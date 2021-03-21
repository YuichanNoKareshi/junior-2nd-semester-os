#lab2

## <font color="red">part 1</font>

### 问题1：请简单解释，在哪个文件或代码段中指定了 ChCore 物理内存布局。你可以从两个方面回答这个问题: 编译阶段和运行时阶段。
+ 编译阶段：boot/mmu.c中init_boot_pt函数
+ 运行时阶段
```c++
kernel/mm.c

extern unsigned long *img_end;
#define PHYSICAL_MEM_START (24*1024*1024)	//24M
#define START_VADDR phys_to_virt(PHYSICAL_MEM_START)	//24M
#define NPAGES (128*1000)
#define PHYSICAL_MEM_END (PHYSICAL_MEM_START+NPAGES*BUDDY_PAGE_SIZE)
```
![avatar](./物理内存布局.jpg)

### 练习1：实现kernel/mm/buddy.c中的四个函数：buddy_get_pages()，split_page()，buddy_free_pages()，merge_page()
&emsp;&emsp;见代码

---

## <font color="red">part 2</font>

### 问题2：AArch64 采用了两个页表基地址寄存器，相较于 x86-64 架构中只有一个页表基地址寄存器，这样的好处是什么？请从性能与安全两个角度做简要的回答。
+ 性能：在AArch64体系结构上，通常应用程序和操作系统使用不同的页表，由于硬件提供了TTBR0_EL1和TTBL1_EL1两个不同的页表基地址寄存器可供他们分别使用，在系统调用过程中不需要切换页表，避免了TLB刷新的开销。
+ 安全：提供了应用程序与操作系统之间的隔离，确保应用程序不会访问操作系统的内存

### 问题3：
1. 请问在页表条目中填写的下一级页表的地址是物理地址还是虚拟地
址?
    + 物理地址
2. 在 ChCore 中检索当前页表条目的时候，使用的页表基地址是虚拟地
址还是物理地址？
    + 物理地址

### 问题4：
1. 如果我们有 4G 物理内存，管理内存需要多少空间开销? 这个开销是
如何降低的?
    + 页的大小为4K，页表项的大小为8byte，则4G物理内存最多需要4G/4K*8byte=8M空间开销
    + 使用多级页表，可以在虚拟地址空间未被全部使用的情况下减少页表页的个数，从而降低空间开销
2. 总结一下 x86-64 和 AArch64 地址翻译机制的区别，AArch64 MMU
架构设计的优点是什么?

### 练习2：在文件kernel/mm/page_table中，实现map_range_in_pgtbl()，unmap_range_in_pgtbl()和query_in_pgtbl() 
&emsp;&emsp;见代码

---

## <font color="red">part 3</font>
