# cpu100
一款快速定位Java线程CPU消耗高原因的小工具

在排查Java进程CPU使用率过高的时候你是否和我有相似的经历？

忘记具体排查步骤只记得要转换什么东西到16进制 🤔  
忘记top命令参数然后被某SDN的复制粘贴文章搞到崩溃😡   
在搜索引擎上搜索“在线转换16进制” 😩  
没来及排查完就同事就重启了进程还被他阴阳怪气排查问题速度慢 😓  

以往我们排查CPU打满的步骤是这样的：
1. top -Hp {pid}: 查看该Java进程内所有线程的资源占用情况
2. 将pid转换为16进制，Linux高手可以用：`printf "%x\n"{pid}`打印出线程id的16进制 
3. jstack -l <pid> > jstack.txt：获取此时的所有线程快照并输入到文件中 
4. 查找文件内容包含nid={16进制id}的线程的堆栈

现在只需要一行命令就搞定啦！

## 使用方法
```bash
./cpu100.sh {进程Id} {topN线程数量}
```
如上命令输出制定进程Id下cpu使用率最高的几个线程堆栈，输出如下：
```bash
Thread ID: 11777(0x2e01), CPU Usage: 5.9%

"Cat-RealtimeConsumer-ProblemAnalyzer-16-0" #5935 daemon prio=5 os_prio=0 cpu=33301.45ms elapsed=2423.07s tid=0x00007ff1bc75fbd0 nid=0x2e01 runnable  [0x00007ff0e5645000]
9221
   java.lang.Thread.State: TIMED_WAITING (parking)
        at jdk.internal.misc.Unsafe.park(java.base@17.0.6/Native Method)
        - parking to wait for  <0x00000005ffdbd1b0> (a java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject)
        at java.util.concurrent.locks.LockSupport.parkNanos(java.base@17.0.6/LockSupport.java:252)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject.awaitNanos(java.base@17.0.6/AbstractQueuedSynchronizer.java:1672)
        at java.util.concurrent.ArrayBlockingQueue.poll(java.base@17.0.6/ArrayBlockingQueue.java:435)
        at com.dianping.cat.message.io.DefaultMessageQueue.poll(DefaultMessageQueue.java:59)
        at com.dianping.cat.analysis.AbstractMessageAnalyzer.analyze(AbstractMessageAnalyzer.java:62)
        at com.dianping.cat.analysis.PeriodTask.run(PeriodTask.java:116)
        at java.lang.Thread.run(java.base@17.0.6/Thread.java:833)
        at org.unidal.helper.Threads$RunnableThread.run(Threads.java:294)

   Locked ownable synchronizers:
        - None

---------------------------------------------
Thread ID: 11789(0x2e0d), CPU Usage: 5.9%

"Cat-RealtimeConsumer-StateAnalyzer-16-0" #5947 daemon prio=5 os_prio=0 cpu=7448.45ms elapsed=2423.05s tid=0x00007ff1bc309800 nid=0x2e0d runnable  [0x00007ff16498d000]
9413
   java.lang.Thread.State: TIMED_WAITING (parking)
        at jdk.internal.misc.Unsafe.park(java.base@17.0.6/Native Method)
        - parking to wait for  <0x00000005ffea5da8> (a java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject)
        at java.util.concurrent.locks.LockSupport.parkNanos(java.base@17.0.6/LockSupport.java:252)
        at java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject.awaitNanos(java.base@17.0.6/AbstractQueuedSynchronizer.java:1672)
        at java.util.concurrent.ArrayBlockingQueue.poll(java.base@17.0.6/ArrayBlockingQueue.java:435)
        at com.dianping.cat.message.io.DefaultMessageQueue.poll(DefaultMessageQueue.java:59)
        at com.dianping.cat.analysis.AbstractMessageAnalyzer.analyze(AbstractMessageAnalyzer.java:62)
        at com.dianping.cat.analysis.PeriodTask.run(PeriodTask.java:116)
        at java.lang.Thread.run(java.base@17.0.6/Thread.java:833)
        at org.unidal.helper.Threads$RunnableThread.run(Threads.java:294)

   Locked ownable synchronizers:
        - None
```

# JavaMemLeak
一款检测Java堆外内存泄漏的小工具

## 使用方法
```shell
显示可能出现内存泄漏的地址块: ./memleak.sh show pid

dump内存到当前目录下: ./memleak.sh dump pid addr
```
### 泄漏内存地址检测
假设JVM进程pid为11983，命令行执行：`./memleak.sh show 11983`，输出如下：
```
00007f2824000000   19396   19396   19396 rw---   [ anon ]
00007f28252f1000   46140       0       0 -----   [ anon ]
00007f2830000000    9752    9672    9672 rw---   [ anon ]
00007f2830986000   55784       0       0 -----   [ anon ]
00007f2834000000   11624   11624   11624 rw---   [ anon ]
00007f2834b5a000   53912       0       0 -----   [ anon ]
00007f2838000000   10040   10028   10028 rw---   [ anon ]
00007f28389ce000   55496       0       0 -----   [ anon ]
00007f283c000000    7360    7352    7352 rw---   [ anon ]
00007f283c730000   58176       0       0 -----   [ anon ]
00007f2840000000    4620    4588    4588 rw---   [ anon ]
00007f2840483000   60916       0       0 -----   [ anon ]
00007f2844000000    4028    4000    4000 rw---   [ anon ]
00007f28443ef000   61508       0       0 -----   [ anon ]
00007f284c5be000   59656       0       0 -----   [ anon ]
00007f2850000000    7544    7540    7540 rw---   [ anon ]
```
根据这里的内存块地址比如：00007f2824000000， 可以用下面的内存dump得到内存块里的内容进一步分析。

### 内存dump
命令行执行：`./memleak.sh dump 11983 00007f2824000000`，输出如下：
```
Dump文件已输出至: ./11983_mem_7f2964000000.bin
```
这是一个二进制文件，如果需要文本格式可以执行：`strings 11983_mem_7f2964000000.bin > 11983_mem_7f2964000000.txt`得到文本格式。

## 注意事项
1、Java进程必须开启Native Memory Track并且设置跟踪级别为detail，设置方法是在启动命令行添加参数：-XX:NativeMemoryTracking=detail


