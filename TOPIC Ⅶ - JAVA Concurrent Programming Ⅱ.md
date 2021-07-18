# TOPIC Ⅶ: JAVA Concurrent Programming Ⅱ

## 1. JAVA 并发包：13'28''
### JDk 核心库的包
* JAVA 项目的 External Libraries 中有一个 `rt.jar`
    * JAVA Runtime 依赖的最核心的 jar 包
    * 类型一：java 开头的，为 JDK 公开的 API，所有 JDK 都必须实现 
    > 尽量使用公开的包，不会有兼容性问题。
    * 类型二：javax（扩展的，可以不实现，很多J2EE的都是这个开头） 或 sun 开头的
* java.lang.*
    * 最核心、最基础：比如常用的数据类型的定义
* java.io.*
    * IO读写，文件操作
* java.util.*
    * 工具类
* java.math.*
    * 数学运算
* java.net.*
    * 网络编程（socket, url 等）
* java.rmi.*
    * JAVA 内置的 RPC 远程调用
* java.sql.*
    * JDBC 相关，操作数据库

### Java 并发包：JUC (java.util.concurrency)
* 在 java.util.* 中
* 作者：Doug Lea
* 功能：通过并发控制使多线程能更好地协同工作。
* 5类核心功能
    * `锁`：针对多线程的锁同步问题，如何进一步改进之前的 wait & notify 机制以及 synchronized 同步块机制。
    * `原子类`：数值类的操作（多线程计数等）；多线程不需要排队等待处理，同时保证执行结果正确，不需要加重锁。
    * `线程池`：管理大量的线程。
    * `工具类`：线程间通过一些机制来相互感知、控制。
    * `集合类`：线程安全集合类。
* 5大类的接口及相关实现
    * 锁机制类 Locks
    > Lock, Condition, ReentrantLock 可重入锁, ReadWriteLock 读写锁, LockSupport 封装了很多静态锁的方法
    * 原子操作类 Atomic
    > AtomicInteger, AtomicLong, LongAdder 改进版的对long类型原子计数的类
    * 线程池相关类 Executor
    > Future, Callable, Executor, ExecutorService
    * 信号量3组工具类
    > CountDownLatch, CyclicBarrier, Semaphore
    * 并发集合类 Collections
    > CopyOnWriteArrayList, ConcurrentMap（包括 ConcurrentHashMap, ConcurrentLinkedHashMap 等）


## 2. 什么是锁：26'48''
* 锁：看作对资源的标记，拿到锁相当于占有该资源的使用权，可继续操作。
* 显示的锁 vs {wait&nofity机制，synchronized同步块机制}
    * synchronized同步块：阻塞后`无法中断`（对 interrupt() 不做响应）、`无法控制超时`（不能自动解锁）、`无法异步处理锁`（不能立即知道是否能拿到锁）、`无法根据条件灵活加解锁`（只能与同步块的范围一致）。
    > 真实业务场景中：超时的锁占用，如果能做到自动超时，强制解锁，然后抛出异常，是一个比较好的设计思路。
    > 真实业务场景中：需要状态通知。

### 基础接口：interface Lock
* 更自由、更灵活地加解锁,性能开销小。
    * JVM 层的锁在 JAVA 层实现了：更灵活。
* 锁工具包：`java.util.concurrent.locks`
* 重要方法

方法 | 说明  
---|---
lock() | 阻塞式地获取锁，类似 synchronized(lock)，兼容了同步块的用法
lockInterruptibly() throws InterruptedExceptions | 支持中断的API
boolean tryLock(long time, TimeUnit unit) throws InterruptedExceptions | 支持超时的API，同时支持中断 
boolean tryLock() | 支持非阻塞方式去获取锁的API
void unlock() | 显式解锁
Confition newCondition() | 一个锁可以有多个Condition，灵活地控制锁

* 基础实现类
    * `ReentrantLock 可重入锁`
    > 持有锁的当前线程第二次进入代码块时，是否还能拿到之前未释放的锁，还是和其他线程一样被阻塞？
    > 能拿到：可重入锁
    * `公平锁（排队靠前的优先）`
    * 非公平锁（机会等同）

### ReadWriteLock 读写锁
* 锁工具包：java.util.concurrent.locks
* 适用场景：并发读，并发写，读多写少。
    * 需要保证写期间读数据的一致性。
* 读写锁：`可重入读写锁 ReentrantReadWriteLock`。
    * 变量 boolean fair：表示当前使用的是公平锁机制 or 非公平锁机制
* 重要方法

方法 | 说明  
---|---
readLock() | 获取读锁；共享锁，保证可见性
writeLock() | 获取写锁；独占锁（每个时间点只有一个线程能写；被读锁排斥，排他锁）

### 基础接口：interface Condition
* 锁工具包：java.util.concurrent.locks
* 调用 await()，当前线程进入等待（`支持被中断`）。
* 重要方法

方法 | 说明  
---|---
await() throws InterruptedException | 等待信号
awaitUninterruptibly() | 等待信号（不能被中断）
await(long time, TimeUnit unit) throws InterruptedException | 等待信号
awaitUntil(Date deadline) throws InterruptedException | 等待信号
signal() | 发信号，类比 notify()
signalAll() | 发信号，类比 notifyAll()

### LockSupport
* 锁工具包：java.util.concurrent.locks
* 静态方法，类比 Thread 类的静态方法
* park(Object blocker) `暂停`当前线程，unpark(Thread thread) `唤醒`当前线程
    * unpark 需要添加一个线程作为入参，因为当前线程已被暂停，自己不能给自己解锁，需要其他线程唤醒当前线程。
    * 实际操作中，可以以线程为参数通过 getBlocker(Thread t) 拿到锁对象。

