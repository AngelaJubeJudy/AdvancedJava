# TOPIC Ⅵ: JAVA Concurrent Programming Ⅰ
## 1. 多线程基础：18'54''
### 基础
* 为什么有多线程？
    * 摩尔定律的失效
    * 现在：业务发展的增量远远快于硬件性能增长的速度，远远超过单核CPU处理能力
    * 结果：多线程，分布式；多核时代
* 单核时代也可以多线程
    * OS基础：线程是基本的调用单位，运行任务执行方法的基本单元。
    * 单核CPU，每个时刻只有一个线程在运行；对于进程内的所有线程，每个时间点只有一个时间片能被使用
    * 多核CPU，在同一个时间点上各线程的时间片无关，并发执行；资源抢占导致了应用程序的复杂性
    * 总结：线程越多，管理复杂度越高
* 架构
    * 共享内存架构：SMP 架构
        * 总线 BUS 上有 N 个 CPU；一块内存被 N 个 CPU 共享使用。竞争激烈！不利于扩展！（添加更多的 CPU 导致总线上的数据量变大，竞争愈发激烈）
        * 优化：`分区 / 分治`
    * 非一致性内存访问架构：NUMA 架构
        * 分区共享：同一块内存，一个时刻只有少量的 CPU 在进行读写操作；减少竞争，适合扩容
        * Q：一个CPU想使用的资源/数据不在其共享内存中怎么办？
        * A：通过 `Router` 桥接各总线，实现跨 CPU 的少量数据交互

* Java 线程
    * Thread 类：重载 run() 方法。
    * 过程描述：应用程序执行 start() 方法，JVM 启动一个与当前主线程不一样的额外线程（JVM 层面的 JavaThread 在 OS 层面被转换成真实的线程对象，使用真实的资源），执行重载后的 run() 方法。执行完毕，终结线程，退出应用程序。
    * 代码层面：Thread 对象。
    * JVM 层面：向上承接 Thread 对象，向下对应底层 OS 线程；由 JVM 统一管理 JAVA 里线程的生命周期。
        * `调用 start() 方法：JVM 真正创建一个 OS 线程。`
        * 调用 run() 方法
    * OS 层面：系统线程


## 2. JAVA 多线程：29'33''
### 使用示例
* 新建一个 JAVA 线程
    * `方法一：实现 Runnable 接口`，new 一个 task，重载 `run() 方法`（Runnable 接口的唯一方法，将线程和线程要执行的任务做拆分）。
        * 写法一：匿名类的实现
        * 写法二：Lambda 操作
    * `方法二：继承 Thread 类`，实现一个子类；重载 `run() 方法`。
* 设置`守护线程`
```java
thread.setDaemon(true);
```
* 注：在一个 JAVA 进程中，如果所有运行中的线程都是守护线程，JVM 会停止当前进程。
    * 主线程执行完之后，查看其他正在执行中的线程，`非守护线程`继续工作，不终止 JVM。
    * Q：主线程执行完，还想继续执行自定义线程怎么办？
    * 方法一：注释掉上一行的设置`守护线程`代码。
    * 方法二：主线程里加入 sleep()，没执行完，新线程有时间执行完。
* 创建并启动线程
```java
thread.start();
```

### 线程状态
* 流程图
    * `Runnable`：执行 start() 方法后，新线程的状态。未抢到 CPU 时间片。
    * `Running`：抢到了 CPU 时间片的线程，运行。
    * `Non-Runnable`：不可运行状态。
    * `Terminated`：终止状态。
* 状态流转
    * 从 Runnable 到 Running：属于“操作系统底层的CPU调度层面”。在应用程序层面无法区分。
    * 从 Running 到 Runnable：执行 yield() 方法，重新被 CPU 调度。
    * 从 Running 到 Non-Runnable：执行 wait() 方法，或 sleep() 方法。
    * 从 Running 到 Terminated：执行 exit() 方法。
    * 从 Non-Runnable 到 Runnable：执行 notify() 方法。
* 状态解说
    * 就绪 READY
    * 运行 RUNNING
    * （无参数）等待 WAITING，（有参数）超时等待 TIMED_WAITING
        * `主动等待`：当线程调用 Object.wait(), Thread.join(), Thread,sleep() 之一时。
    * 阻塞 BLOCKED
        * `被动等待`：当遇到同步代码块时，进入临界区，遇到锁；被通知。
        * 拿到锁，解除等待，进入 READY 状态。
    * 终止 TERMINATED
    * 核心状态：RWB (READY, RUNNING, WAITING / TIMED_WAITING, BLOCKED)

