#### **Homework1 memory**

Assuming a 64-bit machine with 64-bit OS and the page tables have four levels. level-4 (L4) is PGD, L3 is PUD, L2 is PMD, L1 is PTE.

1. On a 32-bit machine, the huge     page size is 4M. On a 64-bit machine, the size of a huge     page is 2M. Why not the same size?

在64位机器上面，一个页表项是8B，一个4K的页里面有512个页表项，可以管理2M大小的地址空间。而在32位机器上面，一个页表项是4B，一个4K的页里面有1024个页表项，可以管理4M大小的地址空间。

1. Why OS/MMU use multi-level page tables to map the     virtual address to physical address? What is the maximum spatial overhead     for the 4-level page table? //四级页表最大空间开销

使用多级页表可以减少空间占用，允许页表中出现“空洞”，实际应用的虚拟地址空间大部分未使用，无需分配页表。对于64位地址空间，占用最大空间为33620096.25GB

1. In ARM-smmu architecture, how can mmu distinguish     whether it is a page entry or invalid entry

第三级页表页中的页表项的第0位表示该项是否有效，若为0，则是一个invalid entry。

1. Please give the advantages and the disadvantages of     using block entry / huge page, and give one scenario for each case.

好处是可以减少TLB缓存项的使用，提高TLB命中率；减少页表的级数，提升遍历效率。坏处是如果不能使用整个大页的话会造成物理内存资源浪费，增加管理内存的复杂度。对于数据库应用程序，占用内存很大，不使用大页的话页表会变得很大，将数据库的共享内存放在大页可以减小开销。大页面不能用于文件缓存。

1. Memory attribution bit AP     and UXN in page entry can already isolate the     kernel space and user space, so why ARM-smmu architecture still needs two     ttbr registers (Translation Table Base Register), please give a scenario     that two ttbr registers can protect the os but attribution-based isolation     can not.

CSE--meltdown Reading Kernel Memory from User Space

如果内核和用户页表放在一起，仅由属性来判断，这会导致权限判断延迟，从而在CPU冒险冲突中得以访问无权限数据；所以解决办法是，让权限判断与CPU计算解耦，使用两个页表

1. TLB (Translation Lookaside Buffer) can cache the     translation from a virtual address to a physical address. However, TLB     will be flushed after a context switch between processes. Why? Is it     necessary to flush TLB when switching between a user application and the     OS kernel? Why?

http://www.wowotech.net/memory_management/tlb-flush.html

因为每个进程都有自己独立的虚拟地址空间，在进程切换的时候，虚拟地址空间发生了变化，因此TLB中条目也无效了；不必要，对于global pages(内核地址空间)，地址翻译对操作系统中的进程都是一样的，一般内核页的TLB条目在进程切换时也不会被刷掉。 内核和应用程序使用不同的页表，在内核态和用户态之间切换时不需要切换页表，因此不需要刷新TLB。

1. Before ARMv8 architecture, there is no DBM(Dirty Bit     Modifier) bit in memory attribution. That’s means hardware does not     support dirty page. So how can os simulate this procedure and record the     dirty page? Please give a possible solution.

可以通过设置访问权限加异常处理来模拟。要追踪一个可写的page是不是dirty的，在建立对应的页表时，可以先设置为readonly的，如果软件要读这个page，不会有问题。如果软件要写这个page，会产生异常，kernel检查异常原因时发现是访问权限的问题，但是kernel本身是可写的，kernel就知道是在模拟dirty page，把权限改为可读可写，并且kernel记录了dirty状态。异常返回到原先的写指令执行也不会出现异常。

https://www.geek-share.com/detail/2738553861.html



#### Homework2 process

1. Assume you are calling fork     in one thread of a multi-thread process in Linux. How many threads will there be in the child     process? What problem may exist in the forked child process? Why     Linux have to design fork operation of a multi-thread process like that?

fork之后，子进程中只有一个线程；在执行fork的时候，其他线程可能在执行由mutex保护的非原子操作，而在子进程中这些线程直接消失了，留下了半修改的数据，而且无法恢复；因为克隆整个进程的所有线程可能会出问题，比如说有的线程可能因为执行系统调用被挂起了。

ref http://www.linuxprogrammingblog.com/threads-and-fork-think-twice-before-using-them

1. vfork is a system call similar to fork. Use man vfork to learn more about vfork. Why does vfork perform     better than fork in applications     consuming a huge amount of memory even when fork already applied the COW policy for memory     copying? Try to optimize the performance of fork for such     applications without compromising its semantic refers to the idea of vfork. //参考vfork的思路，对现有的fork做一些优化

