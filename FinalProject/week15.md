# Final Project
## Solutions
### 1. JVM
#### 关键点
* 定位（JVM 是基于栈的计算机器；栈操作指令，不与 JAVA 直接对应，属于 JAVA 四类指令之一）
* 运行时状态（每个运行时的线程有一个独享的 JVM Stack，存储 Frame；逻辑概念“栈帧” = 操作数栈 + 局部变量数组 + class引用，每一次方法调用 JVM 会自动创建一个栈帧）
* 类加载器：类加载的过程 = 加载 + 验证 + 准备 + 解析 + 初始化；类加载的时机（显示调用，隐式调用，不会初始化的时机）；类加载器的分类（BootstrapClassLoader——在JVM内部，是 JDK 最核心类；ExtClassLoader 扩展类加载器；AppClassLoader 应用类加载器）；类加载器的特点（双亲委托，负责依赖，缓存加载）。
* 内存模型：`调用栈 Stack Trace`（由多个栈帧组成；一个线程对应一个线程栈/JAVA方法栈，每个线程都只能访问自己的线程栈；资源的隔离性——每执行一个方法，就给当前方法创建一个栈帧，所有原生类型的局部变量和对象的引用地址都存储在线程栈中），`堆内存`（又称“共享堆”，所有线程共享堆内存，堆内存包含所有 JAVA 代码中创建的对象内容；GC 负责创建、回收、销毁堆内存上的对象；分类——年轻代 Young-Gen & 老年代 Old-Gen，年轻代包括新生代 Eden sapce、存活区一 S1、存活区零 S0），`非堆 Non-heap`（存放元数据，包括 Metaspace, Compressed Class Space, Code Cache），`JVM 自身`，`堆外`（JVM 直接使用的计算机内存空间）。
* 启动参数：系统属性，运行模式，堆内存设置（xmx, xms, xmn, meta, xss），GC 设置，分析诊断，JavaAgent。

#### 经验认识
* 内存模型————JVM除了使用堆内内存外，还有一些非堆和对外内存，因此Xmx不可设置的过大，谨防OOM内存溢出。
* 内存模型————实际应用中可以把每个应用程序运行在VM或Docker里，资源隔离，不会互相抢占内存资源；指定 Xmx 为整个操作系统的 60%-80%，留出余量。


### 2. NIO
#### 关键点：`大规模的并发 IO 挑战`
##### __问题——>解决方案__
* 线程——>线程池
* CPU 使用率——>减少 CPU 等待时间
* 数据来回大量复制——>共享内存 & IO模型
##### __核心技术：NIO（非阻塞I/O模型）__
* Websocket 协议（Server 端给不同的 Client 端大量推送消息）
* BIO（阻塞I/O模型）：server 一旦接收到一个 client 连接请求，建立通信socket进行读写操作；JVM 进程阻塞，此时不能再接收请求。用户进程等待内核进程 data copy 后唤醒，然后处理数据。
* NIO（非阻塞I/O模型）：用户进程发起系统调用，轮询（即非阻塞）查看 data 是否 READY；READY后开始和BIO类似的阻塞 IO 处理，阻塞时间较短。帮助提高系统吞吐量。
* IO Multiplexing（I/O多路复用模型）：将维护网络连接和处理数据两个流程分开，由不同线程处理，IO 处理流水线化。两个阻塞点，一是 fd 集合在用户态和内核态间来回拷贝（解决方案：epoll——用户态、内核态共享一块内存，通过回调解决遍历，fd 集合数量无限制），二是 IO 操作的后半阶段。基于 Reactor 模式，屏蔽了用户态和内核态交互的中间过程。
* 信号驱动的I/O模型：基于 EDA（Event-Driven Architecture，事件驱动架构），网络请求由 handler 变为一个事件分发给多个线程处理；无需轮询，减少运行时等待，数据 READY 时 kernel 会发信号（后续由用户进程做data copy）。
* 异步I/O模型：（阶段一）用户进程发出系统调用，返回；（阶段二）data READY，kernel 进行 data copy，然后发信号告诉用户进程 data 准备完毕。
##### __标准框架：Netty（JAVA 网络应用编程首选框架）__
* 内部设计实现：核心（动态可扩容的 Zero-Copy-Capable Rich Byte Buffer + 通用 API + 可扩展事件模型），传输服务层，协议支持层。
* 特性：异步，事件驱动，基于 NIO
* 优点：高性能（高吞吐，低延迟，低开销，零拷贝，可扩容），松耦合，易用
* 核心概念：Channel（一个打开的连接，可读可写数据，非阻塞）, ChannelFuture（用于获取连接的状态；可添加回调方法）, Event & Handler（事件处理器关联入站出站数据流）, Encoder & Decoder（用于序列化&反序列化）, ChannelPipeline（事件处理器链，流水线化顺序处理，不同场景流程不同）
* Netty 应用 = 网络事件 + 应用程序逻辑事件 + 事件处理程序（入站事件，出站事件，接口，适配器）
* Reactor 模式（一个 Service Handler，多个 Event Handler）：事件驱动，多路复用。Netty 支持三种模型，
    * 单线程模型：selector 身兼数职，负责 I/O 和负责业务的都是 reactor thread。
    * 多线程模型：I/O (reactor thread 处理，负责维护 socket 和分发事件) 和业务（worker thread pool 处理）在线程层面做了隔离。
    * 主从模型：主线程（mainReactor，负责维护网络连接），从线程（subReactor，负责时间分发）workder thread pool 负责业务处理，reactor thread pool 负责 I/O 操作。
* 关键对象
    * Bootstrap：启动线程。
    * NioEventLoopGroup：支持三种 Reactor 模型。
    * NioEventLoop：单线程，包含一个 selector；一个 EventLoop 可以绑定多个 SocketChannel，负责整个IO事件的生命周期（轮询监听 IO 事件，处理 IO 事件，处理任务队列）。
    * SocketChannel：handler 集合。
    * ChannelInitializer：绑定 handler 集合和 channel
    * ChannelPipeline：事件处理器链。
    * ChannelHandler：事件处理器。
        * 入站：channel --> ChannelInboundHandler --> 应用程序
        * 出站：应用程序 --> ChannelInboundHandler --> channel
##### 典型应用：API 网关（请求接入 + 业务聚合 + 中介策略 + 统一管理）
* 流量网关：外层屏障，与业务无关；关注微服务集群，对性能有高要求。
    * 常见框架：OpenResty, Kong
* 业务网关：关注业务，提供针对性的服务级别的相关操作（细粒度流控、聚合、发现、校验、过滤等处理）。
    * 常见框架：Spring Cloud Gateway, Zuul, Soul
            
#### 经验认识
##### 高性能————高并发用户（大量并发业务连接），高吞吐量（单位时间内能处理较多的业务），低延迟（每个请求的处理时间较低），容量（超出上线有破坏性作用）
* 弊端：系统复杂度、建设维护成本、故障的破坏性均会大幅增加。
* 应对：限制容量，控制爆炸半径，工程积累与改进。
* 性能优化入手阶段：网络连接，数据准备，事件分发。
##### Netty 优化
* 永远不要阻塞 EventLoop！
* 系统参数优化
* 缓冲区优化：给 Bootstrap 绑定缓冲区；复用挥手状态未完全关闭的连接。
* 心跳周期优化：短线重连（快速恢复网络，提升可用性），心跳机制（无高频数据包传输时主动探活）。
* Byte Buffer 优化
* 其他：ioRatio（IO操作和业操作的资源消耗比），Watermark（压力水位），TrafficShaping（网络流控保险丝）。
##### API 网关架构设计
* 思路：由简到繁，先实现业务核心框架，再在技术复杂度和业务复杂度上分别提升。
* 流程：抽象（子组件和关键对象） -> 依赖（组件间的关系） -> 组件化 -> 拼成整体


### 3. 并发编程
#### 关键点：`Moore's Law 失败，“多核 + 分布式”时代来临`
##### __多线程__
* 线程
    * 核心状态 RWB：READY（就绪；拿到锁，解除等待）, Runnable（执行 start() 启动新线程后，拿到 CPU 时间片前）, RUNNING（抢到了 CPU 时间片的线程运行）, WAITING / TIMED_WAITING（主动等待）, Blocked（被动等待；遇到同步代码块/锁，被通知）.
    * 创建：Runnable 接口（重载 run() 方法，定义当前线程里的一个任务），Thread 类（继承了 Runnabele 接口；调用 start() 方法，JVM 真正创建一个 OS 线程；重载 run() 方法，定义当前线程里的一个任务）。
    * 方法：run, start, join, sleep, wait, notify / notifyAll
    * 多线程间统一协调调度： wait, notify / notifyAll
    * 中断处理：方法一，interrupt() + InterruptedException 异常；方法二，设置一个外部的全局状态。
* 线程安全
    * 问题描述：不同线程竞争/同步相同资源。若资源的读写顺序敏感，则存在“竞态条件”（临界区：导致竞态条件发生的代码区）。
    * 并发相关性质：原子性，可见性（关键字：volatile，保证当前变量的更新立刻被更新到主内存，各线程的即时修改同步在各自的副本上；关键字 synchronized 和接口 Lock，保证统一时刻只有一个线程获取锁然后执行同步代码，释放锁前变量的所有修改刷新到主内存），有序性（“happens-before 原则”，便于在多线程代码运行时设置锚点）。
* 线程池
    * 出发点：线程属于重量级资源；CPU 核心数有限，线程的物理资源也有限；线程过多，上下文切换开销大，并行效率下降。
    * Executor 接口：顶层，包含一个无返回值的 execute(Runnable task) 方法。
    * ExecutorService 接口：继承 Executor 接口。shutdown() 方法，三个 submit() 方法。在 submit() 调用过程中，另一个线程的返回值 & 异常均可捕获。
    * ThreadPoolExecutor：（核心步骤）addWorder(task, true) --> workQueue.offer(task) --> addWorder(task, false)。首先判断正在执行的线程数量是否达到线程池的“核心线程数”；未达到，创建新线程处理任务；达到，放入工作队列/缓冲队列（BlockingQueue）。缓冲队列满时，判断是否达到“最大线程数”；未达到，创建新线程处理任务；达到（此时新线程可以复用已释放的 CPU 时间片），执行拒绝策略（不显式定义则使用默认策略）。
    * ThreadFactory：批量在线程池中创建具有相同配置、特定属性的一组线程。
    * Executors 工具类
    * 基础接口：Callable（call() 方法，得到有泛型的返回值），Future（对应异步执行的一个任务，最终需要拿到返回值；get() 方法的两个重载，一个是预期异步线程很快执行完，一个是异步线程的执行时长不确定）。
##### __并发__
* JAVA 并发包 JUC (java.util.concurrency)
    * 5类核心功能：锁，原子类，线程池，工具类，集合类。
    * 5类接口：锁机制类（Lock, Condition, ReentrantLock, ReadWriteLock, LockSupport），原子操作类（AtomicInteger, AtomicLong, LongAdder），线程池相关类（ Future, Callable, Executor, ExecutorService），信号量工具类（CountDownLatch, CyclicBarrier, Semaphore），并发集合类（CopyOnWriteArrayList, ConcurrentMap）。
* 锁（interface Lock）
    * 工具包：java.util.concurrent.locks
    * 出发点：显示的锁（更灵活） vs { wait & nofity 机制，synchronized 同步块机制}
    * interface Lock
        * 基础实现类：ReentrantLock，公平锁，非公平锁。
        * ReadWriteLock 读写锁：（场景）并发读、并发写（需要保证写期间数据的一致性），读多写少。
    * interface Condition
        * 一个锁可以有多个 Condition
    * LockSupport：静态方法
    * 最佳实践
        * 永远只在更新对象的成员变量时加锁
        * 永远只在访问可变的成员变量时加锁
        * 永远不在调用其他对象的方法时加锁（外部加锁，无法控制锁粒度）
    * 原则————“最小使用锁范围”
        * 降低锁范围：降低锁定代码的作用域（提升整体的运行效率）
        * 细分锁粒度：一个大锁拆分成多个小锁（提升并发能力）
* 并发原子类
    * 工具包：java.util.concurrent.atomic
    * 出发点：显示的锁 + { wait & nofity 机制，synchronized 同步块机制}，本质都是操作的串行化，相当于单线程处理，本质上未并发执行。
    * 底层原理：CAS 机制（CompareAndSwap，相当于乐观锁，通过自旋重试保证写入）。
    * 适用场景：并发压力一般时，无锁更快（大部分时候都是一次写入，并发性能提升。并发压力较大时， 本地不停自旋会占用大量资源；较小时，是否使用 CAS 影响不大）。
    * 改进：分段思想（将读写竞争热点 value 拆分成和线程数一样多的数组 cell[]，按线程数分段；每个线程写自己的 cell[i]，最后对数组求和）。
* 并发工具类
    * 面向更复杂多线程协作的场景
    * 基于队列同步器 AQS（AbstractQueuedSynchronizer，构建锁和并发工具类的基础，JUC 的核心组件）实现的并发工具类：抽象了竞争的资源和线程队列；更灵活、更细粒度
        * Semaphore：对当前进入队列的线程，同一时间下的并发线程数控制。
        * CountDownLatch：阻塞主线程，子线程均满足条件时，主线程继续。达到聚合点后不可复用。
    * CyclicBarrier：任务执行到一定阶段，等待其他任务对齐（阻塞各子线程，回调聚合）；阻塞 N 个线程时所有线程被唤醒继续。达到聚合点后，可循环使用（计数为 0 时重置为 N）。
    * Future 模式：Future / FutureTask / CompletableFuture
        * 单个线程/任务的执行结果：Future / FutureTask
        * 多个异步结果的组合、封装，异步的回调处理：CompletableFuture