### Runnable 接口
* 接口定义
```java
public interface Runnable{
    public abstract void run();
}
```
* run() 方法：定义了`当前线程里的一个任务`，并不是开启了一个新的线程。
* start() 方法：`开启一个新的线程`执行 run() 中定义的任务。

### Thread 类
* 实现：继承了 Runnabele 接口
```java
Thread implements Runnable;
```
* `重要字段和方法`

字段/方法 | 解释 | 调用方 | 备注
---|---|---|---
name | 线程名称 | -- | --
daemon | 守护线程标志 | -- | --
Runnable target | 任务 | -- | 调用start()之后新起的线程要执行的逻辑对应的任务
start() | 启动 | -- | 启动新线程
join(), join(long millis) | 等待 | 其他线程 | 当前线程暂停，等待另一个调用了 join() 方法的线程执行完后，当前线程再继续执行；t.join() 方法`内部调用了wait()方法`（无参数；且后续不会调用 notify() 方法，t.notifyAll() 方法由 JVM 层面的实现调用），当前线程不会释放其他对象上的锁，仅释放t对象上的同步锁
Thread currentThread() | 当前线程对象 | -- | 获取当前行线程执行的对象
sleep() | 睡眠 | 当前线程 | `释放CPU，不释放对象锁`，让出时间片；单位：毫秒，必须设置时间参数，到时自动执行；`Thread 对象`的方法
wait(), wait(long timeout), wait(long timeout, int nanos) | 暂停当前线程对象 | 当前线程 | 执行时，`自动释放线程占有的锁，唤醒后需要自动获取锁`；可以不设置时间参数，因为能通过notify()方法唤醒线程；`Object 对象`的方法
notify() | 通知一个 | -- | 发送信号，通知`某一个` Non-Runnable 线程，不一定哪一个
notifyAll() | 通知全体 | -- | 发送信号，通知`所有` Non-Runnable 线程（唤醒所有因wait()而暂停的线程）

* wait & notify 机制：用于线程之间的统一协调调度的重要手段。

## 线程的中断和异常处理
* 线程内部异常自己处理（一般不要溢出到更外层）。
    * 特例：Future 封装————异步调用一个线程时，所有产生的结果封装在Future里。
* 调用 `interrput()` 方法，抛出 `InterruptedException`（需提前预备此异常的处理）：当线程被 Object.wait(), Thread.join(), Thread,sleep() 之一`阻塞`时。
* 计算密集型的操作
    * 外部无法打断，则分段处理————每个片段检查状态，是否终止。
    * 方法一：interrupt() + InterruptedException，里应外合
    * 方法二：设置一个外部的全局状态


## 3. 线程安全：32'11''
* 多线程的代码难写 T_T

### 多线程执行过程中的问题
* 并发安全问题：多个线程`竞争/同步`相同的资源，如果资源的读写/访问顺序敏感，则存在“`竞态条件`”。
    * `临界区`：导致“竞态条件”发生的代码区。

### 并发相关性质
* `原子性`————要么执行，要么不执行；操作不可中断、不能拆解
    * 原子操作：对基本类型的值的读/写操作本身是原子的。
    * 非原子操作举例：x++, y = x 等。
    * 数据库的事务也有“原子性”问题：多个事务的并发问题（采用不同的隔离级别进行并发控制）。
* `可见性`
    * 关键字：`volatile（保证当前变量的更新立即被更新到主内存）`
    * 多个线程分别持有同一变量的副本，默认的及时修改都同步在副本上，然后再同步到主内存。
    * volatile 的变量，在其他线程访问时，会获取其最新值。
* `有序性`
    * JVM 允许编译器和处理器对指令重排。
    * 单个线程内，重排不影响执行顺序；但 JVM 不保证多个线程操作同一数据时是否会产生不一致的结果。
    * happens-before 原则（先行发生原则）：便于在多线程代码运行过程中设置`锚点`，判断锚点间的限后执行顺序。
        1. 程序次序规则：按代码书写的先后顺序。
        2. 锁定规则：unlock 操作先于其对应的 lock 操作发生。
        3. Votaile 变量规则：写操作先于读操作发生。
        4. 传递规则：A 先于 B，B 先于 C，则 A 先于 C发生。
        5. 线程启动规则：Thread 对象的 start() 行为先于真实线程执行 run() 方法发生。
        6. 线程中断规则：捕获异常发生在线程的 interrupt() 行为之后。
        7. 线程终结规则：线程的所有逻辑都发生在线程终结之前。
        8. 对象终结规则：对象的初始化一定发生在 finalize() 行为之前。

