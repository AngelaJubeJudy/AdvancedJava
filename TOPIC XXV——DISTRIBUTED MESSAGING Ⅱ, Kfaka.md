# TOPIC XXV: DISTRIBUTED MESSAGING Ⅱ, Kfaka

## 1. Kfaka 的入门和简单使用：48'7''
### 概念和入门
* Kafka：一种分布式的，基于发布/订阅的消息系统。
* 设计目标
    * `常数时间复杂度`提供消息`持久化`的能力；TB 级的数据也能保证常数时间复杂度的`访问性能`（不会像一代 MQ 那样由于消息的堆积导致性能的劣化）。
    * 高吞吐率（支持任何机器）。
    * 支持 Kafka server 间的消息分区（Partition）及分布式消费，同时每个分区内的消息`顺序`传输，顺序投递处理。
    * 同时支持离线数据处理和实时数据处理（消息的缓冲器，支持离线模式和在线模式）。
    * Scale out：支持在线`水平扩展`（基于分区和多副本机制）。
    
* 6个基本概念（与通用 MQ 类似）
    * Broker：Kafka 集群中的服务器（一个或多个，消息的代理中介）。
    * Topic：消息类别。Kafka 集群中 Topic 可以是集群分布式结构，包含多个 Partitions；逻辑分类。
    * `Partition`：物理分区。
    * Producer：发布消息到 Broker。
    * Consumer：从 Broker 读取消息。
    * `Consumer Group`：每一个 Consumer 都属于一个特定的消费者组。可以按 Consumer Group 为单位从 Kafka 拿到队列里所有信息，分工处理。 

* 部署结构
    * 单机部署：Producers --> Kafka Cluster (1 server), Topic --> Consumers. 
        * 类似点对点模式：消息被投递给消费者组内的一个消费者处理。
    * 集群部署：Producers --> Kafka Cluster (n servers), Topics --> Consumers.
        * `ZooKeeper`: does COORDINATION for Kafka Cluster. 管理 Kafka broker 集群的元数据和订阅关系。
        * 最新版本中已无 ZooKeeper，Kafka 自行管理集群的元数据和订阅关系。

* `Kafka Topic Partition Layout`：针对较大数据容量的场景
    * Topic and Partition
        * 多个 Partition 支持水平扩展和并行处理（并行读，并行写）
        * MQ 本身的顺序读写能力提升整体的吞吐性能
    * Partition and Replica
        * 多机集群场景下(n brokers)：每个 Partition 通过副本因子添加多个副本。
        * 主分片在不同机器上可以并行处理，从副本分片在主分片节点宕机时可以主从切换，保证了集群的高可用和容灾能力。
    * Topic 特性
        * 通过 `Partition` 增加了可扩展性&并行处理能力
        * 通过`顺序`写入达到高吞吐
        * `多副本机制`增加容错性（“3+2”，三个副本、两次确认，最多允许一个节点宕机，每次主副本和两个从副本都写成功确认了才告诉 Producer 写成功了；“5+3”，五个副本、三次确认，最多允许两个节点宕机；“7+4”，七个副本、四次确认，最多允许三个节点宕机；注意，`强确认的数目大于总副本数的50%，允许丢失的最多副本数为确认数减一`）
            * 注意，`允许丢失的最多副本数为确认数减一`：防止数据丢失。
            * 注意，`强确认的数目大于总副本数的50%`：防止集群内脑裂。

### 简单使用
* 单机安装部署
    * 网址：http://kafka.apache.org/downloads
    * 启动：命令行下进入 kafka 目录，修改配置文件 config/server.properties
        * 打开 listeners=PLAINTEXT://localhost:9092 的行
        * 启动 ZooKeeper 服务器：bin\zookeeper-server-start.sh config\zookeeper.properties
            * 后台进程方式启动：nohup bin/zookeeper-server-start.sh config/zookeeper.properties & 
        * 启动 Kafka：bin\kafka-server-start.sh config\server.properties

* 单机部署测试
    * 命令行操作
        * 查看 Topic 队列：bin/kafka-topics.sh --zookeeper localhost:2181 --list
        * 创建 Topic 队列（3个分片，副本因子等于1，即每个分片一个副本）：bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic testk --partitions 3 --replicationfactor 1
        * 查看 testk 分区状态，副本分布：bin/kafka-topics.sh --zookeeper localhost:2181 --describe --topic testk
        * 创建消费者（订阅 testk，指定从头开始消费）：bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --from-beginning --topic testk
        * 创建生产者：bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic testk
    * 简单性能测试
        * 生产者性能测试（限流2000条消息/秒）：bin/kafka-producer-perf-test.sh --topic testk --num-records 100000 --record-size 1000 --throughput 2000 --producer-props bootstrap.servers=localhost:9092 
        * 消费者性能测试（单线程消费消息）：bin/kafka-consumer-perf-test.sh --bootstrap-server localhost:9092 --topic testk --fetch-size 1048576 --messages 100000 --threads 1

