# TOPIC XXVI: DISTRIBUTED MESSAGING Ⅲ, Other MQs

## 1. RabbitMQ / RocketMQ：56'32''
### RabbitMQ
* 安装  
    * 基于 Erlang，需要预先安装
    * 直接安装
        * MAC: brew install rabbitmq
        * Linux:  apt/yum install rabbitmq-server
        * windows: choco install rabbitmq
            * 在命令行打开 RabbitMQ 自带的管理控制台界面 BS：
            ```bash
            rabbitmq-plugins enable rabbitmq_management
            ```
    * docker 安装: docker pull rabbitmq:management（`:management` 后缀表示拉取镜像时还需要 RabbitMQ 自带的管理控制台）
        * 控制台端口15672，MQ 端口5672： docker run -itd --name rabbitmq-test -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS=admin -p 15672:15672 -p 5672:5672 rabbitmq:management
        * 进入容器 Shell：docker exec -it rabbitmq-test /bin/bash；查看状态 & 操作 MQ，
            > rabbitmqctl status
            > rabbitmqctl list_queues
            > rabbitmqadmin declare queue name=kk01 -u admin -p admin
            > rabbitmqadmin get queue=kk01 -u admin -p admin

* 核心概念
    * Publisher, Consumer
    * 核心部分
        * queue：消费者从中读取消息。
        * exchange（实际对象）：消息交换器，将消息发送到 queue 中。
        * routekey：exchange 和 queue 绑定的依据。
        * binding（实际对象）：（引入消息交换器的好处）通过修改绑定关系即可修改应用程序通信双方的通信流程，无需生产者和消费者做出改变。 

* spring-amqp 操作 RabbitMQ
    * Spring 和 RabbitMQ 同属一家公司。
    * RabbitMQ 管理控制台
        * http://localhost:15672/
        * 查看 Exchange：
            * 类型=direct，直接发送消息到对应的 Queue；durable=true，持久化的。
            * Bindings：绑定了多个 Queue，每个 Queue 使用各自的 Routing Key；支持解绑和手动绑定。
        * 查看 Queue
            * Publish Message
            * Get Messages
    * spring-amqp 封装的 AmqpTemplate
    * 注入依赖
        ```xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-amqp</artifactId>
        </dependency>
        ``` 
    * 配置 RabbitMQ 的信息
        * application.yml: host, username, password, port 
        * RabbitConfig,java: EXCHANGE, QUEUE, ROUTINGKEY,connectionFactory, rabbitTemplate 工具类, binding 
            * EXCHANGE_A, EXCHANGE_B, EXCHANGE_C; QUEUE_A, QUEUE_B, QUEUE_C; ROUTINGKEY_A, ROUTINGKEY_B, ROUTINGKEY_C
    * 消息的生产者
        ```java
        // sendMessage(String content) 方法：将消息 content 发送到 ROUTINGKEY_B 对应的队列中（可能有多个），并设置回调 ID correlationId
        rabbitTemplate.convertAndSend(RabbitConfig.EXCHANGE_A, RabbitConfig.ROUTINGKEY_B, content, correlationId);
        ```
    * 消息的消费者 A
        ```java
        @RabbitListener(queues = RabbitConfig.QUEUE_A)
        ```
    * 消息的消费者 B
        ```java
        @RabbitListener(queues = RabbitConfig.QUEUE_B)
        ```

### RocketMQ
* 安装
    * 基于 JAVA
    * 压缩包：rocketmq-all-4.9.1-bin-release.zip，解压即可
    * 启动
        * 启动前需要查看环境变量：echo $JAVA_HOME；没有则需要设置
        * 直接启动：bin/mqnamesrv
        * nohup 启动：nohup sh bin/mqnamesrv
    * 官方自带的工具演示生产者和消费者
        * 创建环境变量指定 name server 的地址：
        ```bash
        > export NAMESRV_ADDR=localhost:9876
        ```
        * 创建消费者
        ```bash
        > sh bin/tools.sh org.apache.rocketmq.example.quickstart.Consumer
        ```
        * 创建生产者
        ```bash
        > sh bin/tools.sh org.apache.rocketmq.example.quickstart.Producer
        ```

