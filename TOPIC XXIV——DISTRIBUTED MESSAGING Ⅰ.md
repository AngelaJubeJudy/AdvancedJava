# TOPIC XXIV: DISTRIBUTED MESSAGING Ⅰ, ActiveMQ

## 1. 从队列到消息服务/消息模式与消息协议：62'3''

### 系统间的通信方式
* 基于文件
    * 同一机器上
    * 不同机器上：跨网络的文件，网络共享
    * 缺点：不方便，不及时
* 基于共享内存
* 基于 IPC
    * 管道
* 基于 Socket
    * Socket 通信
    * 缺点：使用麻烦，需要定义数据格式
* 基于数据库
    * 缺点：不及时（不实时），压力大时对系统有影响
* 基于 RPC
    * 缺点：集群各调用节点间的复杂度（n*(n-1)/2 = O(n^2)），所有压力都是实时的（无缓冲），所有处理都是同步的（请求丢失后无后续）

* 其他
    * MQ: Message Queue / Messaging System / Message Middleware

* 对系统间通信方式的期望
    * 实现`异步`消息通信
    * `简化`各方的复杂依赖关系（从 O(n^2) 降低为线性复杂度）
    * 请求量很大时`缓冲`（类比电容，类比线程池里的 Queue 的缓冲）
    * 某些情况下保障消息的可靠性，甚至接收顺序
    * solution: MQ

* MQ: Message Queue / Messaging System / Message Middleware / Message Broker
    * 节点间通信：`异步`调用（通信双方不直接联系，n个系统与 MQ 间 n 条联系，系统不必一直在线）
        * 收发类比收发快递，MQ 类比快递公司
    * MQ 做缓冲，实现平滑的业务处理

### 从队列到消息服务
* 数据结构：内存里的 Queue（FIFO）
    * （尾）写数据：数据的生产者
    * （头）读数据：数据的消费者
    * Queue 中存储数据
* Message Queue / Messaging System
    * 结构类比内存里的 Queue，走出当前进程，实现一个消息服务中间件
        * 消息队列（独立的、远程部署的 erver），消费者，生产者
        * Queue 中存储消息（消息：具有业务意义、能够被传递的可流动的数据）
    * 系统角色：消费者，生产者
    * 一个 MQ 中有多个消息队列
        * 一个系统既可以是某些队列的生产者，也可以是其他队列的消费者

* MQ 四大作用/特性  
     * `异步`通信
        * 减少线程等待
        * 批量操作（大事务、大耗时）时很有用
     * 系统`解耦`
        * 降低系统间依赖
        * 系统不在线时也能保证通信最终完成
     * `削峰平谷`
        * 缓冲请求消息（类似背压处理，根据输入频率调节处理频率）
     * `可靠`通信
        * 提供不同的消息模式
        * 消息的有序性

### 消息模式与消息协议
* 消息处理模式
    * 点对点（PTP, Point-To-Point）：Queue
        * 1 Sender --> 1 Queue --> 1 Receiver
        * 一对一通信
    * 发布订阅（PubSub, Publish-Subscribe）：Topic
        * 1 Publisher --> 1 Topic --> n Subscribers
        * 一对多通信

* 消息处理的可靠性保障    
    * 消息语义的三个 QoS
        * At most once：消息可能丢失，但不会重复发送（对一致性要求不高）
        * At least once：消息不会丢，但可能重复
        * Exactly once：每条消息肯定被传输一次且仅一次（发送一次并返回）
    * 消息处理的事务性
        * 通过`确认机制`实现
        * 上述机制可以封装后纳入事务管理器，异步的 MQ 甚至可以支持 VA

* 消息有序性
    * 同一个 Topic / Queue 的消息，保障按顺序投递
        * 单线程 + 单个 Queue / 单分区：保障消息的顺序
    * MQ 的容量变大后，需要分布式的处理（分区等），跨分区的处理不再有序（单个分区内仍然有序）；多个线程的并发批量处理也使消息不再有序