因为fork虽然不拷贝实际内存，但是要拷贝内存映射，而vfork直接让父子进程共享同一地址空间，不需要拷贝映射，在应用程序消耗大量内存时，拷贝内存映射也是一个很大的开销。对于这种应用，可以采用写时拷贝映射的方式，在fork时仅复制内核的数据结构，不进行页表项的复制。页表项的复制推迟到子进程修改数据时进行。

https://www.nowcoder.com/ta/review-c/review?page=61

1. In an operating system where a single process     contains multiple threads like ChCore, a context switch is usually done at     the granularity of thread. However, context switch between threads     belonging to the same process can be faster than that between threads     belonging to different processes. Why?

前者的虚拟地址空间还是一样的，只需要修改一下寄存器，PC等。而后者要修改内存映射、页表等，这是一个很大的开销。

https://stackoverflow.com/questions/5440128/thread-context-switch-vs-process-context-switch

1. In ChCore, the page table mapping has been     changed during the context switch. However, after the page table changed,     the ChCore kernel, which also uses virtual memory address in its code, can     still run correctly and get the correct address of its variables and     codes. Why?

因为ARM的内核态和用户态不共享页表，在上下文切换的时候只会改变TTBR0，而不改变TTBR1。

https://rookiecj.tistory.com/326

1. For user-level threads like coroutine, since all     coroutines belong to the same thread, only one coroutine can be running at     the same time. How can coroutine benefit the performance with the same     amount of computing resources? What kind of applications can benefit from     coroutine most?

线程很多的时候，线程切换的开销很大，使用协程可以避免这种开销。需要管理长时间运行的任务时，使用协程可以避免任务阻塞主线程并导致应用冻结。

https://medium.com/software-development-2/coroutines-and-fibers-why-and-when-5798f08464fd

https://stackoverflow.com/questions/6574274/how-do-coroutines-improve-performance

https://developer.android.com/kotlin/coroutines

1. Now, Assume you are going to create     an operating system specialized for the scenario where only one single web server application is running in the     OS. The web server requires: 1) Low waiting     and processing latency for every user request. 2) Code handling requests     from different users can not access each other's memory. How are you going     to design the semantic of process/thread in your OS and the program logic     of the web server? What should be stored in PCB/TCB, and how is context     switch done in your OS?

对于每个connection fork一个新的线程，PCB里面存放进程相关的信息、内存管理的信息、文件管理的信息等，TCB里面存放线程当前的状态、寄存器、pc、stack等。上下文切换时，先把旧的寄存器等保存在栈上，然后切换到新的栈、新的线程，执行结束或者时间片用完的时候恢复寄存器的值，返回到旧的线程。

https://flint.cs.yale.edu/cs422/lectureNotes/L05.pdf

#### homework3 IPC

1. Please give a     suitable real-world program example for each of the following IPC     implementations:

- Two processes communicate with each other by polling     some data in shared memory

适用于共享数据比较大的系统，比如游戏服务器。

- One sender process and one receiver process communicate     with each other using non-blocking message passing

比如餐馆点餐系统，顾客点单时给一个号码牌，然后顾客排队等待取餐。一边生成订单、一边处理订单。

- One sender process and one receiver process communicate     with each other using blocking message passing

适用于对一致性要求比较高的系统，生产者需要等待消费者的回应，比如涉及钱的、转账之类的。

- One sender process and multiple receiver processes     communicate using a shared mailbox

适用于一对多发送消息的，比如聊天群。

1. In the Xv6 pipe     implementation, what is the usage of the field lock     in struct pipe? Why must we put the release/acquire     operation inside the sleep     function? Why is there no lock operation in the wake     function?

使用锁，我们可以确保管道互斥，从而可以原子方式访问共享数据，因为一次只能有一个进程可以持有该锁。如果拿锁放锁在sleep外面会导致带锁睡觉，使得共享变量在此期间不能访问了。因为内核关了中断，不会发生wakeup在条件检查和sleep之间被调用的情况。

https://www.cs.hmc.edu/~rhodes/courses/cs134/sp19/lectures/Lecture11.pdf

1. For shared memory based IPC, there     is a typical security problem named "Time-of-check to     time-of-use". Please give a brief description of what this problem is     with the help of internet and give a possible solution for this problem. **HINT**: the memory     mapping mechanism may help.