* 结构
    * 与 Kafka 和 RabbitMQ 有所不同
    * NameServer Cluster
        * 类比之前的 Kafka 版本中依赖的 Zookeeper 集群
    * Broker Cluster
        * 将 Meta Info 和 Routing Info 发送给 Name Servers
    * Producer Cluster
        * 通过 Name Servers 获取元数据信息和路由信息
    * Consumer Cluster
        * 通过 Name Servers 获取元数据信息和路由信息

* RocketMQ vs Kafka
    * Kafka 的重现版（从 Scala 到 Java），本质区别不大
    * 差异一：RocketMQ 基于 Java 开发，Kafka 基于 Scala 开发。
    * 差异二：延迟投递（早期 ActiveMQ 中的 ScheduledDelivery；一般要求在 MQ 外部做调度）、消息追溯等支持。
    * 差异三：RocketMQ 多个队列使用一个日志（一个 Broker 上可以创建多个队列，队列是逻辑概念，如此不会降低性能） vs 每个队列使用自己的日志（队列和日志间的切换开销较小）

* demo
    * 注入依赖
        ```xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-amqp</artifactId>
        </dependency>
        ``` 
    * 配置 RocketMQ 的信息
        * application.properties: rocketmq.name-server=localhost:9876, rocketmq.producer.group=my-group1, rocketmq.producer.sendMessageTimeout=300000
    * 程序入口
        * 定义 rocketMQTemplate 工具类
        * run()
            * 定义 topic（字符串类型）
            * 发送消息，
                ```java
                // 简单消息；同步发送消息
                SendResult sendResult = rocketMQTemplate.syncSend(topic, "消息内容");
                // 自定义消息，消息序列化为 JSON 格式；同步发送消息
                sendResult = rocketMQTemplate.syncSend(topic, MessageBuilder.withPayload(
                new Order(System.currentTimeMillis(),"CNY2USD", 0.1501d)).setHeader(MessageHeaders.CONTENT_TYPE, MimeTypeUtils.APPLICATION_JSON_VALUE).build());

                // 异步发送消息，添加回调处理 
                sendResult = rocketMQTemplate.asyncSend(topic1, new Order(System.currentTimeMillis(),"CNY2USD", 0.1502d), new SendCallback() {
                    @Override
                    public void onSuccess(SendResult result) {
                        System.out.printf("async onSucess SendResult=%s %n", result);
                    }

                    @Override
                    public void onException(Throwable throwable) {
                        System.out.printf("async onException Throwable=%s %n", throwable);
                    }
                });
                // 支持有返回结果的消息发送，返回类型为 String
                String result = rocketMQTemplate.sendAndReceive(topic1, new Order(System.currentTimeMillis(),"CNY2USD", 0.1502d), String.class);

                // sendResult 有返回结果
                System.out.printf("syncSend1 to topic %s sendResult=%s %n", topic, sendResult);
                ```
            * 接受消息
                * 消费字符串消息，
                ```java
                @RocketMQMessageListener(consumerGroup = "test1", topic = "test-k1")
                // 监听器泛型的类型需要与 msg 的类型保持一致
                public class StringConsumerDemo implements RocketMQListener<String> {
                    @Override
                    public void onMessage(String message) { 
                        // one way：无返回值，消费完即结束
                        System.out.println(this.getClass().getName() + " -> " + message);
                    }
                }
                ```
                * 消费对象消息，
                ```java
                @RocketMQMessageListener(consumerGroup = "test2", topic = "test-k2")
                // RocketMQReplyListener<处理类型，返回类型>
                public class OrderConsumerDemo implements RocketMQReplyListener<Order,String> {
                    @Override
                    public String onMessage(Order order) { 
                        // request-response：消费完返回信息给发送者
                        System.out.println(this.getClass().getName() + " -> " + order);
                        return "Process&Return [" + order + "].";
                    }
                }
                ```


