# Final Project

## Solutions

### 1. JVM
* 关键点：
    * 定位（JVM 是基于栈的计算机器；栈操作指令，不与 JAVA 直接对应，属于 JAVA 四类指令之一）
    * 运行时状态（每个运行时的线程有一个独享的 JVM Stack，存储 Frame；逻辑概念“栈帧” = 操作数栈 + 局部变量数组 + class引用，每一次方法调用 JVM 会自动创建一个栈帧）
    * 类加载器：类加载的过程 = 加载 + 验证 + 准备 + 解析 + 初始化；类加载的时机（显示调用，隐式调用，不会初始化的时机）；类加载器的分类（BootstrapClassLoader——在JVM内部，是 JDK 最核心类；ExtClassLoader 扩展类加载器；AppClassLoader 应用类加载器）；类加载器的特点（双亲委托，负责依赖，缓存加载）。
    * 内存模型：`调用栈 Stack Trace`（由多个栈帧组成；一个线程对应一个线程栈/JAVA方法栈，每个线程都只能访问自己的线程栈；资源的隔离性——每执行一个方法，就给当前方法创建一个栈帧，所有原生类型的局部变量和对象的引用地址都存储在线程栈中），`堆内存`（又称“共享堆”，所有线程共享堆内存，堆内存包含所有 JAVA 代码中创建的对象内容；GC 负责创建、回收、销毁堆内存上的对象；分类——年轻代 Young-Gen & 老年代 Old-Gen，年轻代包括新生代 Eden sapce、存活区一 S1、存活区零 S0），`非堆 Non-heap`（存放元数据，包括 Metaspace, Compressed Class Space, Code Cache），`JVM 自身`，`堆外`（JVM 直接使用的计算机内存空间）。
    * 启动参数：系统属性，运行模式，堆内存设置（xmx, xms, xmn, meta, xss），GC 设置，分析诊断，JavaAgent。
* 经验认识
    * 内存模型————JVM除了使用堆内内存外，还有一些非堆和对外内存，因此Xmx不可设置的过大，谨防OOM内存溢出。
    * 内存模型————实际应用中可以把每个应用程序运行在VM或Docker里，资源隔离，不会互相抢占内存资源；指定 Xmx 为整个操作系统的 60%-80%，留出余量。


### 2. NIO
* 关键点：`大规模的并发 IO 挑战`
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
* 经验认识
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


