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
* __问题——>解决方案__
    * 线程——>线程池
    * CPU 使用率——>减少 CPU 等待时间
    * 数据来回大量复制——>共享内存 & IO模型
* __核心技术：NIO（非阻塞I/O模型）__
    * Websocket 协议（Server 端给不同的 Client 端大量推送消息）
    * BIO（阻塞I/O模型）：server 一旦接收到一个 client 连接请求，建立通信socket进行读写操作；JVM 进程阻塞，此时不能再接收请求。用户进程等待内核进程 data copy 后唤醒，然后处理数据。
    * NIO（非阻塞I/O模型）：用户进程发起系统调用，轮询（即非阻塞）查看 data 是否 READY；READY后开始和BIO类似的阻塞 IO 处理，阻塞时间较短。帮助提高系统吞吐量。
    * IO Multiplexing（I/O多路复用模型）：将维护网络连接和处理数据两个流程分开，由不同线程处理，IO 处理流水线化。两个阻塞点，一是 fd 集合在用户态和内核态间来回拷贝（解决方案：epoll——用户态、内核态共享一块内存，通过回调解决遍历，fd 集合数量无限制），二是 IO 操作的后半阶段。基于 Reactor 模式，屏蔽了用户态和内核态交互的中间过程。
    * 信号驱动的I/O模型：基于 EDA（Event-Driven Architecture，事件驱动架构），网络请求由 handler 变为一个事件分发给多个线程处理；无需轮询，减少运行时等待，数据 READY 时 kernel 会发信号（后续由用户进程做data copy）。
    * 异步I/O模型：（阶段一）用户进程发出系统调用，返回；（阶段二）data READY，kernel 进行 data copy，然后发信号告诉用户进程 data 准备完毕。
* __标准框架：Netty（JAVA 网络应用编程首选框架）__
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
* 典型应用：API 网关（请求接入 + 业务聚合 + 中介策略 + 统一管理）
    * 流量网关：外层屏障，与业务无关；关注微服务集群，对性能有高要求。
        * 常见框架：OpenResty, Kong
    * 业务网关：关注业务，提供针对性的服务级别的相关操作（细粒度流控、聚合、发现、校验、过滤等处理）。
        * 常见框架：Spring Cloud Gateway, Zuul, Soul
            
#### 经验认识
* 高性能————高并发用户（大量并发业务连接），高吞吐量（单位时间内能处理较多的业务），低延迟（每个请求的处理时间较低），容量（超出上线有破坏性作用）
    * 弊端：系统复杂度、建设维护成本、故障的破坏性均会大幅增加。
    * 应对：限制容量，控制爆炸半径，工程积累与改进。
* 性能优化入手阶段：网络连接，数据准备，事件分发。
* Netty 优化
    * 永远不要阻塞 EventLoop！
    * 系统参数优化
    * 缓冲区优化：给 Bootstrap 绑定缓冲区；复用挥手状态未完全关闭的连接。
    * 心跳周期优化：短线重连（快速恢复网络，提升可用性），心跳机制（无高频数据包传输时主动探活）。
    * Byte Buffer 优化
    * 其他：ioRatio（IO操作和业操作的资源消耗比），Watermark（压力水位），TrafficShaping（网络流控保险丝）。
* API 网关架构设计
    * 思路：由简到繁，先实现业务核心框架，再在技术复杂度和业务复杂度上分别提升。
    * 流程：抽象（子组件和关键对象） -> 依赖（组件间的关系） -> 组件化 -> 拼成整体


### 3. 并发编程
#### 关键点：`Moore's Law 失败，“多核 + 分布式”时代来临`
* __多线程__
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
* __并发__
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
* 线程安全问题解决方案：（思路）减少锁的粒度，增加并发粒度
    * 方案一————同步块（关键字：synchronized），操作结果对其他线程可见。执行粒度：方法，对象（偏向锁，轻量级锁/乐观锁，重量级锁）。
    * 方案二————volatile（场景：单个线程写，多个线程读），操作前对操作后可见。替代方案：Atomic 原子操作类。
    * 方案三————final（场景：仅可读，跨线程安全）
* 四种经典利器
    * ThreadLocal 类（针对并发的线程安全问题。在当前线程内进行变量和数据的传递；同一线程跨方法调用栈的调用，在最外层将要操作的数据放入 ThreadLocal 实例）
    * Stream in JDK8（流水线化的处理模型，将批量数据的单线程处理和多线程并行处理在接口层面做了统一）
    * 伪并发问题
    * 分布式下的锁和计数器（分布式环境下应考虑并行，超出了线程的协作机制）
* 加锁前的考虑
    * 粒度：能小则小（意味着大部分代码可以并发执行）
    * 性能（提升效率）
    * 重入（防止线程卡死）
    * 公平（防止线程饿死）
    * 自旋锁（Spinlock，大大降低使用锁的开销）
    * 场景：必须基于业务场景！
* 线程间协作与通信
    * 共享数据和变量
    * 线程协作
    * 进程协作
    

### 4. Spring 和 ORM 等框架
#### 关键点
* __Spring__
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
* __Spring Boot__
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
* Spring / Spring Boot 使用 ORM 的经验
    * 本地事务
    * 多数据源
    * 数据库连接池配置
    * ORM 内的复杂 SQL，级联查询
    * ORM 辅助工具、插件
* 设计模式 & 设计原则
    * 设计原则
        * 面向对象的设计和编程原则 SOLID
        * 最小知识原则 KISS：（核心）高内聚，低耦合。
        * 编码规范
    * 设计模式
        * GoF 23（23个经典设计模式；面向接口编程）
            * 分类：创建型，结构型，行为型。
        * 3个层次：解决方案层，组件层（框架），代码层（GoF 23）。
* 单元测试
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