## 2. Pulsar / EIP / Camel / Spring Integration：49'56''
### Pulsar
* 安装
    * 基于 Java；默认使用 Zookeeper 存储元数据 
    * 下载：[apache-pulsar-2.8.1-bin.tar](http://pulsar.apache.org/zh-CN/download/)，解压即可
    * 使用单机模式启动（有内置的 Zookeeper）：
        ```bash
        > bin/pulsar standalone
        ```
    * 创建订阅者：
        ```bash
        > bin/pulsar-client consume topic1 -s "first-subscription"
        ```
    * 创建生产者：
        ```bash
        > bin/pulsar-client produce topic1 --message "hello-pulsar"
        ```

* 原理及特性
    * 基于 topic
        * 与 Kafka 和 RocketMQ 一致
    * 支持 namespace 和多租户
        * 天生适合云环境
        * 可以使用 namespace 逻辑隔离同一 topic 下的数据
    * 4种消费模式
        * Exclusive 排他：相当于从 topic 退化成点对点模式，同一时间内只有一个消费者组内的消费者能获取消息。
        * Failover：同一时间内只有一个消费者组内的消费者能获取消息；出现异常则发送给另一个消费者。
        * Shared：所有消息随机共享给消费者组内的不同消费者。
        * Key Shared：按 key 路由共享。
    * 支持 Partition
    * `计算存储分离，高可用集群`
        * Broker 节点：Serving Nodes (brokers，支持扩展)
        * 存储节点：Storage Nodes (bookies，支持扩展)；存储底层使用 Apache BooKeeper（一个 WAL, Write Ahead Log，所有日志顺序写入）

* 实战
    * 注入依赖（官方暂无 starter）
        ```xml
        <dependency>
            <groupId>org.apache.pulsar</groupId>
            <artifactId>pulsar-client</artifactId>
        </dependency>
        ``` 
    * 配置 Pulsar Client    
        ```java
        @SneakyThrows
        public static PulsarClient createClient() {
            return PulsarClient.builder()
                    .serviceUrl("pulsar://localhost:6650")
                    .build();
        }
        ```
    * 消费者
        ```java
        // 含超时时间和订阅类型
        Consumer consumer = client.newConsumer()
                .topic("my-topic")
                .subscriptionName("my-subscription")
                .ackTimeout(10, TimeUnit.SECONDS)
                .subscriptionType(SubscriptionType.Exclusive)
                .subscribe();
        // 异步接收消息
        CompletableFuture<Message> asyncMessage = consumer.receiveAsync();
        // 批量接收消息
        Messages messages = consumer.batchReceive();
        //订阅一组 topic（可跨命名空间）
        List<String> topics = Arrays.asList(
                "topic-1",
                "topic-2",
                "topic-3"
        );
        Consumer multiTopicConsumer = consumerBuilder
                .topics(topics)
                .subscribe();
        ```
    * 生产者
        ```java
        // 定义生产 String 类型（支持多种）的消息：Schema.STRING
        stringProducer = Config.createClient().newProducer(Schema.STRING)
                .topic("my-kk")
                .create();
        // 控制发送行为
        Producer<byte[]> producer = client.newProducer()
            .topic("my-topic")
            .batchingMaxPublishDelay(10, TimeUnit.MILLISECONDS)
            .sendTimeout(10, TimeUnit.SECONDS)
            .blockIfQueueFull(true)
            .create();
        //异步发送消息
        producer.sendAsync("my-async-message".getBytes()).thenAccep(msgId -> {
            System.out.printf("Message with ID %s successfully sent", msgId);
        });
        // 额外指定一些消息参数
        producer.newMessage()
            .key("my-message-key")
            .value("my-async-message".getBytes())
            .property("my-key", "my-value")
            .property("my-other-key", "my-other-value")
            .send();
        ```

### EIP 框架，Camel / Spring Integration
* EIP 企业集成模式
    * SOA / ESB / MQ 的理论基础
* 集成领域的两大法宝
    * RPC
    * Messaging
* 常见的 EIP 开源框架
    * Camel 
        * 可以打通各种 MQ，还可以增加额外的路由处理
        * 灵活，减少大量的集成代码的编写
    * Spring Integration     
* EIP 种所有的处理都可以抽象为`“管道 + 过滤器”模式`
    * input：数据从一个输入源头出发
    * pipeline：数据在一个管道流动
    * nodes：中间经过一些处理节点，数据被过滤、增强、计算、转换、业务处理等
    * output: 数据输出到一个目的地
* 实战
    * 在 ActiveMQ 和 RabbitMQ 中间加一个 Camel，把 ActiveMQ 的消息自动转移到 RabbitMQ
    * 分别启动 ActiveMQ 和 RabbitMQ
    * 确认 ActiveMQ 文件目录下有 activemq-camel 和 camel-core 的 jar 包；之后下载 amqp-client（访问 RabbitMQ 的驱动包） 和 camel-rabbitmq（用 Camel 操作 RabbitMQ 的 ORM） 的 jar 包
    * 打开 /conf 下的配置文件 camel.xml，找到 <route> 部分，配置 <from> 和 <to> 的队列
    * 打开 /conf 下的配置文件 activemq.xml，引入配置。
        ```xml
        <import resource="camel.xml">
        ```
    * 重启 ActiveMQ
        ```bash
        bin/activemq stop
        bin/activemq start
        <!-- 查看是否启动成功 -->
        tail -f data/activemq.log
        ```
    * 在管理控制台查看上述配置的打通效果

### 动手写 MQ 
* `Version 1：内存的 MQ`
    * `要求：使用 Java 并发工具包中的 BlockingQueue 作为底层消息存储`
        ```java
        import java.util.concurrent.LinkedBlockingQueue;
        ```
    * 定义 topic：支持多个 Topic，每个 Topic 对应一个 BlockingQueue 作为其实际存储
    * 定义 Message
    * 定义 Producer：实现 send() 方法
    * 定义 Consumer：实现 subscribe() 和 poll() 方法
    * 特点：基于内存
    * demo: kmq-more 项目

* `Version 2：自定义 MQ`
    * `要求：不使用 BlockingQueue；实现消息确认和消费 offset`
    * 定义内存的 Message 数组模拟 Queue：数组长度固定，读和写的位置可以用两个指针（Offset）记录
    * 问题：仅通过指针来记录消费，消息仍存储在数组中，可能导致内存溢出
    * 特点：基于内存

* `Version 3：基于 Spring MVC 实现 MQServer`
    * `要求：拆分 Broker 和 Client`
    * 定义 Queue：采用数组实现
    * 用 SpringMVC 做一个 HTTP Server，将 Queue 放在 web server 端
    * 设计消息读、写接口，确认接口，提交 offset 接口
    * Producer 和 Consumer 通过 HTTPclient / Okhttp 访问 Queue
    * 可以实现基于 offset 消费者增量拉取消息
    * 特点：从单机走向服务器模式

* `Version 4：功能完善的 MQ`
    * 要求：增加策略
    * 增加消息过期、消息重试、消息定时投递等
    * 增加批量操作（消息打包读写）
    * 增加消息清理操作（避免内存爆炸）
    * 考虑消息的持久化（写入数据库/使用 WAL/ 使用 Pulsar 的组件 BooKeeper）
    * 将 SpringMVC 替换为基于 Netty 实现的 TCP 的传输 / rsocket / websocket：从 HTTP 到更底层的 TCP 传输，支持长连接，进一步优化了网络传输通信性能
    * 特点：功能较完备，内存不 OOM，消息持久化，基于 TCP 实现 server 端向 client 端 PUSH 的模式

* `Version 5：体系完善的 MQ`
    * 要求：对接各种技术
    * 封装 JMS 接口规范
    * 实现 STOMP（简单文本对象消息协议）消息规范
    * 实现消息事务机制，与现有的事务管理器集成
    * 对接 Spring，实现 Starter 方便使用
    * 对接 EIP 框架（Camel / Spring Integration）
    * 优化内存和磁盘使用
    * 特点：生产级可用的 MQ

