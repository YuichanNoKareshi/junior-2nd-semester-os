# lab4

## <font color="red">第一部分：多核支持</font>

### 练习1：阅读boot/start.S中的汇编代码_start。比较实验三和本实验之间_start部分代码的差异（可使用git diff lab3命令）。说明_start如何选定主CPU，并阻塞其他副CPU的执行。

```S
BEGIN_FUNC(_start)
	mrs	x8, mpidr_el1
	and	x8, x8,	#0xFF
	cbz	x8, primary

  /* hang all secondary processors before we intorduce multi-processors */
secondary_hang:
	bl secondary_hang

primary:

	/* Turn to el1 from other exception levels. */
	bl 	arm64_elX_to_el1

	/* Prepare stack pointer and jump to C. */
	adr 	x0, boot_cpu_stack
	add 	x0, x0, #0x1000
	mov 	sp, x0

	bl 	init_c

	/* Should never be here */
	b	.
END_FUNC(_start)
```
&emsp;&emsp;lab3的_start将mpidr_el1中的值存入x8寄存器中，随后检查其是否为0，若为0则是主CPU，跳至primary继续执行；非0则进入secondary_hang中执行死循环，挂起

```S
BEGIN_FUNC(_start)
	mrs	x8, mpidr_el1
	and	x8, x8,	#0xFF
	cbz	x8, primary

	/* Wait for bss clear */
wait_for_bss_clear:
	adr	x0, clear_bss_flag
	ldr	x1, [x0]
	cmp     x1, #0
	bne	wait_for_bss_clear

	/* Turn to el1 from other exception levels. */
	bl 	arm64_elX_to_el1

	/* Prepare stack pointer and jump to C. */
	mov	x1, #0x1000
	mul	x1, x8, x1
	adr 	x0, boot_cpu_stack
	add	x0, x0, x1
	add	x0, x0, #0x1000
        mov	sp, x0

wait_until_smp_enabled:
	/* CPU ID should be stored in x8 from the first line */
	mov	x1, #8
	mul	x2, x8, x1
	ldr	x1, =secondary_boot_flag
	add	x1, x1, x2
	ldr	x3, [x1]
	cbz	x3, wait_until_smp_enabled

	/* Set CPU id */
	mov	x0, x8
	bl 	secondary_init_c

primary:

	/* Turn to el1 from other exception levels. */
	bl 	arm64_elX_to_el1

	/* Prepare stack pointer and jump to C. */
	adr 	x0, boot_cpu_stack
	add 	x0, x0, #0x1000
	mov 	sp, x0

	bl 	init_c

	/* Should never be here */
	b	.
END_FUNC(_start)
```
&emsp;&emsp;lab4的_start也会检查mpidr_el1中的值是否为0，若为0则是主CPU，跳至primary继续执行；而非0则会持续等待clear_bss_flag被clear，随后从其他异常级别变为el1、准备栈指针，设置cpu id，最后进入primary正常执行逻辑

### 练习2：完善主CPU激活各个副CPU的函数：enable_smp_cores()和kernel/main.c中的secondary_start()。
&emsp;&emsp;见代码

### 练习3：熟悉启动副CPU的控制流程(同主CPU类似)，并回答以下问题：初始化时，主CPU同时激活所有副CPU而不是依次激活每个副CPU的设计是否正确？换言之，并行启动副CPU是否会导致并发问题？提示：检查每个CPU核心是否共享相同的内核堆栈以及控制流中的每个函数调用是否会导致数据竞争。
+ 同时激活所有副cpu的设计不正确
+ 每个cpu核心有自己的内核堆栈，但是也会对kernel_stack进行修改，并行启动副cpu会导致并发问题

### 练习4：请熟悉排号锁的基本算法，并在kernel/common/lock.c中完成unlock()和is_locked()的代码
&emsp;&emsp;owner表示当前在吃的食客，next表示目前放号的最新值，见代码

### 练习5：在kernel/common/lock.c中实现kernel_lock_init()、lock_kernel()和unlock_kernel()。如上所述，通过在适当的位置调用lock_kernel()和unlock_kernel()，使用大内核锁来处理可能的并发问题
&emsp;&emsp;见代码