* 并发集合类
    * List
        * 分类：ArrayList, LinkedList（均存在写冲突和读写冲突）
        * 线程安全问题解决方案
            * 读写操作加锁（大锁）
            * CopyOnWriteArrayList 类：对写加锁（串行写；每个线程写在各自副本上，写完替换原容器中引用的指针），对读采取快照思维（每个线程无锁并发读原容器）。实现读写分离，保证最终一致。
    * Map
        * 分类：HashMap, LinkedHashMap, ConcurrentHashMap
        * 写冲突 + 读写冲突 + keys()无序：HashMap, LinkedHashMap
        * 改进：ConcurrentHashMap（原理————“分段锁”：一个大的 HashMap 中默认定义16个 segment，即并发级别 concurrentLevel=16，降低了大锁的粒度。并发级别可调，最多允许16个线程并发地操作16个 segment）。
            * 退化（所有并发线程都focus在同一个segment）：HashMap + 大锁。
    * 解决方案总结
        * ArrayList, LinkedList：采用“副本机制”
        * HashMap, LinkedHashMap：采用分段锁或 CAS 机制

#### 经验认识
##### 线程安全问题解决方案：
* （思路）减少锁的粒度，增加并发粒度
* 方案一————同步块（关键字：synchronized），操作结果对其他线程可见。执行粒度：方法，对象（偏向锁，轻量级锁/乐观锁，重量级锁）。
* 方案二————volatile（场景：单个线程写，多个线程读），操作前对操作后可见。替代方案：Atomic 原子操作类。
* 方案三————final（场景：仅可读，跨线程安全）
##### 四种经典利器
* ThreadLocal 类（针对并发的线程安全问题。在当前线程内进行变量和数据的传递；同一线程跨方法调用栈的调用，在最外层将要操作的数据放入 ThreadLocal 实例）
* Stream in JDK8（流水线化的处理模型，将批量数据的单线程处理和多线程并行处理在接口层面做了统一）
* 伪并发问题
* 分布式下的锁和计数器（分布式环境下应考虑并行，超出了线程的协作机制）
##### 加锁前的考虑
* 粒度：能小则小（意味着大部分代码可以并发执行）
* 性能（提升效率）
* 重入（防止线程卡死）
* 公平（防止线程饿死）
* 自旋锁（Spinlock，大大降低使用锁的开销）
* 场景：必须基于业务场景！
##### 线程间协作与通信
* 共享数据和变量
* 线程协作
* 进程协作
    

### 4. Spring 和 ORM 等框架
#### 关键点
##### __Spring__
* 框架设计  
    * 6大模块：Core (Bean / Context / AOP), Testing (Mock / TextContext), Data Access (Tx / JDBC / ORM), Spring MVC / WebFlux (web), Integration (remoting / JMS / WS), Language (Kotlin / Groovy).
    * 引入 Spring ≈ 引入一种研发协作模式：项目天然水平分层（展示层，业务层，服务层，持久化层），项目垂直分层（按业务模块），项目组件化（细粒度拆解，更好地协作管控）。
* __Spring AOP (Aspect Orient Programming)__
    * 需求：Spring 在 Bean 的生命周期管理和其他对象间引用装配的核心功能基础上，增加中间层，实现对象包装（不改变原有 Bean 的定义功能，通过代理 or 字节码增强技术实现），满足针对已有代码的额外控制需求。
    * Spring AOP 通过动态代理实现。
    * 对象装配思路的改进：IoC (Inverse of Control)，也称“依赖注入（DI, Dependency Injection）”。
        * 使用：运行期无需改代码，只需修改配置文件。
        * 属性之间的循环依赖问题：Spring 中，相互依赖的对象各自独立创建，内部属性各自装配。在使用 AOP 的场景，显式拿到 Bean；之后通过代码显式地注入其他依赖对象时，从中间层拿到的是代理类或运行期生成的子类（而非真实对象），故不存在循环依赖问题。
    * 概念：Advice 通知（前置/后置/环绕）, joint point 连接点（插入切面，调用方法）, PointCut 切点（插入增强处理）, Aspect 切面（通知和切点的结合）, Introduction 引入（现有类添加新的方法/属性）, Weaving 织入（增强处理加入目标对象）。
    * 使用
        * 接口类型的对象：默认使用 jdkProxy (JDK的动态代理)，生成代理。如果也使用字节码增强技术，需要开启 proxyTargetClass 选项。
        * 非接口类型的对象：默认使用 CGlib 做字节码增强，生成子类。
        * 相同点：都是先操作代理/子类，最终再调用原始对象/方法，返回结果。
        * 方式：代码（AOP 的类） + XML；注解。
    * 典型用途：日志，权限判断，事务控制。
    * 字节码增强 vs 反射 
        * 字节码操作：运行期在内存里动态拼出的新类型。
        * 反射：破坏了面向对象的封装；窥探内部，隐式调用。
* __Spring Bean__
    * Spring 中的一个类，可以注册成一个 Bean，之后被 Spring 初始化成一个可用对象。Spring 是对 Bean 管理的基础设施。
    * Bean 的加载过程：构造函数 --> 依赖注入 --> BeanName Aware --> BeanFactory Aware --> ApplicationContext Aware --> BeanPostPrecessor 前置方法 --> InitializingBean --> 自定义 init() 方法 --> BeanPostProcessor 后置方法 --> Bean 的使用 --> DisposableBean --> 自定义 destroy() 方法
    * 代码过程：Bean 的实例化、属性赋值、初始化（先检查 Aware 装配，之后做前置处理，调用 init() 方法，然后做后置处理）、销毁等。
    * 思考：与 ClassLoader 的加载过程有哪些相似？ 
* __Spring XML__
    * 需求：Spring Bean 的配置
        * 方式演化：XML 配置 --> 半自动注解配置 --> Java Config 配置 --> 全自动注解配置。
    * XML 的 schemas（描述 XML 文件格式）的定义：XSD 文件（Spring 中默认格式，功能更全），DTD 文件（文档类型的定义，格式为“注册//组织//类型 标签//语言”）。
        * XSD 文件在当前 jar 包中。
        * spring.schemas 文本文件在 Spring-bean 的 jar 包，用于校验 XML 文件内容/格式。
        * spring.handlers：运行期将 XML 的 Bean 定义加载，变成实际运行的 JAVA 对象的 Bean。
    * 配置原理
        * 使用 Spring 自带的自定义标签，定义一个 applicationContext.xml 文件。
        * 通过 spring.schemas 文本文件，找到 jar 包中的 XSD 文件，校验 XML 文件配置的正确性。
        * Spring 程序被加载、Spring 容器初始化的过程中，schemaLocation 找到每个 NS 对应的 NamespaceHandler，将 DOM 对象树解析成对象，将内容交给 NamespaceHandler，最终变成 Spring 的 Bean。
    * 配置简化（牺牲灵活性）
        * 自动化 XML 配置工具
        * XSD 和 Bean 之间的转换：Spring @Comments 注解里的组件  XmlBeans
        * XSD 和实体类之间的转换：XmlBeans 类库
        * 插件：Spring-xbean
    * 解析 XML 的工具
        * DOM：全部加载到内存，解析成 DOM 对象树。
        * SAX / StAX：流式便利节点。
    * XML 和 Bean/POJO JAVA 对象的相互转换的工具
        * xbean
        * XStream 开源框架