* 集成领域圣经：`《Enterprise Integration Patterns》企业集成模式`
    * SOA / ESB / MQ 等技术的理论基础

* 消息协议
    * 6个常见协议：STOMP（简单文本对象消息协议，文本数据的交互）, JMS（J2EE标准的一部分，偏向于客户端接口）, AMQP（高级消息队列协议；综合，规定了 API 接口以及与 MQ 通信的数据格式）, MQTT（消息队列遥感传输；交互的数据报文精简）, XMPP（早期的，基于 XML 的消息协议）, Open Messaging 
        * AMQP 和 MQTT：完备的、多层级的消息协议，协议驱动包具有可重用性（可以访问支持协议的任何 MQ，可复用、可兼容）
        * AMQP 的官方参考实现：Apache Qpid
    * JMS (Java Message Service)
        * 应用层的 API 协议（类似 JDBC）：制定了一整套接口和类
            * ConnectionFactory --> Connection（物理连接） --> Session（逻辑连接） --> Message & MessageProducer & MessageConsumer
            * JMS 中将 Queue 和 Topic 统一：通过 `Destination 接口`抽象，实现 Queue 和 Topic 
        * Message 结构
            * 消息体 Body，消息内容
            * Header：存放系统自定义的内置的各种 k-v
            * Property：存放业务系统定义的各种 k-v
            * Queue / Topic / TemporaryQueue / TemporaryTopic
                * 临时队列：实现`请求响应模式`，封装在 Requester 对象中
            * Connection / Session / Producer / Consumer / DurableSubscription（使 Topic 中的消息持久化；当一个 Publisher 存在至少一个 DurableSubscription 时，所有消息都会被持久化）
        * Messaging 行为
            * 支持 PTP & PubSub
            * 消息的持久化
                * JMS 中默认 Queue 所有消息是持久化的，而 Topic 所有消息旨在内存中不持久化（重启后消息丢失）
            * 事务机制
            * 确认机制
                * 由于消息的有序性，调用一个消息的确认和调用消息所在会话的确认是`等价`的（例，调用第5个消息的确认时，由于消息5所在 session 中共有12345五条消息被处理，则消息12345全部被确认，相当于调用了当前session 的确认）
            * 临时队列

* 消息队列通用结构
    * 交换器（Exchange）：负责消息的持久化以及消息的到具体 Queue 的分发
    * 分发器（Dispatch）：如果消息有订阅者，将消息投递到订阅者
    * 消息协议
        * 内部4层：客户端应用层（收发消息；`JMS 所在层`），消息模型层（消息、连接、会话、事务等的实现层；需要 JMS 的驱动包实现），消息处理层（定义消息交互的逻辑和持久化；AMQP 和 MQTT 中有所定义，JMS 中未涉及），网络传输层（序列化协议、传输协议、可靠机制；AMQP 和 MQTT 中有所定义，JMS 中未涉及）
        * 外部2层（可有可无）：安全层，管理层

* 开源消息中间件 / 消息队列
    * 一代：ActiveMQ / RabbitMQ（支持 AMQP 协议）
        * 特点：功能丰富，实现了经典的企业集成模式，对内存的使用有较高要求
    * 二代：Kafka / RocketMQ
        * 针对一代不支持大数据量堆积做了改造
        * 特点：使用磁盘做 WAL，叠加顺序写日志的堆积方式；只要磁盘允许，就可以不断堆积消息，且不会影响 MQ 的性能。
    * 三代：Apache Pulsar
        * 在二代基础上实现了 MQ 本身节点和存储节点的分离，支持更大规模的集群


## 2. ActiveMQ 消息中间件以及使用示例：22'37''

### ActiveMQ 消息中间件
* 特点：高可靠、事务性的消息队列
    * 功能齐全，当前应用最广的开源消息中间件
    * Apache ActiveMQ Apollo 子项目：Scala 编写，下一代 ActiveMQ
    * Apache ActiveMQ Artemis 子项目：代替 Apollo，作为下一代 ActiveMQ 孵化