### 实例与优化思考
* example：单线程计数 vs 多线程计数
    * 结果不一致
    * 原因：线程不安全
    * 改进：以下3种方法，`减少锁的粒度，增加并发的粒度`。 
* `synchronized 同步块关键字`
    * 关键字的位置（不同执行粒度）：`对象，方法，某一块代码`。
        * 锁加在对象上。
        * 锁加在调用方法的对象上。
        * 锁加在代码块 synchronized(obj) 的 obj 上，可以额外新建一个obj对象；即支持锁在多个对象上，不限于当前对象，进一步提升了`并发粒度`。
    * 针对对象加锁；锁加在了对象头的标志位上，占 2 bits 的长度。
        * （复习）对象头：标记字，class 指针，数组长度.
        * 锁：偏向锁，轻量级锁，重量级锁。
        * `BiaseLock 偏向锁`：线程A使用锁，此时有其他线程来增强该锁，则默认 A 获取并使用当前锁的资源进行操作的成本最低。
        * 轻量级锁，“乐观锁”：CAS方式，尝试操作，如果失败（锁已被其他线程占有）则升级为重量级锁，排队等待拿锁。
        * 重量级锁：早期实现机制。开销大。
    * 操作的结果对其他线程可见；更新刷入主内存。
    * 有线程安全问题的代码块放入同步块：多个线程来排队，按顺序执行“读->写->刷入主内存”，相当于串行化，避免并发干扰。
    * 副作用：效率低。
* `volatile`
    * 每次都强制从主内存读取数据，写的数据也会直接刷入主内存。
    * 场景：单个线程写，多个线程读。
    * 建议少用：因为不能使用变量副本，需要去主内存刷新。
        * 平替：`原子技术类`，利用一些封装好的结构来实现同等效果。
    * 保证执行顺序（“栅栏”）：volatile 之前的操作对于其之后的操作来说都可见。
* `final`
    * 关键字的位置：类，方法，局部变量，实例属性，静态属性。
    * 表示不允许被修改。仅可读，跨线程安全。


## 4. 线程池原理与应用：40'53''
### 线程池
* Q：为什么需要线程池？
* A：每次需要时 new 一个线程，开销大。
    * CPU 的核心数有限，则线程的物理资源也是有限的。线程太多，上下文切换的开销大，并行效率下降。
    * 线程属于重量级资源，更好的做法是池化，并维护最小、最大线程数量。
* Q：线程池如何处理短时间内大量进入的并行计算业务？
    * A：JDK 中的线程池的抽象设计和具体实现。

#### Executor 执行者
* 最顶层
* interface Executor 仅一个方法：`execute(Runnable cmd)`，执行一个可运行的任务；任务执行器
* execute(Runnable cmd) 方法`无返回值`。

#### ExecutorService 
* 接口 API，interface ExecutorService 继承了 interface Executor
* 方法
    * `shutdown()`：立即停止接收新任务（还在运行中的不停止执行），关闭线程池。
        * shutdownNow()：立即停止接收新任务（还在运行中的也停止）。
        * shutdown() 是“优雅停机”。
        * boolean awaitTermination(timeOut, unit)：阻塞当前线程，返回是否线程都执行完。timeOut之后池中线程都执行完返回true，否则 false. 
        * `优雅停机的实现`：先调用 shutdown()，再调用 awaitTermination(timeOut, unit)；awaitTermination 返回 true，正常退出；返回 false，再调用 shutdownNow()，强制关闭已超时的线程。
    * 三个 `submit()` 重载方法，`返回 Future`（即可以把异步让给另一个线程去执行的任务的返回值&异常都封装在 Future 对象里）：submit(Runnable task), submit(Runnable task, T result), submit(Callable<T> task)
* submit() VS execute()
    * submit() 调用过程中，把另一个线程的返回值&异常都捕获了。
    * execute() 调用过程中，另一个异步线程的异常不在当前的上下文里，无法处理（在另一个线程的堆栈中抛出异常）。
    * 有差异的异常的讨论：算数异常。
        * submit()：发返回 number 类型的非数 NaN.
        * execute():在另一个线程的堆栈中抛出异常。