"Time-of-check to time-of-use"是由[竞争状态](https://en.wikipedia.org/wiki/Race_condition)引起的一类[软件错误](https://en.wikipedia.org/wiki/Software_bug)，这些[竞争](https://en.wikipedia.org/wiki/Race_condition)[错误](https://en.wikipedia.org/wiki/Software_bug)涉及检查系统的一部分状态（例如安全凭证）以及该检查结果的使用。解决方法：在文件系统或OS内核中采用事务。事务为OS提供了并发控制抽象，可用于防止TOCTOU争用。

wiki

1. For the LRPC implementation,     please answer the following questions:

- Why is the stack divided into an argument stack and an     execution stack?

参数栈同时映射在调用者进程和被调用者进程地址空间，不需要内核额外的数据拷贝。运行栈是用来真正执行逻辑的。

- Where does the overhead come from during the control     flow transformation of LRPC?

切换地址空间、权限表等状态，不做调度和真正的线程切换。

- Are there any security problems caused by the shared     argument stack? (Multi-threading are not considered)

调用者可以在被调用者返回前修改参数栈上的数据，导致被调用者不能正确执行。

1. Most IPC     implementation requires a naming mechanism to find the specific process     for communication (e.g., the nread/nwrite     pointer in the Xv6 example). Will the design of the naming mechanism     dominate the IPC performance? Why?

不会，命名机制只是维护了一个map，我觉得还是控制流的转换比较影响性能。

1. The performance of IPC heavily     depends on the hardware architecture (e.g., how the hardware change     privilege level and the hardware details of page table switching). For the     IPC implementation of ChCore under AArch64 architecture, try to analyze     what hardware may influence to the IPC performance. If you are a hardware     designer hired by the ChCore team, what modification on the hardware can     you do to speed up ChCore's IPC while not compromise security?

影响性能的主要是控制流转换时对地址空间和权限表的状态切换，我觉得可以同时存储两份权限表、两份页表，在切换时仅仅改变一个bit。

传输数据可能也比较影响性能，小数据可以采用寄存器传输，大数据可以通过共享内存传输。

来自 <https://oc.sjtu.edu.cn/courses/17894/assignments/30776> 



#### homework4 

\1.    在单处理器系统中，假设一个线程获取了自旋锁，把lock置为1，此时发生中断，而其他线程无法拿锁，原来的线程也不能释放锁。

解决：

在非抢占的系统中, 进程一旦处于核心态(例如用户进程执行系统调用)，则除非进程自愿放弃CPU，否则该进程将一直运行下去，直至完成或退出内核。如果有中断打断，则需要关中断。自旋锁退化为关开中断。

在抢占的系统中, 要使高优先级进程不能抢占，自旋锁的定义变成禁止/打开抢占+关开中断。

\2.    只要有读者在，写者就无法进入临界区，可能造成starvation。

偏向写者的设计：

写者优先级高于读者。

当有写者到来时, 读者不能进入临界区。

当有一个写者正在写时、或在等待进入临界区时，应当阻塞读者的读操作，直到所有写者完成写操作时，放开读者。

当没有写者时，读者应该能够同时读取文件。

\3.    在4个处理器，5个相同资源，每个处理器在一定时间内最多需要2个资源的情况下，至少可以满足其中一个处理器的要求，所以未被满足的处理器可以等待其释放资源。以此类推，资源分配不会形成环，也就不会有循环等待，不满足形成死锁的条件。

\4.    Ticket lock中，多核对lock所在缓存行的读写竞争导致throughput下降:

while (lock->owner!=my_ticket){ /*Busy looping*/ }

  MCS锁在关键路径上避免对单一缓存行的高度竞争，每个处理器只在一个本地变量上自旋。

\5.    公平性问题：全局锁在一段时间内只在一个结点内部传递。

解决：当有其他结点等待时，让持有全局锁的结点运行一段时间后主动放锁，使所有结点轮流获得全局锁。

\6.    void lock(struct spinlock* lock) { 

/* locking */ 

barrier();    

}

void unlock(struct spinlock* lock) { 

barrier();

/* unlocking */ 

}



#### homework5

1. Symbolic link and hard link are both used as a shortcut     of a file but they are very different. Please describe at least 4     differences between them.

2. 1. hard link没有创建新文件；symbolic link创建了一个新文件，内容是一个字符串
   2. 创建hard link使得目标inode的reference      count加一；而symbolic不改变reference      count
   3. 目标文件删除，hard link仍然合法，symbolic      link不合法了
   4. hard link只是增加了一个文件名和已经存在的inode之间的映射
   5. symbolic link可以指向目录，hard      link不可以

3. In some file systems, such as ext4, hard link are not allowed to     link a directory. 
             (1) Please give an example to illustrate what problem is if a file     system supports hard link to a directory.

比如/a/b是一个目录，创建/a/b/c指向目录a的链接，使得a的refcnt变成2，unlink /a之后，refcnt变为1，inode不可以删除，但是a事实上已经不可达了。指向目录的链接导致环，浪费了一个inode空间。

(2) If we really need hard link to a directory, how can you design the file system? Then, please analysis your design from some points like complexity and performance.

需要指向目录的硬链接的话，可以加一个参数用以区分开来原文件和hard link，避免指向目录的硬链接破坏文件系统有向无环的特性。

1. Please give an example of file system inconsistency     caused by system crash. 

Adding block to file: free list was updated to indicate block in use, but file descriptor wasn't yet written to point to block.

 

来自 <https://web.stanford.edu/~ouster/cgi-bin/cs140-winter13/lecture.php?topic=recovery> 

1. Explain terms of durability and atomicity, how to     enforce durability and atomicity of file system operation?

持久性是说数据被写到磁盘等非易失性内存，原子性是说操作要么完成要么全部没发生。在文件系统中，可以通过日志以及合适的操作顺序，保证提交点之前可以恢复到什么都没发生，提交点之后可以全部完成，数据会在适当的时候写入磁盘。

1. There are three techniques to support consistency:     copy-on-write, journaling and log-structured updates. 
             (1) Please explain the differences among them. 

写时复制是在修改多个数据时，不直接修改数据，而是将数据复制一份，在复制 上进行修改，并通过递归的方法将修改变成原子操作。日志是在内存中进行文件系统操作的同时，在磁盘上记录日志。日志文件系统是将文件系统的修改以日志的方式顺序写入存储设备。

(2) How to choose these techniques under different scenarios? Please describe these scenarios.

每次修改都接近整块，而且在磁盘中局部性较好时适合用cow，不会引起级联的修改；多次小的修改适合用日志。

1. For the wear out problem, how can the file system avoid     it causing the drop of flash memory’s capacity in a short time of usage?     If some block has been worn out, how can the file system handle them?     (Suppose the hardware provides some way to report whether a block is worn     out.) 

可以通过FTL实现读写和擦除非对称，把需要频繁读写的块迁移到别的位置，从而实现负载均衡。

 

来自 <https://oc.sjtu.edu.cn/courses/17894/assignments/37824



#### Homework 6

\1.    Linux设备驱动抽象：

• Device（设备）：用于抽象系统中所有的硬件

• Bus（总线）：CPU连接Device的通道

• Class（分类）：具有相似功能或属性的设备集合

LDDM利用sysfs向用户空间提供系统信息

\2.    GIC将中断完成分两步走，是为了把响应和完成的时间切分，并进行时延控制。Linux通过将中断处理程序分为两半，使得中断处理时可以在handler中执行较长的任务，并且不会长时间保持中断阻塞。top half将请求放入队列（或设置flag），将其他处理推迟到bottom half。这使得top half在bottom half仍在工作时处理新的中断。

 

\3.    采用轮询，则收端来不及处理数据，导致之前的数据的被覆盖。采用中断，则收端在处理中断上下文中，导致后来数据没有收到。可以采用以下策略：静态配置法（UART驱动需要在初始化时指定“波特率”，限制发包速率）、动态协商法（TCP设计了流量控制机制，发端逐步试探出收端收包能力的上限、进行动态调整）

4.

\1.    网卡收到包，通过DMA把包拷贝到内存里，然后发一个中断。CPU收到中断后调用ISR。

\2.    将包数据拷贝到RX队列。OS发出一个softirq。

\3.    OS收到softirq，检查RX队列，把数据从RX队列组装并拷贝到socket buffer。

\4.    IP层解析skb查询路由

\5.    TCP层解析skb、检查连接状态

\6.    将包拷贝到socket的接收队列，然后到用户空间。

有2个context switch，因为有一次中断。

\4.    sk_buff本身不存储报文，通过指针指向真正的报文内存空间，在各层传递时只需调整指针相应位置即可，浅拷贝是克隆出新的sk_buff控制结构，和原来指向同一报文，所以是零拷贝。深拷贝需要同时复制sk_buff以及指向的报文。

\5.    DPDK的优化：

抛弃中断，使用轮询模式

使用大页（2MB）减少TLB miss

控制平面与数据平面相分离

用多核编程代替多线程技术

CPU 核尽量使用所在 NUMA 节点的内存，避免跨NUMA内存访问

ChCore也可以使用大页来优化网络性能。