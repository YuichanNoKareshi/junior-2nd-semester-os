# lab5

## <font color="red">第一部分：文件系统</font>

### 练习1：实现tfs_mknode和tfs_namex
+ tfs_mknod
  - 创建一个文件，如果mkdir为true，则创建目录
  - 创建inode和对应的dentry，并把dentry假如dir的htable中
+ tfs_namex
  - 在fs中寻找 `*name`，并把父路径存入`*dirat`，文件名存入`*name`.

### 练习2：实现tfs_file_read和tfs_file_write。提示：由于数据块的大小为PAGE_SIZE，因此读写可能会牵涉到多个页面。读取不能超过文件大小，而写入可能会增加文件大小（也可能需要创建新的数据块）。
+ tfs_file_write
  - 把buf处size大小的字符串写到inode的offset处，可能会改变文件大小
+ tfs_file_write
  - 从inode的offset处读size大小字符串到buf

### 练习3：实现tfs_load_image函数。需要通过之前实现的函数进行目录和文件的创建，以及数据的读写。
+ 将cpio文件load到tmpfs中，起始地址为`start`
+ 如果需要，创建目录和文件。还需要将数据写入tmpfs。

### 练习4：实现在user/tmpfs/tmpfs_main.c中 的fs_dispatch和在user/tmpfs/tmpfs_server.c中 的 所 有fs_server_xxx处理函数
&emsp;&emsp;见代码

## <font color="red">第二部分：Shell</font>

### 练习5：实现在user/apps/init_main.c中定义的getchar()，以每次从标准输入中获取字符，以及在user/apps/init.c中定义的readline。
+ getch
  - 见代码
+ readline
  - 从stdin中读取以`prompt`开头的命令
  - 将命令放入`buf`并返回`buf`
  - 将按下回车键之前的输入内容存入内存缓冲区并将其标准输出

### 练习6：实现在user/apps/init.c中定义的bultin_cmd()以支持 shell 中的内置命令，例如ls，ls [dir]，cd [dir]，echo [string]，cat [filename]。
&emsp;&emsp;见代码

### 练习7：实现在user/apps/init.c中定义的run_cmd，以通过输入文件名来运行可执行文件，并且支持按 tab 自动补全
&emsp;&emsp;见代码

### 练习8：实现top以显示线程信息。
&emsp;&emsp;见代码


```
runing init_test: (8.3s) 
  readline: FAIL 
    ...
         Booting fs...
         [INFO] pgfault at 0x0 failed
         info_page_addr: 0x200000
         [tmpfs] register server value = 0
         qemu-system-aarch64: terminating on signal 15 from pid 148264 (make)
    MISSING '> echo ls tt yy'
  echo: FAIL 
    ...
         Booting fs...
         [INFO] pgfault at 0x0 failed
         info_page_addr: 0x200000
         [tmpfs] register server value = 0
         qemu-system-aarch64: terminating on signal 15 from pid 148264 (make)
    MISSING 'abc123XYZ'
  ls: FAIL 
    ...
         Booting fs...
         [INFO] pgfault at 0x0 failed
         info_page_addr: 0x200000
         [tmpfs] register server value = 0
         qemu-system-aarch64: terminating on signal 15 from pid 148264 (make)
    MISSING 'init.bin'
  ls dicrectory: FAIL 
    ...
         Booting fs...
         [INFO] pgfault at 0x0 failed
         info_page_addr: 0x200000
         [tmpfs] register server value = 0
         qemu-system-aarch64: terminating on signal 15 from pid 148264 (make)
    MISSING 'test'
  cat: FAIL 
    ...
         Booting fs...
         [INFO] pgfault at 0x0 failed
         info_page_addr: 0x200000
         [tmpfs] register server value = 0
         qemu-system-aarch64: terminating on signal 15 from pid 148264 (make)
    MISSING 'apple banana This is a test file.'
  auto complement: FAIL 
    ...
         Booting fs...
         [INFO] pgfault at 0x0 failed
         info_page_addr: 0x200000
         [tmpfs] register server value = 0
         qemu-system-aarch64: terminating on signal 15 from pid 148264 (make)
    MISSING '> yie.*ld_spin.bin'
  run executable: FAIL 
    ...
         Booting fs...
         [INFO] pgfault at 0x0 failed
         info_page_addr: 0x200000
         [tmpfs] register server value = 0
         qemu-system-aarch64: terminating on signal 15 from pid 148264 (make)
    MISSING '\[Parent\] create the server process.'
  top: FAIL 
    got:
      0
    expected:
      6

```
&emsp;&emsp;写完之后make grade有如上报错，看报错应该是lab4的问题，于是经过检查后修改了lib中的spawn