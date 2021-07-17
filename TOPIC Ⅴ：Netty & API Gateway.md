# TOPIC Ⅴ：Netty & API Gateway

## 1. 什么是高性能：19'37''
### 理解
* `高并发用户（Concurrent Users）`：业务系统能同时处理大量并发的连接请求
* `高吞吐量（Throughout）`：单位时间内能处理足够多的业务；事务 TPS，查询 QPS
* `低延迟（Latency）`：每个业务/请求处理时间较短
* `容量`：超出容量上限有破坏性作用
* 压测实践：sb -u http://localhost:8808 -c 40 -N 30
    * 高并发用户（Concurrent Users）：命令行参数的并发用户数'-c 40'
    * 高吞吐量（Throughout）：结果中的QPS 'Requests/sec'
    * 低延迟（Latency）：命令行参数'--latency'，结果中的 'Latency Distribution'
        * 平均延迟：有时不能反映真实情况（系统延迟偏差较大）
        * 百分位延迟：P50, P75, P90, P99（百分之X的请求在t时间完成了）

### 高性能的B面
* 系统复杂度 UP UP UP
* 建设、维护成本 UP UP UP
* 故障的破坏性 UP UP UP

### 应对策略：“混沌工程”——系统的而稳定性建设
* 容量：超限就可能出事故；预估-->改造-->压测容量。
* 爆炸半径：代码重启、变更（范围要尽可能得小）的时候更容易出故障。
* 积累与改进：过往经历根因分析，针对性措施分类加入标准流程中，便于改进。


## 2. Netty 如何实现高性能：26'41''
### 从 BIO/Socket IO 到 NIO
* BIO
    * 使用不同子线程处理请求；效率较低
    * 每个线程的处理流程：read -> decode -> compute -> encode -> send
    * 其中IO相关操作时，线程空等待，造成系统资源浪费
    * server 承接所有 client 端请求
    * “事件处理机制”：请求d -> event queue队列 -> event mediator分发给多个事件channeld -> channel下是具体线程
        * 支持大量并发的连接请求
* Reactor 模型
    * 事件机制：ServiceHandler线程（负责IO操作）里的eventDispatch分发事件给不同处理线程（负责业务操作）
    * 多路复用
* 并发编程界大牛 `Doug Lea`
    * Reactor 模型提出者

### Reactor 模型
* `Reactor 单线程模型`
    * selector 身兼数职：
        * 维护网络连接状态，
        * 轮询看数据是否准备好，
        * 调用 Handler 处理业务数据
    * 效率不高：负责IO和负责业务的都是reactor thread，可能产生相互干扰
* `Reactor 多线程模型`
    * 业务处理模块：“线程池”
    * IO和业务在线程层面做了隔离
    * reactor thread：负责IO操作，维护socket + 分发事件 
    * worker thread pool：负责业务处理
    * 优势：模式可扩展
* `Reactor 主从模型`
    * mainReactor 线程：负责网络请求连接状态维护
    * subReactor 线程：负责事件分发处理 
    * worker thread pool：负责业务处理
    * reactor thread pool：负责IP操作
* 优化性能的思考
    * 拆解为三个阶段：网络连接，数据准备，事件分发

### Netty 框架与 Reactor 模型
* Netty支持以上三种Reactor模型
* EventLoopGroup
    * 单线程模式：new NioEventLoopGroup(1)
    * 多线程模式：new NioEventLoopGroup()
    * 主从模式：bossGroup, workerGroup 
* Netty启动和处理流程
    * new NioEventLoopGroup()，创建线程池；
    * 绑定端口访问NettyServer；
    * 建立socket连接，通信稳定后client和server互发数据；
    * 从NioEventLoop分发到NioSocketChannel；
    * workGroup注册多个`NioEventLoop`（每个绑定若干handler），进行业务处理
* 核心对象：`NioEventLoop`
    * 带了selector的一个线程
    * 可以直接和channel通信（一个EventLoop可以绑定多个channel）
    * 内部不断对IO事件进行循环，“自旋”看是否有数据要处理
    * 本质：相当于Netty的CPU，或者工厂的工人；负责整个事件的生命周期

### Netty 关键对象
* Bootstrap：启动线程，应用程序入口
* EventLoopGroup
    * 多个 EventLoop
* EventLoop
    * 绑定多个 SocketChannel
* SocketChannel
    * 对应 pipeline，即 Handler 的集合
* ChannelInitializer
    * 把 Handler 的集合和 channel 进行绑定
* ChannelPipeline：处理器链
* ChannelHandler：处理器

### ChannelPipeline 的结构
* 入栈：channel --> ChannelInboundHandler --> 应用程序
* 出栈：应用程序 --> ChannelInboundHandler --> channel


## 3. Netty 网络程序优化：34'13''
### TCP协议：粘包与拆包问题
* 人为
* 应用层 solution：通信前，双方约定数据包的组成和结构，是否定长；字符串按分隔符计算完整报文
    * Netty中常见的5个编解码器：定长的解码器，基于文本行的解码器，指定分隔符的基于文本行的解码器，变长的（报文头中指定长度）解码器，JSON格式解码器
* 网络层 solution
    * 大量小数据包引发的网络拥堵
    * “Nagle算法”，设定发送数据包的条件：缓冲区满了，或超时（平衡网络拥堵和资源利用）
    * 对延迟要求较高的系统：打开参数 TCP_NODELAY（此时Nagle算法被禁用）
    * 底层物理网络也是按数据包传输
    * `MTU, Maxitum Transmission`：网络的最大传输单元；大小固定，1500字节，其中1460字节（MSS）用于数据，20字节用于TCP header，20字节用于IP header。

### TCP 如何建立连接
* 三次握手：由client发起
    * server先绑定端口监听，进入 LISTEN 状态
    * client：在吗
    * server：在，你在吗
    * client：在
    * 成功建立连接，相互发送数据
* 四次挥手：双方均可发起
    * client：通信结束
    * server：收到
    * server：确认吗（之后立即关闭连接）
    * client：确认（`等待2个MSL`之后关闭连接）
* MSL（Linux默认1分支）：资源被占用，未完全释放（一次压测后等一段时间后再压测）
    * solution 1：降低时间窗口 MSL 的值
    * solution 2：复用未关闭的连接
* UDP 协议无“握手”机制，数据包在网络上广播，不保证是否收到

### Netty 优化
* 核心：永远不要阻塞 EventLoop
    * EventLoop是`单线程`
* 系统参数优化
    * 文件描述符的使用上限
    * MSL 的配置修改（建议改短）
* 缓冲区优化
    * 给 Bootstrap 绑定
    * backlog：正在建立过程中的状态最多能接收的网络连接数
    * 复用：挥手状态的，没完全关闭的连接
* 心跳周期优化
    * 短线重连：快速恢复网络，提升可用性
    * 没有高频数据包传输时：心跳机制，主动探活
* ByteBuffer优化
    * DirectBuffer：使用直接内存，即堆外内存；不受GC影响，效率高
    * HeapBuffer：堆内存，受GC影响
* 其他
    * ioRatio：IO操作和业务操作的资源消耗；默认50:50
    * Watermark：高低水位；适应当前压力
    * TrafficShaping：网络流量整形，流控；“保险丝”


## 4. 典型应用：API 网关：19'33''
### 提出背景
* 所有业务服务化之后（微服务架构），系统内部的部署关系复杂
* 外部需要借助寻址能力调用系统内部的需求
* 中间层上的业务服务聚合需求
* API 网关的4大职能
    * 请求接入：海量并发连接
    * 业务聚合：后端服务接口的聚合
    * 中介策略：安全、验证、路由、过滤、流控等，和业务无关和性能相关的能力集成
    * 统一管理：相当于把所有微服务体系管理起来

### 分类
* 流量网关：外层屏障，`系统的稳定和安全，与业务无关`；关注微服务集群，对性能有高要求
* 业务网关：关注业务，提供`针对性的服务级别的`相关操作（`细粒度`流控、聚合、发现、校验、过滤等处理）；满足不同用户需求

### 应用
* Zuul: 
    * 请求流程：HTTP Request -> pre filter -> routing filter (router) -> origin servers
    * 响应流程：origin servers -> post filter -> client
* Zuul 2.x 
    * Netty 重构版：内部BIO换成了NIO
    * Netty HTTP Server：网关接入端
    * Netty Client Handlers：接出端
    * Inbound filter：请求流程
    * Outbound filter：响应流程
    * Endpoint filter：路由
* Spring Cloud Gateway
    * Request -> adapter -> dispatch handler -> handler mapping -> web handler -> filters -> service
    * 复用了 Spring 5.x 里的 Web 模块 WebFlux 项目，底层是 Netty

### 常见框架和工具
* `流量网关：性能好`
    * OpenResty：基于Nignx插件机制，引入Lua引擎，可编程，扩大了应用场景
    * Kong：进一步完善了 OpenResty 的插件机制，提供开箱即用的模块，有控制台
* `业务网关：扩展性好`，适合二次开发
    * Spring Cloud Gateway：任何依托于Spring Web的项目可以通过映射URL添加网关能力
    * Zuul 2.x
    * `Soul`：整合了主流的微服务框架，开箱即用，有管理控制台配置网关能力


## 5. 动手实现：API 网关：18'15''

### gateway 1.0
* 请求流程：REQ -> (gateway) -> `HTTP Server` -> 后端服务
* Netty 网关：处于后端服务之前
* 只有代理转发能力

### gateway 2.0
* 请求流程：REQ -> (gateway) -> HTTP Server -> `filters` -> 后端服务
* 过滤请求：增强（增加安全认证等），拦截，修改
* 对响应的数据也可以过滤
* 满足更多功能和非功能性的管控需求

### gateway 3.0
* 请求流程：REQ -> (gateway) -> HTTP Server -> filters -> `routers` -> 后端服务
* 高可用：每个后端服务多个部署节点（多个服务实例），通过 router 功能决定请求选取哪个实例调用（负载均衡）

### 示例
* Inbound  
    * HTTPInboundServer：请求的入口
    * HTTPInboundHandler
    * HTTPInboundInitializer
* Outbound
    * HTTPOutboundServer
    * HTTPOutboundHandler：配置后端服务的真实 URL 地址；有线程池
    * HTTPOutboundInitializer
* Filter
    * HttpRequestFilter
    * HttpResponseFilter
* Router
    * 后端有多个业务服务时使用
    * HttpEndpointRouter

### 架构设计
* 设计思考：由简到繁，先实现业务的最核心骨架
    * 技术复杂度
    * 业务复杂度
* 抽象
    * 概念：子组件，关键对象
    * 命名
* 组合
    * 组件之间的关系：依赖与调用，系统的组件化
* 流程：抽象 -> 依赖 -> 组件化 -> 拼成整体
