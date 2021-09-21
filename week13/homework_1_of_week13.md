# WEEK 13

## Obligatory

1. （`必做`）搭建一个 3 节点 Kafka 集群，测试功能和性能；实现 spring kafka 下对 kafka 集群的操作，提交代码。
-------------------------------------------------------------

### Part Ⅰ：集群安装部署
#### step 1: 创建集群
* 部署3个节点的集群
    * 创建日志文件夹
        * 例，E:\kafka_2.12-2.8.1\kafka-logs
    * 修改各节点配置文件：kafka9001.properties, kafka9002.properties, kafka9003.properties
        ```properties
        # The id of the broker. This must be set to a unique integer for each broker.
        broker.id=1
        # A comma separated list of directories under which to store log files
        log.dirs=E:\\kafka_2.12-2.8.1\\config\\kafka-logs
        # The address the socket server listens on. It will get the value returned from java.net.InetAddress.getCanonicalHostName() if not configured.
        # FORMAT: listeners = listener_name://host_name:port
        # EXAMPLE: listeners = PLAINTEXT://your.host.name:9092
        listeners=PLAINTEXT://localhost:9001
        # Broker List
        broker.list=localhost:9001,localhost:9002,localhost:9003
        ```
* 清理 ZooKeeper 上的数据
    * ZooInspector 工具：下载，解压，进入 build 目录，执行“java -jar ZooInspector.jar”；连接到本机的 ZooKeeper，删除除了“zookeeper”之外的其他所有节点。重启 ZooKeeper，得到一个空的注册中心。
* 打开3个窗口，启动3个 Kafka server，
    ```bash
    bin/kafka-server-start.sh kafka9001.properties
    bin/kafka-server-start.sh kafka9002.properties
    bin/kafka-server-start.sh kafka9003.properties
    ```
    * 查看 ZooInspector：发现已有集群及各节点信息。

#### step 2: 操作
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

#### step 3: 性能测试
```bash
<!-- 生产者（限流2000条消息/秒） -->
bin/kafka-producer-perf-test.sh --topic test32 --num-records 100000 --record-size 1000 --throughput 2000 --producer-props bootstrap.servers=localhost:9003
<!-- 消费者 -->
bin/kafka-consumer-perf-test.sh --bootstrap-server localhost:9001 --topic test32 --fetch-size 1048576 --messages 100000 --threads 1
```
-------------------------------------------------------------

### Part Ⅱ：JAVA 中使用 Kafka 收发消息
* 基于 Kafka Client 的生产者、消费者
    * 项目注入依赖，
        ```xml
        <dependency>
            <groupId>org.apache.kafka</groupId>
            <artifactId>kafka_2.12</artifactId>
            <version>2.6.0</version>
        </dependency>

        <dependency>
            <groupId>org.apache.kafka</groupId>
            <artifactId>kafka-clients</artifactId>
            <version>2.6.0</version>
        </dependency>
        ```
    * Producer 接口：包含方法 send() 和 close()
    * Producer 接口的实现类 ProducerImpl：
    ```java
    // 类属性
    private Properties properties;
    private KafkaProducer<String, String> producer;

    // in public ProducerImpl() 构造器：
    properties = new Properties();
    properties.put("bootstrap.servers", "localhost:9002");  // 参数一：Kafka server IP and port
    properties.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");  // 参数二：key 的序列化器
    properties.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");  // 参数三：value 的序列化器
    producer = new KafkaProducer<String, String>(properties);

    // in public void send(TestPack pkg) 方法：将 TestPack 对象封装到 ProducerRecord 类中
    try {
        // producer.beginTransaction();
        // JSON.toJSONString(pkg)：将 TestPack 对象序列化成字符串 
        ProducerRecord record = new ProducerRecord(topic, pkg.getId().toString(), JSON.toJSONString(pkg));
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
    * Consumer 接口：包含方法 consumeMsg() 和 close()
    * Consumer 接口的实现类 ConsumerImpl：
    ```java
    // in public ConsumerImpl() 构造器：
    properties = new Properties();
    properties.put("group.id", "consumer-group1");  // 参数一：消费者组
    properties.put("bootstrap.servers", "localhost:9092");  // 参数二：Kafka server IP and port
    properties.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");  // 参数三：key 的序列化器
    properties.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");  // 参数四：value 的序列化器
    consumer = new KafkaConsumer(properties);

    // in public void consumeMsg() 方法：
    consumer.subscribe(Collections.singletonList(topic));  // 订阅 topic
    try {
        while (true) { 
            ConsumerRecords<String, String> poll = consumer.poll(Duration.ofSeconds(1));  // 拉取数据
            for (ConsumerRecord o : poll) {
                ConsumerRecord<String, String> record = (ConsumerRecord) o;
                TestPack pkg = JSON.parseObject(record.value(), TestPack.class);  // 将单个消息反序列化成对象
                System.out.println(" pack msg = " + pkg);
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

* 流程简述
    * 生产者：配置 producer properties，创建 KafkaProducer，构造 ProducerRecord
    * 消费者：配置 consumer properties，创建 KafkaConsumer，订阅 topic，拉取 ConsumerRecords，业务处理 