* __Spring Messaging__
    * Messaging：发送、接收消息，消息的流动
        * MQ 应用场景：同步转异步 / 简化多系统间通信的网络拓扑。
    * JMS (Java Messaging Service)：JAVA 中的消息规范
        * 工具包：javax.jms.*
        * 消息模式：Queue（一个消费者；默认持久化），Topic（多个消费者；默认无持久化）。
        * 消息的行为模式：生产消费模式，发布订阅模式
##### __Spring Boot__
* 框架设计
    * 从 Spring 到 Spring Boot 的优化：“约定大于配置”（零配置 & 默认约定）。
    * 基于 Maven 和 POM
    * 核心原理：自动化配置，Spring Boot Starter（将对应的框架技术和 Spring 框架做粘合）。
    * 功能特性：独立运行的 Spring 应用，无需部署 WAR 包，限定性的 starter 依赖，必要时自动化配置，提供生产 produce-ready 特性。
    * 配置  
        * 文件：默认 resources 文件夹存放默认配置文件 application.yml 或 application.properties；多种配置文件，默认使用 spring.profiles.active 属性决定运行环境（开发/测试/生产）时的配置文件。
        * 加载：通过配置类加载成 Configuration，之后创建 Bean 并初始化。 
        * 条件化自动配置：运行时灵活组装，避免冲突。
* Spring Boot Starter
    * 独立项目，单独打包；结构与一般的 JAVA 项目一致。
    * 配置文件：spring.provides（写入当前 starter 的名字），spring.factories（写入自动配置的类），addtional-spring-configuration-metadata.json（类似Spring的XSD文件）。
    * SpringBootConfiguration类： Spring Boot 项目被拉起的入口点。