* JAVA 中使用 Kafka 收发消息
    * 基于 Kafka Client 的生产者、消费者
        * Producer 接口：send(), close()
        * ProducerImpl 实现类：
        ```java
        // 类属性
        private Properties properties;
        private KafkaProducer<String, String> producer;

        // in public ProducerImpl() 构造器：
        properties = new Properties();
        properties.put("bootstrap.servers", "localhost:9092");  // 参数一：Kafka server IP and port
        properties.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");  // 参数二：key 的序列化器
        properties.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");  // 参数三：value 的序列化器
        producer = new KafkaProducer<String, String>(properties);

        // in public void send(Order order) 方法：将 Order 对象封装到 ProducerRecord 类中
        try {
            // producer.beginTransaction();
            // JSON.toJSONString(order)：将 order 对象序列化成字符串 
            ProducerRecord record = new ProducerRecord(topic, order.getId().toString(), JSON.toJSONString(order));
            producer.send(record, (metadata, exception) -> {
                if (exception != null) {
                    producer.abortTransaction();
                    throw new KafkaException(exception.getMessage() + " , data: " + record);
                    }
            });
            // producer.commitTransaction();

        } catch (Throwable e) {
            // producer.abortTransaction();
        }
        ```
        * ConsumerImpl 实现类：
        ```java
        // in public ConsumerImpl() 构造器：
        properties = new Properties();
        properties.put("group.id", "java1-kimmking");  // 参数一：消费者组
        properties.put("bootstrap.servers", "localhost:9092");  // 参数二：Kafka server IP and port
        properties.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");  // 参数三：key 的序列化器
        properties.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");  // 参数四：value 的序列化器
        consumer = new KafkaConsumer(properties);

        // in public void consumeOrder() 方法：
        // 订阅 topic
        consumer.subscribe(Collections.singletonList(topic));
        // 拉取数据
        try {
            while (true) { 
                ConsumerRecords<String, String> poll = consumer.poll(Duration.ofSeconds(1));
                // 消息的批处理：poll 不是单个消息
                for (ConsumerRecord o : poll) {
                    ConsumerRecord<String, String> record = (ConsumerRecord) o;
                    Order order = JSON.parseObject(record.value(), Order.class);  // 将单个消息反序列化成对象
                    System.out.println(" order = " + order);
                }
            }
        } catch (CommitFailedException e) {
            e.printStackTrace();
        } finally {
            try {
                consumer.commitSync();  // 同步当前消费者消费的位置
            } catch (Exception e) {
                consumer.close();
            }
        }
        ```
    * 流程总结
        * 生产者：配置 producer properties，创建 KafkaProducer，构造 ProducerRecord
        * 消费者：配置 consumer properties，创建 KafkaConsumer，订阅 topic，拉取 ConsumerRecords，业务处理 


## 2. Kfaka 的集群配置：20'16''
### 集群安装部署
#### 创建集群
* 部署3个节点的集群
    * 创建日志文件夹
    * 修改各节点配置文件：kafka9001.properties, kafka9002.properties, kafka9003.properties
        ```properties
        # The id of the broker. This must be set to a unique integer for each broker.
        broker.id=1
        # A comma separated list of directories under which to store log files
        log.dirs=E:\\kafka_2.12-2.8.1\\config\\kafka-logs
        # The address the socket server listens on. It will get the value returned from java.net.InetAddress.getCanonicalHostName() if not configured.
        # FORMAT: listeners = listener_name://host_name:port
        # EXAMPLE: listeners = PLAINTEXT://your.host.name:9092
        listeners=PLAINTEXT://localhost:9092
        # Broker List
        broker.list=localhost:9001,localhost:9002,localhost:9003
        ```
* 清理 ZooKeeper 上的数据
    * ZooInspector 工具：下载，解压，进入 build 目录，执行“java -jar ZooInspector.jar”；连接到本机的 ZooKeeper，删除除了“zookeeper”之外的其他所有节点。重启 ZooKeeper，得到一个干净的注册中心。
* 3个窗口启动3个 Kafka server
    ```bash
    ./bin/kafka-server-start.sh kafka9001.properties
    ./bin/kafka-server-start.sh kafka9002.properties
    ./bin/kafka-server-start.sh kafka9003.properties
    ```
    * 查看 ZooInspector：发现已有集群及各节点信息。