* 主要功能
    * 多语言、多协议编写客户端
        * 语言：常见语言
        * 协议：OpenWire（语言无关的二进制协议）, Stomp REST, WS Notification, XMPP, AMQP, MQTT
    * 完全支持 JMS 1.1 和 J2EE 1.4 规范（持久化，XA消息，事务）
    * 与 Spring 很好地集成，支持常见 J2EE 服务器
    * 支持多种传输协议
    * 支持通过 JDBC（持久化到指定的数据库中） 和 Journal 提供高速的消息持久化；支持自带日志的持久化
    * 实现了高性能的集群模式

### ActiveMQ 使用示例
* 使用场景
    * 所有需要使用消息队列的地方（消息不大量堆积）
    * 订单处理、消息通知、服务降级等异步的业务处理场景
    * ActiveMQ 是纯 JAVA 实现的，支持嵌入到应用系统，作为一个嵌入式的 MQ 使用
* 补充材料：[JMS 介绍：我对 JMS 的理解和认识](https://kimmking.blog.csdn.net/article/details/6577021)
* 实战
    * [下载 server](https://activemq.apache.org/components/classic/download/)，解压
    * 启动（Windows 系统）：双击 bin\win64 目录下的 activemq 批处理文件
    * 启动（Linux 系统）
    ```bash
    bin/activemq start
    tail -f data/*.log
    ```
    * 查看状态
    ```bash
    bin/activemq status
    ```
    * 登录自带的控制台：http://localhost:8161/admin/，使用 admin / admin 默认账号登录
        * Queue：默认为空
        * Topic：系统自带两个：ActiveMQ.Advisory.MasterBroker, ActiveMQ.Advisory.Queue
        * 自定义 Topic "test.topic"：多出两个，ActiveMQ.Advisory.Topic 和 "test.topic"
        * Send：发送消息到某个 Queue / Topic
    
    * 通过 JMS 使用 ActiveMQ
        * 项目：activemq-demo
        * 在 pom 中注入依赖：activemq-all；版本与 server 对应 
        * 代码
        ```java
        /*
        * 方法：public static void main(String[] args)
        */
        // 定义 Destination
        Destination destination = new ActiveMQTopic("test.topic");

        /*
        * 方法：public static void testDestination(Destination destination)
        */

        // 创建连接
        // 默认端口 61616 的配置：详见 apache-activemq-5.16.3-bin\apache-activemq-5.16.3\conf\activemq.xml 文件中“<transportConnectors>”
        ActiveMQConnectionFactory factory = new ActiveMQConnectionFactory("tcp://127.0.0.1:61616");
        ActiveMQConnection conn = (ActiveMQConnection) factory.createConnection();
        // 启动连接，连接到 MQ 
        conn.start();
        // 创建会话：关闭事务，会话自动确认
        Session session = conn.createSession(false, Session.AUTO_ACKNOWLEDGE);

        // 创建消费者
        MessageConsumer consumer = session.createConsumer(destination);
        final AtomicInteger count = new AtomicInteger(0);
        // 创建监听器：onMessage() 方法用于消费者处理消息
        MessageListener listener = new MessageListener() {
            public void onMessage(Message message) {
                try {
                    // Thread.sleep();
                    System.out.println(count.incrementAndGet() + " => receive from " + destination.toString() + ": " + message);
                    // message.acknowledge(); // 前面所有未被确认的消息全被确认

                } catch (Exception e) {
                    e.printStackTrace(); // 不要吞任何这里的异常
                }
            }
        };
        // 绑定消息监听器
        consumer.setMessageListener(listener);

        // 创建生产者：发送消息到 MQ
        MessageProducer producer = session.createProducer(destination);
        int index = 0;
        while (index++ < 100) {
            TextMessage message = session.createTextMessage(index + " message.");
            producer.send(message);
        }

        Thread.sleep(20000);
        session.close();
        conn.close();
        ```



