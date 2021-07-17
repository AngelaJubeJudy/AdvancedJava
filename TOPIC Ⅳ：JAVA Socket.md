# TOPIC Ⅳ：JAVA Socket

## 1. Java Socket 编程：19'23''
### 大规模的并发IO挑战
* 核心技术：NIO
* 标准框架：Netty

### Java Socket
* 计算机基础知识
    * 所有进程复用同一个网络同一块网卡，IP和端口用于定位进程；范围0~65535
* 模型：Server端和Client端相互通信
    * server建立服务端监听socket，`绑定一个端口`
    * server等待并接收来自clients的连接请求
    * client创建连接socket，向server发起请求
    * （三次握手）server接收请求后创建连接socket
    * 相互通信，全双工：I/O, InputStream和OutputStream
    * 四次挥手，关闭连接
* 实现一个简单的HTTP服务器：HttpServer01.java
    * step 1: 创建 ServerSocket实例
    * step 2: 绑定端口8801
    * step 3: 通过accpet方法拿到client端的请求；打开双方的socket通道
    * step 4: 模拟输出 HTTP header 和 body
        * HTTP header 中需要写 `Content-Length`，避免Client端读错数据
        * 通过命令行压测：<Mac> `wrk -c 40 d30s http://localhost:8801`, <Win> `sb -u http://localhost:8801 -c 40 -N 30`；40个并发，运行30秒。
    * step 5: 关闭socket
* 思考：上述的`单线程`HTTP服务器如何优化？
    * HttpServer02.java：（改进点）每个client端的请求new一个新的线程，并行处理
    * 隐患：不断创建新的线程，对于线程这种重量级的资源，目前没有复用
* 思考：上述的`多线程`HTTP服务器如何优化？
    * HttpServer03.java：（改进点）固定大小的线程池
* “性能”——每秒请求数：HttpServer03.java > HttpServer02.java > HttpServer01.java


## 2. 深入讨论IO：11'08''
* 课前思考：
    * IO通信的过程中发生了什么？
    * 怎样更高效地提升通信的效率和性能？

### IO通信过程
* 2大类型的操作
    * 1. Server端的CPU计算 / 业务处理：`CPU密集型`
    * 2. IO操作与等待 / 网络、磁盘、数据库：`IO密集型`
* 案例分析：应用程序A通过网络与应用程序B通信，同时A会读取本地磁盘的文件
    * 分析：CPU资源利用率低（大部分线程执行时间CPU都在等待），资源浪费
    * 优化：“统筹学”，工作量不变，中间过程的等待时间减少，提升整体生产效率
    * 解决方案：IO密集型的应用，CPU资源可以在其IO等待时间里被另外一些业务线程抢占
* 深入思考
    * 背景：Linux上的内存分为`用户空间（运行用户的进程）`和`内核空间（底层进程）`
    * Socket 通信流程：
        * 输入：所有data先通过socket网卡读取`内核空间`，然后从内核空间复制到`用户空间`的JVM进程才能使用。
        * 输出：`用户空间`的JVM进程把data写到`内核空间`，内核空间的缓冲区写满后data通过socket发出去。
    * 问题分析：中间的这次cpoy，既浪费了内存，也使CPU使用率增高。
    * 实际场景：除线程、CPU的问题外，还有大量的`数据来回复制`的问题。
    * 优化一：只使用一块缓冲区（用户空间和内核空间共享缓冲区）
    * 优化二：对IO处理整个流程进一步细分，即`“流水线化处理”`，拆分为不同步骤（可以放在不同线程池处理每个步骤）
        * 技术栈：IO模型


## 3. I/O模型与相关概念：33'12''
### 计算机基础概念辨析
* 阻塞，非阻塞————`线程处理`模式
* 同步，异步————`通信`模式
* fd, file descriptor 文件描述符：Linux服务器中所有东西都是fd

### I/O模型分类
* `同步`通信
    * 阻塞I/O模型（BIO）
    * 非阻塞I/O模型（NIO）
    * I/O复用模型
    * 信号驱动的I/O模型
* `异步`通信
    * 异步I/O模型

### I/O模型详细
* BIO（示例：HttpServer01.java）
    * server一旦接收到一个client连接请求，建立通信socket进行读写操作；此时不能再接收请求
    * 中间过程：用户进程等待内核把 data 准备好、复制到用户空间，而后内核唤醒`被阻塞的JVM进程`处理 data
* NIO
    * 阶段一：用户进程发起系统调用，轮询（即`非阻塞`）查看 data 是否 READY；
    * 阶段二：READY后开始和BIO类似的`阻塞`I/O处理；阻塞时间就较短。
    * 效率远远高于BIO；轮询期间的资源被很好地利用。
* I/O Multiplexing：I/O多路复用模型，也叫“事件驱动I/O”
    * NIO的升级（NIO是使用`单个进程`来监控管理多个socket）
    * 优化点：多路复用，分工明确，系统整体运转效率提高；`维护网络连接`和`处理data`两个流程被分开，由不同线程处理，I/O处理的`“流水线化”`
    * 阻塞点1/2：“迎宾员”，select 或 poll；
        * select或poll的`缺点`：每次select，都需要把`fd集合`在用户态和内核态之间来回拷贝，fd集合较大时copy的成本很高；且每次都需要遍历fd集合查看哪些状态 READY 了，开销较大；同时select支持的fd集合数量太小，default=1024个。
        * solutions: `epoll` ————用户态和内核态`共享`一块内存（解决了来回copy问题，即不用做数据拷贝了）；fd集合上有一些回调函数（解决了遍历开销问题）；fd集合数量没有限制。
    * 阻塞点2/2：和NIO类似，发生在I/O操作的后半阶段。
    * 基于 `Reactor`：屏蔽了用户线程和内核打交道的中间过程。
* 信号驱动的I/O模型
    * 区别：数据准备阶段无需轮询（用户线程不再等待，业务更灵活），因为`数据READY时`kernel会发信号（后续由用户进程做data copy）
    * `EDA (Event-Driven Architecture)：事件驱动架构`
    * 流程：网络请求进来，由 handler 将请求变成一个事件，分发到多个线程进行处理。
    * 效率高，易扩展，可以充分利用多核处理能力
    * 优化点：请求量很大时，
        * 1. 在 event handler 之前加一个 `event queue`缓存待处理事件。
        * 2. 在 event handler 之后实现多个EDA架构，每个处理不同业务类型的事件。
        * 特点：整体平滑，易扩展，能应对大流量的复杂的并发访问处理体系。
        * SEDA：分阶段的EDA架构（上述）
* 异步I/O模型
    * `全程无阻塞`
    * 阶段一：用户进程发出系统调用，返回；
    * 阶段二：data准备完成，`kernel做data copy`，然后发信号告诉用户进程`I/O操作执行完毕`（区别：在信号驱动的I/O模型中，kernel发的信号是告诉用户进程`data准备完毕`）。

### 实际场景联想
* BIO：排队等待；自行打印。
* Reactor模式：拿号，不用排队等待；到号拿文件自行打印。
* Proactor模式：拿号，不用排队等待；老板帮忙打印好，通知去拿。


## 4. Netty 框架简介以及 Netty 使用示例：32'33''
### 计算机基础
* `WebSocket 协议`
    * 构建在`HTTP 1.1`基础上，复用了HTTP 1.1的`TCP通道`
    * 通过HTTP发请求，告诉服务端现在需要 Upgrade 协议到 WebSocket；通信双方通过底层的TCP通道相互发送二进制的报文数据。
    * 场景：`server端给不同的client端大量推送消息`。

### Netty 简述
* JAVA做`网络应用编程`的首选框架
* Netty内部设计实现的3部分
    * Netty核心————`ByteBuffer`， 通信API，事件模型
    * 传输服务层————底层网络协议、通信方式
    * 协议支持层————HTTP, WebSocket, 安全套接字协议SSL
* Netty是功能丰富的框架
    * data在网络传输阶段和具体的应用内存中支持多种序列化和编解码方式。
* 3大特点
    * `异步`
    * `事件驱动`————编程模型运行时减少等待
    * 基于`NIO`————提高吞吐量
* 3大适用场景
    * 通过编程方式实现网络应用程序的服务端
    * 通过编程方式实现网络应用程序的客户端
    * 需要使用 TCP / UDP / HTTP / SSL 等的协议时
* 从`高性能的协议服务器`角度看，有以下优点：
    * 高吞吐：NIO，容纳更多的并发连接请求
    * 低延迟：更充分合理地使用系统资源
    * 低开销
    * 零拷贝（不用在用户态和内核态之间来回拷贝数据，多路复用，共享内存）
    * 可扩容（缓冲区对象`ByteBuffer是动态可扩容的`，所以不论要处理的数据多大，网络应用程序都不会产生严重抖动）
* 从开发使用的角度看，有以下优点：
    * `松耦合`————网络处理和业务处理有抽象隔离
    * 易用，可维护性好
* 高性能的协议服务器
    * Netty支持大部分通用协议
    * Netty也支持自定义协议

### Netty 核心概念
* Channel
    * NIO基础概念，代表一个打开的连接，一个“管道”
    * `可写可读`数据（不用操作socket，直接操作channel）
* ChannelFuture
    * 一个封装，用于获取 channel 的状态
    * 可以`添加回调`方法：相当于通过`事件通知机制`拉起后续需要执行的处理逻辑
* Event & Handler
    * 通过发送事件传递消息
    * 事件处理器很重要!
* Encoder & Decoder
    * 编码器：把当前对象转换成通过Netty可以网络传输出去的二进制的数据对象
    * 解码器（上述过程的逆向处理）
    * 序列化 & 反序列化
* `ChannelPipeline`
    * 通用框架：针对不同的处理场景，处理流程不同；`流水线化`处理
    * 抽象网络应用的复杂的内部处理

### Netty内部运行期，一个具体的IO处理组成
* 1. 网络事件
* 2. 应用程序逻辑事件
* 3. 事件处理程序
    * 接口（入栈&出栈，`ChannelHandler`的2个默认实现）：`ChannelHandler`, ChannelOutboundHandler, ChannelInboundHandler
    * 适配器（针对不同使用场景）：ChannelOutboundHandlerAdapter, ChannelInboundHandlerAdapter
    * `入栈`事件：channel激活&停用，读操作事件，异常事件，用户事件
    * `出栈`事件：打开、关闭连接，写入、刷新数据
    * 入栈：对Server来说，就是client发生数据，从channel打开到Server拿到数据的过程。
    * 出栈：Server将数据写并发送到client