#### 操作
* 创建 Topic
    ```bash
    <!-- 3个分区，副本因子为2 -->
    bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic test32 --partitions 3 --replication-factor 2
    <!-- 查看主从副本及分区状态 -->
    bin/kafka-topics.sh localhost:2181 --describe --topic test32

    <!-- 生产者：连接9003 -->
    bin/kafka-console-producer.sh --bootstrap-server localhost:9003 --topic test32
    <!-- 消费者：连接9001 -->
    bin/kafka-console-consumer.sh --bootstrap-server localhost:9001 --topic test32 --frombeginning
    ```
* 性能测试
    ```bash
    <!-- 生产者 -->
    bin/kafka-producer-perf-test.sh --topic test32 --num-records 100000 --record-size 1000 --throughput 2000 --producer-props bootstrap.servers=localhost:9002
    <!-- 消费者 -->
    bin/kafka-consumer-perf-test.sh --bootstrap-server localhost:9002 --topic test32 --fetch-size 1048576 --messages 100000 --threads 1
    ```

### 集群与多副本的说明：在生产环境下的性能和稳定性
* `ISR: In-Sync Replica` 指标
    * 含义：目前处于`同步状态`的副本（即数据`与主副本一致`的副本）
    * 用参数 --describe 查看 topic 状态时有 ISR
    * 问题：当前副本掉出 ISR 集合，可能是多副本机制的主从复制出现了问题，延迟较大，甚至导致 broker 端的 rebalance，数据量大时产生性能抖动。
* Rebalance: Broker 的 Rebalance，Consumer Group 的 Rebalance
* 热点分区：需要重新平衡
    * 分区策略有问题：热点分区成为性能瓶颈，致使水平扩展的优势不复存在
    * Kafka 默认按 key 分区


## 3. Kfaka 的高级特性：35'57''
### 生产者
* 1. 执行步骤
    * 先在`客户端`实现消息的序列化、分区、元数据管理、压缩等操作，再将消息发送给 Kafka Server 做进一步处理。
    * 相比于一代的 MQ，二代的 MQ (Kafka, RocketMQ) 的服务端 broker 相对轻量级，只负责消息的存储和简单的分发。
        * 优势：broker 上需要维护的状态少，有利于大规模的 broker 集群，单位时间内支持更多的客户端连接；broker 更关注处理消息本身。
* 2. 确认模式 ACK
    * 选择一：ack=0，只发送消息，不保证是否写入 broker（相当于没有 ACK）。
    * 选择二：ack=1，写入当前 broker 集群中的 leader 主分区即认为成功。
    * （默认）选择三：ack=-1 或 all，写入到最小的副本数（每个写入都要确认；`性能`较选择一、选择二较低）即认为成功。保证了分布式场景下的高可用和数据`一致性`。
    * 调节 ACK：用于平衡性能和一致性。
* 3. 同步发送
    * 生产者发送消息：
        ```java
        KafkaProducer kafkaProducer = new KafkaProducer(pro);
        ProducerRecord record = new ProducerRecord("topic", "key", "value");
        Future future = kafkaProducer.send(record);  // 默认异步发送，自动返回 Future
        ```
        * solution 1: 异步转同步，在当前线程中同步等待 Send 有返回结果
        ```java
        Onject o = future.get();
        ```
    * solution 2: 强制将消息刷入 broker，刷入磁盘后返回
        ```java
        kafkaProducer.flush();
        ```
* 4. 异步发送
    * 生产者发送消息：
        ```java
        // 配置：当超过下列两个参数的设置值其中之一时，消息被发送
        pro.put("linger.ms", "1");  // 毫秒数；默认-1，即不等待，直接发送，延迟最小；增大单次消息发送延迟的好处————增大集群整体吞吐
        pro.put("batch.size", "10240");  // 字节数
        KafkaProducer kafkaProducer = new KafkaProducer(pro);
        ProducerRecord record = new ProducerRecord("topic", "key", "value");
        Future future = kafkaProducer.send(record);  // 默认异步发送，自动返回 Future
        ```
    * solution 1: 重载 send()，写一个回调函数
        ```java
        kafkaProducer.send(record, (metadata, exception)->{
            if (exception == null) System.out.println("record=" + record);
        });
        ```
    * solution 2: 直接 Send 
        ```java
        kafkaProducer.send(record);
        ```
* 5. 生产的消息的顺序保证：参数设置 + 同步发送
    * 参数“max.in.flight.requests.per.connection”，每个连接中最大处理中状态的请求数量，配置如下：
        ```java
        pro.put("max.in.flight.requests.per.connection", "1");
        ```
        * 消息没有被 broker 处理完，不会再有新的消息写入 Kafka
        * 优势：防止网络抖动等导致的乱序
        * 劣势：整体性能降低
    * 同步发送每条消息