### 最佳实践
* 永远只在更新对象的成员变量时加锁
* 永远只在访问`可变的`成员变量时加锁
* 永远不在调用`其他对象的方法`时加锁
    * 外部加锁，无法控制锁的粒度
* 原则：“`最小使用锁范围`”
    * `降低锁范围`：降低锁定代码的作用域（提升整体的运行效率）
    * `细分锁粒度`：一个大锁拆分成多个小锁（提升并发能力）


## 3. 并发原子计数类：17'35''
* 工具包：java.util.concurrent.atomic
* 之前的 WN 机制 / 同步块机制 / Lock：“加锁”在本质上都没有做到并发执行。
    * 操作的串行化，相当于都是单线程在处理。
    * 优化：原子计数类

### 底层实现原理
* （1/3）调用了一系列的 Unsafe API: CompareAndSwap前缀，`CAS 机制`   
    * 实现方法都在 JVM 内部
* （2/3）需要 CPU 硬件指令支持：CAS 指令（相当于“乐观锁”，通过自旋重试保证写入）
    * 如何保证 CAS 一致生效？（主存中的数据与线程拿到的副本不一定一致）
* （3/3）value 的可见性：volatile 关键字，保证读写操作都可见（不保证原子性）

### 有锁 VS 无锁
* 并发量大，竞争激烈
    * 无锁，CAS + volatile：本地不停地自选，来回读取数据，会占用大量资源。
* 并发压力较小
    * 是否使用 CAS 影响不大。
* 并发压力一般
    * 无锁更快：大部分都是一次写入（乐观锁），并发性能提升了

### 利用分段思想改进原子类
* 比 CAS 在多线程下表现更好的计数方式。
* 从 AtomicLong 到 LongAdder
    * 多线程计数变为单线程计数：性能提升
    * 分段：使用数组将当前的计数任务（不同线程的计数器）按线程数分段（多线程之间不共享资源，各干各的事），最后对数组求和。
    * 本质：value 是资源竞争的热点。


## 4. 并发工具类详解：34'57''
* 用途：多线程并发执行；代码简单易维护，又能使用多核的红利。
* 简单的协作机制：wait & notify 机制，Lock & Condition 锁机制。
* 面向更复杂的场景（可以`定量`）
    * 需要控制并发访问资源的`并发数量`。
    * 需要多个线程在某个时间`同时开始运行`。
    * 需要指定数量线程`到达某状态`再继续处理（设置聚合点）。

### AQS (AbstractQueuedSynchronizer) 队列同步器
* 更灵活，更细粒度地控制 JAVA 多线程相互间协作。
* AQS 是构建锁和并发工具类的基础，JUC 的核心组件.
    * `抽象了竞争的资源和线程队列`。
    * 资源：Integer, 可以看作 state; volatile 保证可见性。
    * 第一个线程：可以独占，可以共享。
    * 接下来的并发线程：排队，双向队列；支持实现公平锁 / 非公平锁。

### 基于 AQS 实现的并发工具类
#### Semaphore 信号量
* 作用：对当前进入队列的线程，同一时间下的并发线程数控制。
    * N = 1：独占锁。
    * 参数：new Semaphore(N)，N 表示并发线程数；new Semaphore(N, true)，N 是并发线程数，true 是标识公平/非公平。
    * 可以看作 Synchronized 同步块的升级版。
* acquire() 方法：控制资源占用，看是否能获取当前信号量。
* 好处：限制被外部并发调用的线程数，保护内部代码。

#### CountDownLatch
* 倒着计数：递减计数，实现多线程间的协作。
* `阻塞主线程`，N 个子线程满足条件时主线程再继续。
* 相关方法

方法 | 说明  
---|---
CountDownLatch(int count) | 构造函数（需要指定允许并发的信号的数量）
await() throws InterruptedException | 等待归零（`主线程在等待被唤醒`）
await(long timeout, TimeUnit unit) | 有超时的等待
countDown()) | 等待减一（每个子线程干完活就调用，告诉主线程信号量减一）
getCount() | 返回余量

#### CyclicBarrier
* 不是基于AQS实现的。
* 多线程间可循环利用的屏障。
* `在各个子线程中等待`；都达到信号数量时，各个子线程被唤醒，继续处理。
* 相关方法

方法 | 说明  
---|---
CyclicBarrier(int parties) | 构造函数（需要等待的数量）
CyclicBarrier(int parties, Runnable barrierAction) | 构造函数（需要等待的数量，需要执行的任务-在聚合点之后要执行的操作）
await() | 等待到齐
await(long timeout, TimeUnit unit) | 有超时的等待到齐
reset() | 重来一轮

#### CyclicBarrier vs CountDownLatch
* CountDownLatch
    * 主线程 await，然后再聚合
    * N 个子线程 countDown()，主线程继续
    * 聚合点之后在主线程继续
    * 基于 AQS 实现（state 为 count）
    * 达到聚合点后不可复用
* CyclicBarrier
    * 子线程 await，各个子线程继续执行，条件在子线程里
    * N 个子线程 await()，子线程继续
    * 回调里写达到聚合点后的操作
    * 基于可重入锁 condition.await / signAll 实现
    * 达到聚合点后可以 reset()，循环使用屏障

### Future / FutureTask / CompletableFuture
* 普通模式
* Future 模式
    * 额外的线程执行返回的结果封装在 Future，当前线程通过 future.get() 拿到异步线程的结果。
    * 优势：当前线程在调用了异步方法和拿到异步执行的结果中间这段时间可以干别的事。
    * FutureTask：有返回值的任务；单个任务。
    * 多个异步结果的组合、封装，异步的回调处理：CompletableFuture.