#### ThreadPoolExecutor
* 提交任务逻辑流程
    * 首先判断正在执行的线程数量是否已达到`池的核心线程数`。
        * 未达到：创建新的线程处理任务。
        * 达到：将当前任务添加到`工作队列/缓冲队列`，排队；队列有大小。
    * 缓冲队列满时，判断是否达到`最大线程数`。
        * 未达到：创建新线程。
        * 达到：执行`拒绝策略`（是否拒绝过多的任务）。
        * 达到上限的思考：前面核心线程数的线程有可能经过了大量I/O操作导致的暂停，CPU资源已被释放，但任务没有被处理完；此时再新起一些线程，可以复用这些已释放的CPU的时间片，提升池的整体效率。
* 核心步骤
    * addWorker(task, true)————创建新的线程处理任务
    * workQueue.offer(task)————将当前任务添加到`工作队列/缓冲队列`
    * addWorker(task, false)————拒绝
* 线程池参数    
    * `缓冲队列 BlockingQueue：双缓冲队列`
        * 保证并发安全，最大化提升存取效率：允许两个线程，同时向队列，一个存储一个取出。 
        * 实现类一：ArrayBlockingQueue
        > 类似ArrayList，底层是数组，构造时需指定容量大小。
        > 顺序：FIFO
        * 实现类二：LinkedBlockingQueue
        > 类似LinkedList，底层是链表，默认情况下容量大小不固定。
        > 顺序：FIFO
        * 实现类三：PriorityBlockingQueue
        > 类似LinkedBlockingQueue；对每个进入队列的对象按优先级排序（自然顺序 or 构造时传入Comparator比较器），然后入队。
        > 顺序：非FIFO，按优先级
        * 实现类四：SynchronizedQueue
        > 默认只能存一个数据（容量大小=1），则两个线程交替地读、写。
    * `拒绝策略`
        * 策略一：AbortPolicy（抛弃任务；抛出异常，人工干预任务处理）
        > 默认的拒绝策略。
        * 策略二：DiscardPolicy（抛弃当前任务；无异常，任务凭空消失）
        * 策略三：DiscradOldestPolicy（抛弃队列最早的任务，重新提交当前任务）
        * 策略四：CallerRunsPolicy（由提交任务的线程处理该任务）
        > 常用策略四：（原因）不丢任务 + 缓冲线程池当前的压力
* 重要属性和方法

字段/方法 | 备注
---|---
corePoolSize | 核心线程数
maximumPoolSize | 最大线程数
ThreadFactory threadFactory | 线程工厂（创建线程）
BlockingQueue<Runnable> workQueue | 工作队列/缓冲队列
RejectedExecutionHandler | 拒绝策略处理器
execute(Runnable task) | 执行任务
submit(Runnable task), submit(Runnable task, T result), submit(Callable<T> task) | 提交任务 

* 示例流程
    * 先定义核心线程数和最大线程数（一般设置为核心线程数的2倍，可以充分利用CPU）
    * 定义工作队列
    * 定义线程工厂
    * 利用以上参数创建一个 executor；不显式定义拒绝策略则使用默认策略

#### ThreadFactory
* 线程工厂：interface ThreadFactory
* 好处：线程池中具有相同配置、特定属性的一组线程，批量地由线程工厂创建。

#### Executors 工具类
* 创建线程
* 更方便！
* 静态方法

字段/方法 | 性质 | 备注
---|---|---
newSingle ThreadExecutor | 执行器 | 创建单线程的线程池（相当于单线程串行执行所有任务，可以保证任务处理的顺序；因异常结束的线程会有一个新线程来替代，保证池内线程数固定）
newFixedThreadPool | 线程池 | 创建固定大小的线程池（因异常结束的线程会有一个新线程来替代，保证池内线程数固定）
newCachedThreadPool | 线程池 | 创建可缓存的线程池（池的大小不固定；可以复用之前已执行完任务的空闲线程；超过`空闲时间`的线程会被回收，缩容）
newScheduledThreadPool | 线程池 | 创建大小无限的线程池（任务有指定的执行时间，定时调度）

* 线程池最大线程数的设置考量（假设 corePoolSize = N）
    * `CPU 密集型`：maximumPoolSize = N 或 N+1
    * `IO 密集型`：maximumPoolSize = 2N 或 2(N+1)

#### 基础接口
* `interface Callable`
    * 仅一个 call() 方法，有泛型的返回值
* `interface Future`
    * 对应异步执行的一个任务，最终需要拿到其返回值
    * 重要方法：get()，有2个重载方法

    > 预期异步线程很快执行完：get() throws InterruptedException, ExecutionException

    > 异步线程的执行时间不确定：get(long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutException

