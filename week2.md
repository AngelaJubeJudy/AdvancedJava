# Week 2: 2021-06-28 ~ 07-04
## 时长共计：243min 55s = 4h 3min 55s

# 第三课
## 1. GC 日志解读与分析：50'16''
### JVM调优的三个指标
* GC 
* 线程运行情况
* 内存的使用情况

### 模拟GC的情况
* GCLogAnalysis.java 文件：模拟业务系统
    * Young 区：1秒内不断新建对象
    * Old 区：垃圾对象缓存在另一个对象中（有引用while外的'cachedGarbage'，因此GC时缓存不会被回收，从而进入老年代）
        * 先编译.java文件
        * 运行：参数 `-XX:+PrintGCDetails`
        ```bash
        java -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:gc.demo.log -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * 注：以上命令中存在“[JDK9及以后版本启动脚本兼容性问题导致项目无法启动](https://blog.csdn.net/weixin_44305208/article/details/113915321)”问题。
    * JVM有默认堆内存配置参数，只执行 "java GCLogAnalysis" 时（日常）。
    * 日志解读
        * 第一段：堆内存的变化情况（包括：GC发生原因 + GC暂停时间；GC执行前后的内存大小变化）
        * 第二段：CPU 使用情况
        * Full GC 做 Old 区 GC 时，Young 区被清空。
        * 不同参数下的GC次数比较：`Xmx/Xms` 设置为较小值时，Full GC次数变多，GC更频繁；更容易出现`堆内存溢出（OutOfMemoryError）`。`Xmx/Xms` 设置为较大值时，GC暂停时间会变长。
        * 不配置参数`Xms`会导致Full GC的次数增多，单位时间内GC频率上升。因为堆内存小了（蓄水池小了），容纳的对象少，需要频繁回收。
    * 概念辨析
        * Young GC vs Full GC (Young GC + Old GC) ————
        * Minor GC 小型 vs Major GC 大型 ———— 一般Young GC被叫做Minor GC，对堆内存的影响较小。
    * 不同 GC 算法下的辨析（JDK 8默认为并行GC算法）
        * 串行GC（`DefNew`，Young区GC）：
        ```bash
        java -XX:+PrintGCDetails -XX:+UseSerialGC -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * 并行GC：
        ```bash
        java -XX:+PrintGCDetails -XX:+UseParallelGC -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * CMS GC（`Parnew` 针对 Young 区，`CMS GC` 针对 Old 区）：
        ```bash
        java -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * 注：CMS GC 发生过程中有可能会发生一次或多次 Young GC
        * G1 GC（过程最复杂，可以只看概要 '`-XX:+PrintGC`'）：
        ```bash
        java -XX:+PrintGCDetails -XX:+UseG1GC -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * G1 GC各阶段：
        > Evacuation Pause: young ———— 纯年轻代模式转移暂停
        > Concurrent Marking ———— 并发标记
        > 阶段一：Initial Mark ———— 初始标记
        > 阶段二：Root Region Scan ———— Root区扫描
        > 阶段三：Concurrent Mark ———— 并发标记
        > 阶段四：Remark ———— 再次标记
        > 阶段五：Cleanup ———— 清理
        > Evacuation Pause (mixed) ———— 转移暂停（混合模式）
        > Full GC (Allocation Failure)

### 工具
* 在线（可视化）：GCEasy
    * 地址：gceasy.io
    * 操作：把GC的log文件上传 / 拷贝log文件粘贴在输入框
* JAVA 包：GCViewer

### 课后小结
* 如何查看、分析不同GC配置下的日志信息？
* 各种GC有什么特点和使用场景？


## 2. JVM 线程堆栈分析/内存分析与相关工具：40'15''
### JVM线程模型
* 三个层面
    * JAVA层面：Thread对象
    * JVM层面：JavaThread （thread.start()之后）
    * OS层面：系统线程（物理线程；运行完之后线程被终止，在OS层面被销毁）
* 种类
    * 用户自定义业务线程（除以下几种之外的线程）
    * JVM内部线程
        * VM 线程（单例）
        * 定时任务线程（单例）
        * GC线程（多个）
        * 编译器线程（JVM运行时产生的热代码被编译为本地代码）
        * 信号分发线程（例，ctrl+C中断线程）
* 安全：JVM调用物理线程干活时，干活代码里插入了检查的安全点；干活期间不断检查
    * 在检查点上暂停
    * JVM安全点状态：所有线程都处于安全点状态（线程暂停，线程栈在这一点上不变）
* 工具
    * jstack
    * jcmd
    * kill -3
    * JMX
    * jconsole
    * fastthread.io（提交一个线程栈用于检查）

### 内存分析与相关工具
* Q：一个对象，1000个属性 vs 1000个对象，每个一个属性
    * 后者占用内存更多
    * 对象在内存中的结构：对象头 + 对象体 + alignment
    * 对象头 = 标记字 + class指针 + 数组长度
    * 对象体 = padding + 实例数据
    * 对象的字节数不是4字节（32位）或8字节（64位）的倍数时，需要对齐！！！
    * 对齐的2种方式：（内部）padding，（外部）alignment
* 查看对象占用内存的工具
    * 开源框架 JOL (Java Object Layout)：用于查看对象内存布局
    * Java API 中的Instrumentation类里的getObjecySize()方法：估算对象占用内存
    * 命令行 'jmap -histo pid'：列出所有实例数和占用的字节数
    * 实战：Byte 类一个占用 16 bytes，Integer 类一个占用 16 bytes（由此可见，包装类型的内存占用远大于原生类型）
* 总结
    * `64位JVM`中：对象头占用12个字节，以 `8-Byte 对齐`因此需要占用16个字节（`一个空类的实例`）
    * `32位JVM`中：对象头占用8个字节，以 `4-Byte 对齐` 
    * 64位JVM需要多消耗堆内存！！！
* 包装类型
    * Integer: 占用16个字节（= 标记字8 + class指针4 + int类型数据4）
    * Long: 占用24个字节（= 标记字8 + class指针4 + long类型数据8 + 对齐4）
    * 压缩指针：堆内存不大时，JVM开启4字节保存指针，节约内存空间
* 多维数组和字符串
    * 多维数组：每多一个维度，都是new一个单独的对象，额外占用16字节
    * 二维数组：每个嵌套的第二维都是一个单独的对象，额外占用16字节
    * 上例：int[128][2]，则内存占用计算为 [(8+4+4) + 4*2]*128 + 16 = 3600字节
    * 上例：int[256]，则内存占用计算为 4*256 + (8+4+4)) = 1040字节
    * 字符串对象：一个String类有24字节的额外开销
* 大问题：内存泄漏（OOM, OutOfMemory）
    * 解决方案一：加大堆内存容量
    * 解决方案二：增大 PermGen / Metaspace 区的大小（原因：加载到内存的类太多或体积太大，超出PermGen区的大小）
    * 高版本的JVM可以支持卸载元数据区的class：使用 '`-XX:+CMSClassUnloadingEnabled`' 参数
    * 解决方案三（诱因——不能创建本地线程了，堆内存快用完了）：降低Xss / 调整操作系统的线程数限制 / 调整代码减少线程使用
    * 内存Dump分析工具：Eclipse MAT, jhat


## 3. JVM 分析调优经验：29'51''
### 经验指标一：分配速率 Allocation Rate
* 年轻代的新对象的分配（单位时间内的内存分配量）
    * 单位：MB/sec
    * 过高：影响系统性能（业务的资源变少），产生巨大GC开销
    * 持续大于回收速率：OOM
    * 较低：健康（与回收速率基本持平）
    * 分配速率和回收速率都很高：亚健康
* 新对象创建发生在`Eden区`：分配速率高，Eden区快速被填满，导致`Minor GC高频发生`（STW频率上升；进而影响吞吐量）
    * Q：Eden区占Young区80%空间，Young区占堆内存1/3空间
    * `2 solutions: 增大Young区 / Young区和Old区等比例增大`
        * 隐患——“`蓄水池效应`”：Young GC每次暂停时间变长（频率降低）

### 经验指标二：晋升速率 / 提升速率 Premature Promotion
* 从年轻代晋升到老年代的速率（单位时间内的晋升到Old区的数据量）
    * 单位：MB/sec
    * 存活时间短的过早晋升：Major GC / Full GC 暂停时间变长，影响系统吞吐量
    * Q：老年代上的GC算法是针对存活时间较长的对象设计的
    * `2 solutions: （相对/绝对，通过修改参数实现）增加年轻代大小 / 减少每次业务处理的内存使用量`
        * 主体思路：`让临时数据在年轻代存得下`
* 计算
    * 晋升到老年代的部分 = 堆内存减少的数量 - Young区减少的数量
* 3个现象
    * 测试：配置"`-Xmx24m -XX:NewSize=16m -XX:MaxTenuringThreshold=1`"参数模拟
    * 短时间内的大量 Full GC
    * 每次 Full GC后，老年代使用率较低：对象存活时间短
    * 分配速率的数值与晋升速率接近


## 4. JVM 疑难情况问题分析：27'17''
### Arthas：JVM分析诊断利器
* 阿里的开源工具

### 从现象收集指标，通过关联性分析异常 
* 来源一：业务日志
    * 依赖，请求压力等
* 来源二：系统的资源使用情况
    * 硬件，网络，架构，负载等
* 来源三：性能
    * 数据库连接数、索引等，中间件，底层软件
* 来源四：操作系统日志
* 来源五：APM
* 来源六：`排查应用系统`（优化效果非常明细；成本小，不用修改代码）
    * GC问题，配置文件，线程，代码，单元测试等
* 来源七：资源竞争、坏邻居性能
* 来源八：疑难问题

### 实战分析
* 问题描述：GC暂停时间峰值较高，且时间发生突然；需要控制在200ms以内。
* 分析
    * CPU使用率较低，系统负载很低
    * JVM堆内存：Full GC 导致了长久的暂停；未配置GC算法，使用了默认的 Parallel GC
    * 换成 G1 GC 后，暂停时间峰值更高了
    * 分析GC日志，2个可疑点：物理内存超高（k8s的资源隔离没做好，其实都是物理机的内存），并行GC线程数超高（k8s的资源隔离没做好，72核对应了48个线程在4个core上资源竞争，上下文切换频繁）



# 第四课
## 5. Java Socket 编程：19'23''
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


## 6. 深入讨论IO：11'08''
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


## 7. I/O模型与相关概念：33'12''
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


## 8. Netty 框架简介以及 Netty 使用示例：32'33''
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