### 练习6：为了保护寄存器上下文，在el0_syscall调用lock_kernel()时，在栈上保存了寄存器的值。然而，在exception_return中调用unlock_kernel()时，却不需要将寄存器的值保存到栈中，试分析其原因。
+ el0_syscall会执行一些操作，这些操作可能会改变寄存器的值，因此需要在内核堆栈上保存寄存器的值
+ exception_return中我们会退出内核态并恢复栈上保存的寄存器值，因此不用将寄存器的值保存到栈中

---

## <font color="red">第二部分：调度</font>

### 练习7：完善kernel/sched/policy_rr.c中的调度功能
&emsp;&emsp;sche_init()初始化调度器。sched_enqueue()将新线程添加到调度
器的就绪队列中。sched_dequeue()从调度器的就绪队列中取出一个线程。
当 ChCore 调度要执行的线程时，将调用sched()，它将当前线程放入调度器
的就绪队列，然后选择调度器的就绪队首线程出队并进行调度。sched()使
用sched_choose_thread()是sched()的辅助函数，用于选择下一个进行
调度的线程。sched_handle_timer_irq()是时间中断处理函数
+ 当CPU核心调用rr_sched_enqueue()时，应将给定线程放入CPU核心自己的rr_ready_queue中，并将线程的状态设置为TS_READY。
+ 当CPU核心调用rr_sched_dequeue()时，应该从CPU核心自身的rr_ready_queue中取出给定线程，并将线程状态设置为TS_INTER，代表了线程的中间状态。
+ 一旦CPU核心要发起调度，它只需要调用rr_sched()，首先检查当前是否正在运行某个线程。如果是，它将调用rr_sched_enqueue()将线程添加回rr_ready_queue。然后，它调用rr_choose_thread()来选择要调度的线程

&emsp;&emsp;见代码

### 练习8：如果异常是从内核态捕获的，CPU核心不会在kernel/exception/irq.c的handle_irq中获得了大内核锁。但是，有一种特殊情况，即如果空闲线程（以内核态运行）中捕获了错误，则CPU核心还应该获取大内核锁。否则，内核可能会被永远阻塞。请思考一下原因。
&emsp;&emsp;当处理完异常后，os会调用exception_return退出内核态，此时会有放锁操作
+ 如果先前是非空闲线程捕获的错误，由于非空闲线程正持有锁，所以不会有问题
+ 但是空闲线程不持有锁，所以在exception_return中放锁时会出现问题。

&emsp;&emsp;因此如果空闲线程中捕获了错误，则CPU核心还应该获取大内核锁

### 练习9：现在，尽管调度器尚未完成，但已经可以运行一些简单的用户态程序。在syscall.c中实现系统调用sys_get_cpu_id()，它告诉用户态程序正在运行的CPU核心的ID。在sched.c中实现系统调用sys_yield()，使用户态程序可以启动线程调度
&emsp;&emsp;见代码

### 练习10：在exception_init_per_cpu()中恢复被注释代码timer_init()，这将在用户态下启用硬件定时器中断。内核的终端处理逻辑结束后会调度线程。此时，yield_spin.bin应可以正常工作：主线程应能在一定时间后重新获得对CPU核心的控制并正常终止
&emsp;&emsp;见代码

### 练习11：在kernel/sched/policy_rr.c中修改调度器逻辑，以便它可以支持预算机制。按照上述说明，实现rr_sched_handle_timer_irq()。不要忘记在kernel/sched/sched.c的sys_yield()中重置“预算”，确保sys_yield()在被调用后可以立即调度当前线程
&emsp;&emsp;见代码

### 练习12：为kernel/sched/policy_rr.c中 的rr_sched_enqueue()增加线程的亲和性支持。如果亲和性设置为NO_AFF，则应将线程加入当前CPU核心的rr_ready_queue。否则，将线程排队到亲和性指定的rr_ready_queue上
&emsp;&emsp;见代码

### 练习13：在thread.c中实现sys_set_affinity和sys_get_affinity
&emsp;&emsp;见代码

---

## <font color="red">第三部分：spawn()</font>

### 练习14：在user/lib/spawn.c中实现spawn()