* JDBC & ORM——Hibernate/MyBatis
    * JAVA 数据库操作核心 API————JDBC：使用统一的编程模型访问不同的数据库。
        * 每个数据库需要提供独一无二的驱动包。
        * 缓存优化：DataSource，Pool 连接池（提高应用程序可用性）。
        * JDBC 上的增强：加 XA 事务，使用连接池，MySQL 驱动 JDBC 接口。
    * ORM
        * Hibernate：先定`实体类和 hbm 映射关系文件 --> 使用 HQL 操作对象中的属性，用面向对象的方式写 SQL --> 返回的数据自动变成配置好的映射关系。优势：可以使用 JPA 接口操作，作为 JPA(Java Persistence API) 规范的适配实现。
        * MyBatis：半自动化ORM。可以用 XML 或注解配置映射，将接口和 POJOs 映射成数据库记录。
    * Spring / Spring Boot 集成 ORM / JPA
        * Spring 操作关系型数据库
            * Spring JDBC 组件：封装 JDBC 接口，使用连接池等技术，操作管理 DataSource。
            * Spring ORM 包：封装 JPA 接口，操作 EntityManager。
        * Spring 操作非关系型数据库：类似JPA操作关系型数据库（使用面向对象操作）。
        * Spring 管理事务
            * JDBC 层：编程式事务管理
            * Spring 框架层：事务管理器 + AOP
        * Spring 集成 MyBatis：项目中 resources 文件夹下有各实体类的 mapper.xml 配置（mapper 在 MyBatis 里相当于 DAO）。
        * Spring 集成 Hibernate / JPA
            * 配置 `EntityManagerFactory`：注入数据源，指定JPA的适配器是Hibernate的JPA，指定实体类的位置，指定其他配置属性。
            * 配置事务管理器（EntityManager 接口由 Hibernate 适配器自动生成）。
            * 其他类似 Spring 集成 MyBatis
        * Spring Boot 集成更简单。

#### 经验认识
##### Spring / Spring Boot 使用 ORM 的经验
* 本地事务
* 多数据源
* 数据库连接池配置
* ORM 内的复杂 SQL，级联查询
* ORM 辅助工具、插件
##### 设计模式 & 设计原则
* 设计原则
    * 面向对象的设计和编程原则 SOLID
    * 最小知识原则 KISS：（核心）高内聚，低耦合。
    * 编码规范
* 设计模式
    * GoF 23（23个经典设计模式；面向接口编程）
        * 分类：创建型，结构型，行为型。
    * 3个层次：解决方案层，组件层（框架），代码层（GoF 23）。
##### 单元测试
* 本质：白盒测试 + 自动化测试
* 粒度：单元测试（业务方法测试；开发人员编写，数量 > 业务方法） --> 集成测试（服务测试） --> 功能测试（端到端测试）。 
* 优势
    * 明确所有的边界处理
    * 保证代码符合预期
    * 在开发时期提前发现问题，降低 bug 修复成本
* 经验
    * 一个方法一个case，且断言要充分、提示要明确
    * 应覆盖所有边界条件
    * 充分使用 Mock 技术
    * 不好写，则反向优化代码，解决代码设计问题
    * 批量测试使用参数化的单元测试
    * 单元测试默认是单线程的（可能有“环境污染问题”）
        * 尽量少修改全局变量、静态变量
        * 合理使用 before, after, setup 准备环境
        * 尽量不使用外部的数据库和资源
            * 若必须使用，考虑嵌入式数据库、事务的自动回滚 
    * 合理使用通用测试基类（避免重复）
    * 配合 checkstyle、coverage 等工具
    * 制定单测覆盖率基线


### 5. MySQL 数据库和 SQL
#### 关键点
##### 性能优化
* 低延迟 vs 高吞吐
* 量化：制定业务指标
* 考虑点：时机，业务场景
##### __DB 与 SQL 优化__
* 是业务系统优化的的核心
    * 业务处理本身无状态，系统的状态在数据库中存储。
    * 业务系统规模扩大，数据量扩大，且各系统内部实现完全不同。
* 数据库设计范式（实体表的合理拆分）
    * 1NF：当且仅当关系 R 中每个属性的值域只包含原子项（不可拆分项）。
    * 2NF：满足1NF，消除非主属性对码（即主键，可由多列联合组成）的部分函数依赖。
    * 3NF：满足2NF，消除非主属性对码的传递函数依赖。
    * BCNF：满足3NF，消除非主属性对码的部分函数依赖和传递函数依赖。
    * 4NF：消除非平凡的多值依赖。
    * 5NF：消除不合适的连接依赖。
    * 实际场景一：故意加一些冗余字段（常用字段），提高查询效率。
    * 实际场景二：不需要依赖主键去其他表查数据：从表也在当前表中。
##### __MySQL__ 
* 关系型数据库
    * 以关系模型描述、表达数据。
    * 以关系代数理论操作、运算。
* 两个主流分支版本：MySQL, MariaDB
* 执行引擎 / 存储引擎
    
    存储引擎 | MyISAM | InnoDB | Memory | Archive  
    ---|---|---|---|---   
    存储限制 | 256TB | 64TB | 看内存大小 | 压缩在磁盘上
    事务支持 | x | √ | x | x
    索引支持 | √ | √ | √ | x
    锁的粒度 | 表锁 | 行锁 | 表锁 | 行锁
    数据压缩 | √ | x | x | √
    外键 | x | √ | x | x

* 索引原理
    * 数据按页分块。
    * InnoDB 引擎使用 B+ 树或 Hash 实现索引。
    * B-Tree / B-Tree / B+Tree 类型：默认数据按主键索引的结构存储。
* 配置优化
    * 关于“连接请求”的变量
    * 关于“缓冲区”的变量
    * 配置 InnoDB 的变量
* 事务
    * 事务隔离：数据库的基础特征。
    * InnoDB：支持事务的存储引擎。
    * 可靠性模型：ACID (Atomicity, Consistency, Isolation, Durability)
    * 隔离级别（涉及 Isolation）
        * 读未提交 READ UNCOMMITTED （不保证一致性、对性能要求高的场景）
            * 问题：脏读，幻读，不可重复读
        * 读已提交 READ COMMITTED (RC)
            * 问题：幻读，不可重复读
        * 可重复读 REPEATABLE READ (RR)
            * InnoDB 的默认隔离级别；仅支持基于行的 binlog。
            * 使用了MVCC技术（多版本并发控制）：快照机制，保证事务在执行时看到的数据快照的一致性。
        * 可串行化 SERIALIZABLE （串行处理，隔离最严格，性能最低）
    * 隔离范围：全局，会话。
    * 日志
        * undo log 撤销日志：保证原子性（Atomicity）；用于回滚。
        * redo log 重做日志：保证持久性（Durability）；记录事务对数据页做的修改。
* 锁
    * 表级锁，行级锁
    * 死锁
    * 乐观锁：先尝试操作，有冲突再重新读，重新尝试，本地自旋。
    * 悲观锁：在释放锁之前，其他事务会被该锁阻塞；影响性能。
        * 改进：无锁 / 乐观锁。
    * 锁的竞争不是很激烈时，乐观锁的效率远高于悲观锁。
##### __主从复制__
* 目标：解决单机数据库的读写压力问题。
* 核心：主库写 binlog；从库订阅主库，本地化从主库拉取的数据成为 relay log，按其中的顺序和指令执行 SQL 线程。
* 原理：
    * 异步复制：可能造成主从数据不一致。
    * 半同步复制：可靠性较纯异步较好；超时确认，主库可能会退化到传统的异步复制。
    * 组复制：所有节点对等，不存在主从；基于分布式 Paxos 协议实现，保证分布式数据一致性。存在多节点写冲突。
* 局限性    
    * 主从延迟问题
    * 应用侧需要配合读写分离框架
    * 未解决高可用问题
##### __读写分离__
* 目标：提升数据库集群读的能力。
* 实现：配置多个数据源。
    * 支持配置多个从库
    * 支持多个从库的负载均衡
* 切换数据源的“侵入性”问题
    * 其他考虑：降低侵入性会导致“写完读”数据不一致问题！
    * solution: ShardingSphere-jdbc 的 Master-Slave 功能。
        * SQL 解析和事务管理，自动实现读写分离。
        * 可以解决“写完读”不一致问题。
* 旧系统改造问题    
    * 思路：多个读写分离、主从复制的数据库作为一个单独的虚拟数据库使用；仅修改数据库连接字符串（即连接指向）。
    * solution：MyCat / ShardingSphere-Proxy 的 Master-Slave 功能。
        * 部署一个中间件：读写分离、主从复制的规则配置在中间件。
        * 中间件模拟一个 MySQL 服务器：对业务系统几乎零侵入。
##### __高可用__
* 目标：提供 Failover 能力，防止物理机宕机对集群的影响，保证系统持续可用的时间（更少的不可用服务时间）。
* 指标：SLA / SLO。
* 方案1~2：MySQL 外部；方案3~5：MySQL 内部。
    * 方案1：主从手动切换
        * 侵入性问题：数据库和应用系统之间的中间层的大量的配置和脚本定义；代码的侵入性问题。
    * 方案2：MHA (Master High Availability)
        * 目标：故障切换，主从提升。
        * 问题：需要配置SSH信息；需要至少3台服务器。
    * 方案3：MGR (MySQL Group Replication)
        * 目标：数据可靠性复制（基于组复制），主从切换。
        * 特点：高一致性，高容错性，高扩展性，高灵活性。
        * 使用场景：弹性复制；高可用分片。
        * 问题：从外部（应用程序或中间层）获得主从状态变更，需要读数据库；外部需使用 LVS/VIP 配置。
    * 方案4：MySQL Cluster
        * 完整的数据库层高可用方案。
        * 组成：MGR 核心组件 + MySQL Router（提供负载均衡，配置读写分离、高可用规则） + MySQL Shell（Cluster Admin 管理控制台）
    * 方案5：Orchestractor 编排器
        * 一款 MySQL 高可用和复制拓扑管理工具。
        * 特点：自动发现 MySQL 的复制拓扑关系，可在 Web 界面重构复制关系，可自动/手动恢复主节点异常，支持命令行和 Web 界面管理复制。

#### 经验认识
##### __DB 与 SQL 设计优化__
* 数据
    * 类型：选取合适的、明确的类型，避免字节数浪费。
    * 数据量：初期应考虑系统增量，合理使用类型；新增字段，增加从表；新增索引，在停机维护阶段进行。
    * 尽量避免修改表结构：尽量避免修改 DDL 文件，尽量避免增加索引。
    * 大批量写入优化
        * solution 1: PreparedStatement，减少SQL解析。
        * solution 2: 多值（INSERT语句中拼多条记录） / 批量（PreparedStatement中ADD BATCH）插入。
        * solution 3: Load Data 原生命令，文本文件直接导入数据。
        * solution 4: 先把约束和索引去除，导入数据；之后一次性重建所有约束和索引。
    * 合理拆分宽表：提高执行效率。
* 索引
    * Hash 类型：适合内存中的索引。
    * B-Tree / B-Tree / B+Tree 类型：按块存储数据，适合磁盘中的索引；默认按主键顺序索引。
    * 字段选择：计算字段的选择性，= DISTINCT(col)/count(*)；重复性越低，选择性越好，越适合作为索引；等于1时最好。
    * 组合索引的构建：应避免索引冗余（长短索引共存时端索引冗余；数据库默认对唯一约束产生索引，则有唯一约束的索引与其他列组合时冗余）。
    * 索引失效
        * 与“空”的比较操作：NULL, not, not in
        * 函数（用函数也走不了索引）
        * 减少使用 'or'：使用 'union'（已去重；'union all' 未去重）
        * 数据量大：放弃所有条件组合都走索引的幻想，直接全文检索。
        * 必要时：'force index', 告诉数据库强制走某个索引。
* 查询
    * SQL：使用简单的 SQL，避免隐式转换。
    * 设计：主键单调递增，避免出现“页分裂”问题。
    * 设计：主键长度不宜过大，避免影响每个数据块能容纳的数据条数。
    * 设计：尽量不使用外键、触发器。
    * 速度：按主键 vs 按非主键
        * 按主键：更快。“聚集索引”。
        * 按非主键：“二级索引”，单独的索引文件，不直接对应数据。
    * 模糊查询
        * 数据量小：使用 LIKE（默认前缀匹配）。
        * 数据量大：建立”全文检索“的倒排索引；使用 ElasticSearch / solr 等全文检索类工具。
    * 连接查询
        * 驱动表的选择：驱动表越小，数据越明确。
* 存储引擎（恰当选择）
    * InnoDB：主流默认选择；强事务。
    * MyISAM：不需要事务，数据操作量较大。
    * Memory：数据量小，不需要持久化。
    * Archive：针对归档数据。
    * ToKuDB：针对归档数据（高压缩比，有大量重复数据时，压缩效率超高）。
* 参考 DBA 指导手册 / 数据库设计规范
##### 优化场景：高效分页
* 改进一 ：确定查询的记录总数只需要查主表，重写 count 值。
* 改进二：大数量级的分页，降序查询。
* 改进三：大数量级的分页，ID索引，精确定位。
* 改进四：非精确分页。
* 改进五：全文检索。


### 6. 分库分表
#### 关键点
##### 目标：解决容量问题；将整个节点的数据量变小，降低单节点写压力，提升整个系统的容量上限。
##### 实现：分布式数据库作为数据分片的集群提供服务。
* 指导原则：扩展立方体
    * x-axis：建集群（水平；最简单，整体扩展）<== 全部数据
    * y-axis：业务拆分（垂直；按需，子系统的扩展）<== 业务分类数据
    * z-axis：数据分片（拆分数据；同类数据，不同扩展方式）<== 任意数据
##### 数据库垂直拆分
* 拆库：一个数据库按不同业务处理能力拆分成不同数据库。
* 拆表：针对单表数据量过（宽表）的情况进行拆分（一个主表 -> 一个核心表+多个子表）。
* 优：数据库集群的性能和容量整体提升（并行数据处理能力提升），系统和数据复杂度降低。
* 缺：管理复杂；对业务系统侵入性强；改造过程复杂，易出故障；拆分有上限。
* 步骤：梳理拆分范围，检查评估和重构影响到的服务；准备新的数据库集群复制数据；修改系统配置，上线。
##### 数据库水平拆分
* 分库：数据放在不同库。
* 分表：数据放在不同表。
* 优：解决容量问题；对系统的影响小于垂直拆分。
* 缺：管理复杂；复杂 SQL 支持；数据迁移问题（扩缩容）；一致性问题。
* 拆分建议：不建议分表。
    * 每个 MySQL 实例上可以建虚拟的DB，类似于分表的效果。
##### 工具：框架和中间件
* JAVA 框架层：TDDL，Apache ShardingShpere-JDBC
* 中间件层：处于业务系统和数据库中间，模拟数据库。
    * ShardingSphere：一套开源的分布式数据库中间件解决方案组成的生态圈，提供标准化的数据分片、分布式事务、数据库治理；含3款产品：JDBC, Proxy, Sidecar。
* 引入成本比较：框架 < 中间件 < 分布式数据库/数据网格
##### 分库分表导致的一致性问题
* solution：分布式事务
    * 一致性要求：在分布式条件下，多个结点的整体事务一致性。
    * 场景要求一：严格的一致性————solution：数据库支持XA协议。
    * 场景要求二：准实时/非实时的处理————solution：不用事务 or 使用柔性事务框架。
* solution 1：XA 分布式事务
    * 一致性要求：强一致性
    * 需要数据库对 XA 事务的支持。
    * 模型
        * AP, Application Program：由应用程序发起事务。
        * RM, Resource Manager：多个，管理具体资源（如数据库）。
        * TM, Transaction Manager：事务管理器；通知资源，控制协调本地事务提交/回滚。
    * JAVA 中的分布式事务框架：Atomikos, JBOSS Naratana, Seata（支持 TCC / AT）.
    * 问题
        * 同步阻塞问题
        * 单点故障
        * 数据不一致
* solution 2：BASE 柔性事务（Basically Avaiable, Soft State, Eventually Consistent）
    * 一致性要求：最终一致性
    * 适合场景：长事务 & 高并发
    * 模式
        * TCC / SAGA：手动补偿。TCC 模式三段逻辑都是独立的事务（准备操作 Try，确认操作 Commit，取消操作 Cancel）；SAGA 无 Try 阶段，直接提交事务。
        * AT：自动补偿；两阶段提交。
* 事务的发展：本地事务 -> XA（二阶段）强一致性事务 -> BASE 最终一致性事务

#### 经验认识
##### 数据迁移：新系统与老数据（异构数据迁移易出故障）
* 方式一：全量
    * 优：简单
    * 缺：停机时间随数据量上升，对业务影响较大
* 方式二：全量 + 增量（所有库表都有时间戳及状态字段）
    * 优：停机时间较短
    * 缺：数据库主库的读压力
* 方式三：全量 + 增量 + binlog
    * 需要中间件支持：模拟从库，订阅读取 binlog，拿到数据，写入集群
        * 历史数据：历史 binlog，全量
        * 实时增量数据：主库正在执行的，增量
    * 优：无需额外寻找增量的时间点，无需去主库读数据；平滑迁移，新老数据库可并行使用；可实现多线程断点续传，并发数据同步；可实现自定义复杂异构数据结构；可实现自动扩缩容。
* 中间件工具：ShardingSphere-Scaling（模拟MySQL从库）
    * 支持数据全量和增量同步
    * 支持断点续传和多线程数据同步
    * 支持数据库异构复制和动态扩容
    * 可视化配置


### 7. RPC 和微服务
#### 关键点
##### __RPC (Remote Procedure Call)__
* 关键原理
    * 设计————RPC 是基于接口的远程异构型分布式服务调用，client 和 server 必须共享“服务契约/服务的接口契约（Service Contract）”。
        * 共享的信息：POJO 实体类的定义，接口的定义，服务契约的定义。
        * 角色：远程 = service provider，本地 = service comsumer
        * Stub 存根进程：远程的本地代理；“Stub + RPC Runtime” 屏蔽了远程过程调用的网络调用细节，负责参数的编解码、网络通信；像调用本地方法一样调用远程方法。
    * 代理————（实现）接口的动态代理/实现类。
    * 序列化————语言原生的序列化（不能跨平台；RMI, Remoting 等） / 二进制（可跨平台，信息精简） / 文本（可跨平台，人类友好，数据量大；JSON, XML 等）。
    * 网络传输————（方式一）TCP/SSL/TLS，性能更好；（方式二）HTTP/HTTPS。
    * 查找实现类————通过接口查找服务端的实现类；一般通过注册的方式。
* 技术框架
    * 语言原生 RPC 技术
        * （JAVA）RMI，（.NET）Remoting
    * 常见技术（根据技术原理分为三类）
        * Corba (= OMG IDL + 对象请求代理 + IIOP 标准协议) / RMI /.NET Remoting
        * 基于 HTTP 规范传输：JSON RPC, XML RPC, WebService (2个框架：Axis2, CXF)。
        * 序列化基于二进制：Hessian（基于 HTTP 规范；性能高），Thrift（基于 TCP 规范），Protocol Buffer，gRPC（云原生环境下的 RPC 标准）。
* 设计
    * 基于 RPC 技术原理
        * 设计：基于共享接口？基于 IDL？
        * 代理：基于动态代理？基于 AOP？
        * 序列化：原生？基于二进制？基于文本？
        * 网络传输：TCP? HTTP?
        * 查找实现类：服务端如何查找并处理？
    * 实现 RPC 框架核心：API 部分，client 部分，server 部分
        * API 部分：定义接口的请求 & 响应 + 定义 POJO 实体类。
        * client 部分（服务的消费者）：创建动态代理（实现对远程服务的调用），封装请求对象（包含接口名、方法名、参数列表），辅助发送请求、接收响应。
        * server 部分（服务的提供者）：暴露服务路径（注册/更新到 ZooKeeper），将请求反序列化化成请求对象，查找服务实现类（通过 resolver 查找到 Spring 实现类，拿到具体实现）。
* 从 RPC 到分布式服务化
    * 大规模分布式服务化下的 RPC 增强：在 client 端和 server 端对 RPC 本身的机制做增强。
    * 注册中心————服务提供者列表
        * 服务端 --> 注册中心：每个服务的可用实例与服务部署状态一致。
        * 注册中心 --> 客户端：注册中心通过客户端的服务发现去更新服务列表。
    * 客户端————服务发现
        * client————调用模块：负载均衡，容错，透明
        * RPC 协议：序列化，协议编码，网络传输（双向传输）
    * 服务端————服务暴露
        * server————处理程序（线程池）
        * RPC 协议：反序列化，协议解码，网络传输（双向传输）
    * 区别
        * RPC：技术概念（开发级别）
            * 在技术之上可以考虑性能优化、使用 Spring Boot 等封装，使更易用。
        * 分布式服务化：服务是业务语义；业务与系统的集成 
            * 分布式服务化框架角度：功能性需求 + 非功能性需求
##### __Apache Dubbo__
* 服务框架
    * 特点：高性能，轻量级，灵活扩展，简单易用。
    * 核心能力
        * 面向接口代理的高性能 RPC 调用
        * 智能负载均衡（内置策略） 
        * 服务自动注册与发现（准实时的注册中心）
        * 高度可扩展能力（Dubbo 结构：一个微内核+N个插件；所有组件都是插件，灵活）
        * 运行期流量调度（内置条件判断、脚本等路由策略）
        * 可视化的服务治理与运维
    * 基础功能：RPC 调用（Dubbo 内核）
        * 核心抽象模型：Provider 服务提供者，Consumer 消费者（消费者 invoke 服务提供者），Registry 注册中心，Monitor 监控。
        * 主路：Provider 服务提供者，Consumer 服务消费者。
        * 旁路Registry 注册中心，Monitor 监控；异步调用。
        * 基于 RPC 的其他支持：多协议，服务的注册发现，配置、元数据的管理。
        * 特点：框架分层设计，可任意组装和扩展模块。
    * 扩展功能：集群，高可用，管控
    * 设计
        * 服务的一次调用：生产 Proxy --> Filter（是否本地调用） --> 封装了 cluster 功能的 Invoker --> Registry（拿到 Directory） --> LoadBalance --> Filter（本地调用的增强） --> 封装了 RPC 协议的 Invoker --> 发送请求 --> Codec 编码和 Serialization 序列化 --> server ThreadPool 接收请求 --> Server 处理请求 --> Exporter 暴露服务 --> Filter 做响应的增强 --> Invoker 调用实现类。
* 原理
    * 分层设计
        * 纵向：Provider 服务提供者，Consumer 服务消费者
        * 横向：1层 Service 层（Business 模块，业务接口层），9层 Dubbo 定义的（RPC, Remoting 模块）。
            * RPC 模块：config 配置层，proxy 服务代理层，registry 注册中心层，cluster 路由层，monitor 监控层，protocol 远程调用层。
            * Remoting 模块：exchange 信息交换层，transport 网络传输层，serialize 数据序列化层。
    * SPI 的应用
        * SPI：需要自己做实现类的接口。
        * ServiceLoader 机制：实现控制反转，解决了框架侧无法感知业务侧的关于框架接口的实现类的问题。
            * 类似机制：Callback（框架侧预留的放置实现类的集合），EventBug（处于框架侧和业务侧中间），Dubbo 的 SPI 扩展。
        * Dubbo 启动时，进行所有 SPI 扩展的装配（装配完的对象都缓存在 ExtensionLoader 中，避免二次加载）。
    * 引用服务
        * 服务暴露：所有服务都使用 URL 的方式描述。
        * Directory 目录服务（list of invokers）：每个 invoker 代表了对某个服务提供者的引用；负责从注册中心拉取当前服务的所有可用的服务提供者列表。
        * 实现：通过 ServiceReference
        * 流程：配置对远程服务的调用（ReferenceConfig） --> 指定 protocol --> 引入 invoker --> ProxyFactory 转换成真正的远程调用 --> ServiceReference.
        * 泛化引用（GenericService）
            * 已知接口、方法、参数，不需要对本地调用创建一个 Stub 存根，采用反射的方法即可调用服务。
    * 集群 & 路由
        * Dubbo 的 Cluster 模块
        * Router 路由：负责选择此次调用能提供服务的 invokers 集合。
        * LoadBalance：从上述 invokers 集合中选择单个的服务提供者。
    * 隐式传参：context 模式，上下文变量传到另外一侧（参数可传播到 RPC 调用全过程，透过网络被感知）。
    * mock
        * 期望：本地开发调试，只调用本地mock（方便）。
        * Dubbo 框架中的流程：服务的一次调用先经过 Proxy --> 接下来经过 Filter 看是否本地调用 --> 在本地寻找相同接口名、但后缀为 Mock 的实现类（加载并作为当前Bean的实现类）。
* 重点模块
    * 核心概念层：common, config, filter, rpc/remoting/serialization.
    * 集群与分布式：cluster, registry/configcenter/metadata. 
* 场景
    * 分布式服务化改造：数据拆分，服务分布化。
    * 开放平台
        * 开放模式————“微内核 + API”；星状/网状结构，分布式服务化。
        * 容器模式————开放一套 SPI，集中集成服务能力。
    * 基于 Dubbo 实现 BFF（直接作为前端使用的后端）：建议不要改变业务层，在中间加一层 Controller层 / Web层；灵活支持前台业务，即向中台发展。
    * 基于 Dubbo 实现业务中台
* 最佳实践
    * 开发分包
        * 通用接口：涉及服务接口、服务模型、服务异常。
        * 服务接口：粒度尽可能大，以业务场景为单位划分（聚合），每个服务方法代表一个功能（避免一致性问题）。
    * 环境隔离与分组
        * 多注册中心机制（每个负责一部分服务的注册）
        * Group 机制（group 间服务地址隔离）
        * 版本机制（向后兼容；不可向后兼容的，必须通过变更版本号升级）
        * Tag 机制
    * 参数配置
        * 通用参数：以 Consumer 端为准。
        * Provider 端的配置：与提供服务的能力相关。
    * 容器化部署————“注册的 IP 问题”
        * 描述：容器内服务提供者使用的 IP 如果注册在外部注册中心，则服务消费者将无法访问。
        * solution 1：docker 使用宿主机网络。
        * solution 2：docker 参数指定注册的 IP 和 port 参数。
    * 运维与监控
        * 简单，需定制：管理控制台 Admin
        * 可观测性强：tracing 全链路跟踪, metrics 指标监控, logging 日志统计分析。
    * 分布式事务
        * Dubbo 支持柔性事务（SAGA/TCC, AT）：Seata（AT）或 Dubbo + hmily（TCC）。
    * 重试与幂等
        * 场景：服务调用失败，若设计不幂等，多次重试会造成业务重复处理。
        * 幂等接口设计：去重；类似乐观锁的机制，允许重复。
##### __Distributed Service__
* 分布式服务化 vs SOA (Service-Oriented Architecture) / ESB
    * SOA / ESB：服务汇聚到 ESB（中心节点）；代理调用，直接增强。
    * 分布式服务化：（框架）功能性需求 + 非功能性需求；直连调用，侧边增强。新增配置中心、注册中心，管理有状态的部分（持久化状态）；无状态的部分放在业务侧。。
* 配置/注册/元数据中心
    * 配置中心：ConfigCenter
        * 管理启动、运行期（开关控制）的配置参数信息，业务无关
        * 主流基座：Zookeeper, etcd, Nacos, Apollo 等
    * 注册中心：RegistryCenter
        * 管理相同的服务注册，提供服务发现和协调能力。
        * 消费者通过 HTTP 或 RPC 方式动态获取生产者集群的状态变化。
    * 元数据中心：MetadataCenter
        * 显式定义业务模型
        * 管理各节点元数据信息
    * 比较
        * 相同：需要保存、读取数据和状态；需要通知变更。
        * 不同：配置中心保存全局的、非业务的参数；注册中心保存运行期临时状态；元数据中心保存业务模型。
    * 实现：存取数据的能力 + 数据变化的实时通知机制；基座 namespace，在顶层隔离不同环境。
* 服务的注册与发现
    * 注册：服务提供者在服务启动时将自己注册到注册中心的临时节点；停机/宕机时，临时节点消失，准实时通知已订阅服务的消费者。格式：key（服务 / 服务+版本） + node（描述信息）。
    * 发现：消费者启动时，从注册中心代表当前服务的主节点拿到临时节点列表（即可用的服务提供者集合；后由注册中心通知消费者刷新），并本地缓存。
* 服务的集群与路由
    * 服务路由（Service Route）：对当前的服务提供者列表过滤，返回子集（运行期的动态分组）。
    * 服务负载均衡（Service LoadBalance）：制定策略，均匀分散调用压力。
* 服务的过滤与监控
    * 服务过滤
        * `计算机中任何复杂处理的都可以抽象为“管道（Pipeline） + 过滤器（Filter）”的模式。`
        * 实现额外增强；中断当前处理流程，返回特定数据。
    * 服务流控（Flow Control）
        * 基于过滤实现，用于输入请求大于处理能力的情况。
        * 3个级别：限流（线程数/调用数/数量），服务降级（仅保留核心逻辑），过载保护（系统短时间内不处理新业务，积压输入处理完再恢复）。
##### __Microservice__
* 架构
    * 服务架构发展：单体架构 --> 垂直架构（关注系统：横向抽象聚合，纵向按业务拆分） --> SOA 架构（关注服务；接口契约定义服务） --> 微服务架构 MSA（一个应用系统实现一组微服务，每个微服务完整自洽）。
    * 微服务架构发展：响应式微服务 -> 服务网格 -> 数据库网格 -> 云原生 -> 单元化架构。
        * 响应式微服务 MicroService：专注于数据流和变化传递，异步编程。
        * 服务网格 ServiceMesh & 云原生 Cloud-Native
            * 服务网格：服务间通过 Sidecar 通信串联；服务间的网络通信和控制策略下沉到基础设施。
            * 云原生体系：微服务、容器化、持续交付、DevOps 等技术组成
        * 数据库网格 DatabaseMesh：节点间通过 Sidecar 连接数据库。
        * 单元化架构 Cell Architecture
            * 以单元为组织架构：单元即容量、部署、容灾、高可用的基本单元。
            * 以单元化部署为调度单位
    * 基于场景的比较
        * 单体架构：复杂度较低时性能好。
        * 微服务架构：适用于大规模复杂业务系统的架构升级与中台建设。
    * 落地
        * 准备阶段：调研 -> 分析 -> 规划 -> 组织
        * 实施阶段：拆分 -> 部署 -> 治理 -> 改进
* Spring Cloud 技术体系
    * 生态架构：微服务 + Spring Cloud + 第三方组件
    * 第三方组件
        * 配置 & 注册：Config / Eureka / Consul
        * 网关：Zuul (BIO) / Zuul2 (NIO) / Spring Cloud Gateway 
        * 通信：Feign / Ribbon
        * 流控：Hystrix / Alibaba Sentinel / Reslient4j
* 相关框架与工具
    * APM (Application Performance Monitor) 应用性能监控
    * 权限控制
        * 3A: Authc (Authentication), Authz (Authorization), Audit 审计。
        * 框架：SpringSecurity, Apache Shiro
    * 网关与通信
        * 流量网关 & WAF，业务网关
        * 通信：REST（易用）与其他协议（性能稍好，但可维护性较低）
    * 数据处理

#### 经验认识
##### 从 RPC 到分布式服务化
* 大规模`分布式业务场景`里的非功能性需求考虑
    * 多个相同服务如何管理？==> 集群/分组/版本 ==> 分布式与集群
    * （大量服务）服务的注册发现机制 ==> 注册中心/注册/发现 
    * 如何做到负载均衡、路由等集群功能？==> 路由/负载均衡
    * （大流量）请求量较大时，熔断、限流等治理能力 ==> 过滤/流控/过载保护 
    * 心跳、重试等策略
    * （非功能性需求）高可用、监控、性能等
* 微服务架构最佳实践
    * 最佳实践一：遗留系统改造
        * 功能剥离，数据解耦 --> 自然拆分 --> 谨慎迭代 --> 灰度发布 --> 提质量线。
    * 最佳实践二：恰当粒度拆分
        * 原则：高内聚，低耦合；不同阶段不同要点。
    * 最佳实践三：扩展立方体（AFK）：单元化架构的基础
        * X-axis: 水平复制系统
        * Y-axis: 业务功能解耦
        * Z-axis: 数据分区
    * 最佳实践四：自动化管理
        * 测试、部署、运维更复杂：需要自动化提升效率
    * 最佳实践五：分布式事务
        * 各微服务操作的数据天然隔离：建议进行补偿/冲正（撤销事务的影响）。
    * 最佳实践六：完善监控体系
        * 业务监控，系统监控，报警预警，故障处理。