* 6. 消息可靠性传递：消息的事务性
    * Kafka：存储数据；数据只读，追加式插入。生产者相当于 DML，操作（增删改）数据、改变 MQ 的状态；消费者相当于 DQL 查询数据，消费过程中没有任何状态的变化。
    * 数据库：存储数据；随机读写。
    * 设置
        ```java
        pro.put("enable.idempotence", "true");  // 打开幂等后，默认将 ACK 设置为 -1
        pro.put("transaction.id", "tx0001");  // 添加事务 ID
        // in public void send(Order order) 方法
        try {
            producer.beginTransaction();
            ProducerRecord record = new ProducerRecord(topic, order.getId().toString(), JSON.toJSONString(order));
            producer.send(record, (metadata, exception) -> {
                if (exception != null) {
                    producer.abortTransaction();
                    throw new KafkaException(exception.getMessage() + " , data: " + record);
                    }
            });
            producer.commitTransaction();  // 一切正常，提交事务

        } catch (Throwable e) {
            producer.abortTransaction();  // 发送异常，取消事务。Kafka send 的消息默认都会存入日志，被回滚的消息则会被标记；消费者会根据标记过滤此类消息，不做处理
        }
        ```

### 消费者
* 1. Consumer Group
    * 一个消费者组可以有一个或多个消费者
    * 消息分发给消费者组里的`某个`消费者，而非全部；所有消费者`共享`一个 offset
    * offset：commit 的偏移量，当前消费进度；需要记录！
    * 数量关系  
        * kn Partitions, n Consumers and k ≥ 1: k Parition/Consumer，均匀。
        * m Partitions, n Consumers and m < n: 出现闲置消费者；通过配置避免同一个消费者组中出现 m < n 的情况。
        * m Partitions, n Consumers and m > n: 尽量使分区均匀被消费。
* 2. Offset 同步提交：更安全
    * 配置
        ```java
        pro.put("enable.auto.commit", "false");  // 关闭；默认自动提交
        while (true) {
            ConsumerRecords poll = consumer.poll(Duration.ofMillis(100));
            poll.forEach(o -> {
                ConsumerRecord<String, String> record = (ConsumerRecord) o;
                Order order = JSON.parseObject(record.value(), Order.class);
                System.out.println("order = " + order);
            });
            consumer.commitSync();  // 显示调用，同步提交 Offset
        }
        ```
* 3. Offset 异步提交：更快
    * 配置
        ```java
        pro.put("enable.auto.commit", "false");  // 关闭；默认自动提交
        while (true) {
            ConsumerRecords poll = consumer.poll(Duration.ofMillis(100));
            poll.forEach(o -> {
                ConsumerRecord<String, String> record = (ConsumerRecord) o;
                Order order = JSON.parseObject(record.value(), Order.class);
                System.out.println("order = " + order);
            });
            consumer.commitAsync();  // 显示调用，异步提交 Offset
        }
        ```
* 4. Offset 自动提交
    * 配置
        ```java
        pro.put("enable.auto.commit", "true");  // 默认自动提交
        pro.put("auto.commit.interval.ms", "5000");  // 自动提交的时间窗口
        ```
* 5. Offset Seek
    * rebalance 后保证 kafka 不重新消费
    * 配置
        ```java
        pro.put("enable.auto.commit", "true");  // 默认自动提交
        // ConsumerRebalanceListener：设置 rebalance 监听器
        consumer.subscribe(Arrays.asList("demo-source"), new ConsumerRebalanceListener() {
            @Override
            public void onPartitionsRevoked(Collection<TopicPartition> partitions) {  // rebalance 之前，消费者停止消费之后：记录当前的 offset
                commitOffsetToDB();
            }
            @Override
            public void onPartitionsAssigned(Collection<TopicPartition> partitions) {  // rebalance 之后，消费者读取消息之前：重置所有的 offset（从数据库里获取），消费者 seek 跳转到记录的偏移量后再开始消费
                partitions.forEach(topicPartition -> consumer.seek(topicPartition,
                getOffsetFromDB(topicPartition)));
            }
        });

        // 业务处理环节：record 中包含 offset，通过调用方法拿到当前偏移量
        while (true) {
            ConsumerRecords poll = consumer.poll(Duration.ofMillis(100));
            poll.forEach(o -> {
                ConsumerRecord<String, String> record = (ConsumerRecord) o;
                processRecord(record);
                // 每消费一条消息，可以将偏移量记录在数据库中，防止系统崩溃后消费进度丢失
                saveRecordAndOffsetInDB(record, record.offset());
            });
        }
        ```
