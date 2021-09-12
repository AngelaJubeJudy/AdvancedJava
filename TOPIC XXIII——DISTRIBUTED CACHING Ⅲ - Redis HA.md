# TOPIC XXIII: DISTRIBUTED CACHING Ⅲ: Redis HA

## 1. Redis 集群与高可用：72'29''

### Redis 集群与高可用
* Redis 主从复制
    * （Redis 内存数据库）从单节点到多节点，类似 MySQL 的主从
    * 主从结构（`主从复制+读写分离`）：主库处理写请求；`从库只读`，`异步复制`主库，处理读请求（从库也可以不从主库复制数据，而是挂在其他从库上）
    * 实操
        * 配置主从：
        ```redis-cli
        127.0.0.1 6380> SLAVEOF 127.0.0.1 6379
        127.0.0.1 6380> info
        # Replication
        role:slave
        127.0.0.1 6380> get port 
        6379
        127.0.0.1 6380> set port sss
        (error) READONLY You can't write against a read only replica.
        ```
        * 配置文件 redis.conf
        ```conf
        # 端口
        port 6379
        # pid 文件
        pidfile "/var/run/redis_6379.pid"
        # 数据文件夹
        dir "/Users/xxx/logs/redis0"
        # IO 线程数（可配置）
        io-threads 4
        # AOF 模式
        appendfilename "appendonly.aof"
        # 数据日志的持久化方式
        appendonly no
        # 刷盘策略
        appendfsync always
        # 配置该节点从启动时就作为从库
        replicaof ::1 6380
        ```
        * 启动 Redis Server
        ```bash
        redis-server redis6379.conf
        redis-server redis6380.conf
        ```
* `Redis Sentinel` 主从切换：走向高可用 MHA
    * Sentinel 监控主从节点的在线状态，负责切换
    * Sentinel 也可以做成集群（依靠分布式的一致性协议 raft）
    * Redis Sentinel 是 Redis Server 里的一个功能块，两种启动方式（redis-sentinel命令相当于 redis-server 命令的一个软链接）： 
        ```bash
        > redis-sentinel sentinel.conf
        > redis-server redis.conf --sentinel
        ``` 
    *  `配置文件 sentinel.conf`（主从切换的频率和速度）
        ```conf
        <!-- 指定要监控的 master 节点；“2”表示最少需要2个 sentinel 集群来投票选举，选择哪个 slave 可以变为主库 -->
        sentinel monitor mymaster 127.0.0.1 6379 2
        <!-- 主库宕机后 sentinel 触发选举的等待时间60秒，心跳 -->
        sentinel down-after-milliseconds mymaster 60000
        <!-- failover 允许选举的最长时间3分钟 -->
        sentinel failover-timeout mymaster 1800000
        <!-- 单位时间内可以并行地去主库拉取数据的从库个数 -->
        sentinel parallel-syncs mymaster 1
        ```
    * 无需配置从节点：主从网络拓扑信息可以通过“info”命令获取
    * 实操
        * 启动 redis servers
        ```bash
        redis-server redis6379.conf
        redis-server redis6380.conf
        ```
        * 配置主从 
        ```redis-cli
        127.0.0.1 6380> SLAVEOF 127.0.0.1 6379
        ```
        * 主库清空数据；检查
        ```redis-cli
        127.0.0.1 6379> flushall
        127.0.0.1 6379> info
        ```
        * 修改配置文件 sentinel.conf
        ```conf
        sentinel monitor mymaster 127.0.0.1 6379 2
        sentinel down-after-milliseconds mymaster 60000
        sentinel failover-timeout mymaster 1800000
        sentinel parallel-syncs mymaster 1
        port 26379
        ```
        * 启动 redis sentinel
        ```bash
        redis-sentinel sentinel0.conf
        redis-sentinel sentinel1.conf
        ```
        * 宕机模拟：redis6379 Ctrl+C 停止服务
        * Q：重启 redis6379 会发生什么？
            * A：redis6379 转换成 6380 的 slave 了，sentinel 负责完成其角色转换。
            * Q：应用程序端应该如何修改？（不做改动）
                * 封装一：sentinel 连接池
                ```java
                // 配置所有 sentinel 节点到池中，由 Sentinel 去判断主从
                sentinels.add(new HostAndPort("127.0.0.1",26379).toString());
                sentinels.add(new HostAndPort("127.0.0.1",26380).toString());
                JedisSentinelPool pool = new JedisSentinelPool(masterName, sentinels, config, TIMEOUT, null);
                ```
                * 封装二：集群模式
                ```java
                JedisCluster jedisCluster = null;
                // 添加集群的服务节点Set集合
                Set<HostAndPort> hostAndPortsSet = new HashSet<HostAndPort>();
                // 添加节点
                hostAndPortsSet.add(new HostAndPort("127.0.0.1", 6379));
                hostAndPortsSet.add(new HostAndPort("127.0.0.1", 6380));
                // Jedis连接池配置
                JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
                // 最大空闲连接数, 默认8个
                jedisPoolConfig.setMaxIdle(12);
                // 最大连接数, 默认8个
                jedisPoolConfig.setMaxTotal(16);
                // 最小空闲连接数, 默认0
                jedisPoolConfig.setMinIdle(4);
                // 获取连接时的最大等待毫秒数(如果设置为阻塞时BlockWhenExhausted),如果超时就抛异常, 小于零:阻塞不确定的时间,  默认-1
                jedisPoolConfig.setMaxWaitMillis(2000); // 设置2秒
                // 对拿到的 connection 进行 validateObject 校验
                jedisPoolConfig.setTestOnBorrow(true);
                // 集群
                jedisCluster = new JedisCluster(hostAndPortsSet, jedisPoolConfig);
                ```
                * 封装三：直接连接 sentinel 节点
                ```bash
                redis-cli -p 26379
                redis-cli -p 26380
                ```

* Redis Cluster：走向分片，全自动分库分表
    * 主从复制不解决容量问题，还是单机
    * Redis Cluster：一致性哈希方式
        * 数据分散到多个服务器节点：共 16384（16K）个槽位，分散到多台 redis server 
        * redis 客户端对 Key 使用 crc16 算法计算一个值，然后模16384，得到当前 Key 对应的哈希槽位序号（在槽位对应的节点上操作）。
        * 启动
        ```redis-cli
        cluster-enabled yes
        ```
    * 节点间使用 Gossip 协议通信：规模要小于1000
    * 一致性要求：默认所有槽位可用时才对外提供服务
    * 一般配合主从模式使用

### Redission
* Redis 的 JAVA 分布式组件库
    * 该驱动基于 Netty NIO，API 线程安全
    * 亮点：实现了大量`分布式的功能特性`（在不同应用节点间共享数据）
* 实操
    * `分布式锁`
        * 
        ```java
        public class RedissionDemo {
            @SneakyThrows
            public static void main(String[] args) {
                Config config = new Config();
                config.useSingleServer().setAddress("redis://127.0.0.1:6379");
                final RedissonClient client = Redisson.create(config);
                RMap<String, String> rmap = client.getMap("map1");
                RLock lock = client.getLock("lock1");
                try{
                    lock.lock();
                    for (int i = 0; i < 15; i++) {
                        rmap.put("rkey:"+i, "111rvalue:"+i);
                    }
                    // 代码块 W1：一直循环，没有释放锁
                    while(true) {
                        Thread.sleep(2000);
                        System.out.println(rmap.get("rkey:10"));
                    }
                }finally{
                    lock.unlock();
                }
            }
        }

        public class RedissionDemo1 {
            // 同下
            // 因为 map1 的锁（同一server的同名锁，即分布式的全局锁）一直无法被释放，RedissionDemo1 无法如下所示正常打印
        }
        ```
    * `分布式 Map`, RMap (Redis Map)
        * 两个类共享一个 redis：不同 JVM 里操作的其实时同一个 rmap
        ```java
        public class RedissionDemo {
            @SneakyThrows
            public static void main(String[] args) {
                Config config = new Config();
                config.useSingleServer().setAddress("redis://127.0.0.1:6379");
                final RedissonClient client = Redisson.create(config);
                RMap<String, String> rmap = client.getMap("map1");
                RLock lock = client.getLock("lock1");
                try{
                    lock.lock();
                    for (int i = 0; i < 15; i++) {
                        rmap.put("rkey:"+i, "111rvalue:"+i);
                    }
                }finally{
                    lock.unlock();
                }
                
                // 代码块 W1
                while(true) {
                    Thread.sleep(2000);
                    System.out.println(rmap.get("rkey:10"));
                }
            }
        }

        public class RedissionDemo1 {
            public static void main(String[] args) {
                Config config = new Config();
                config.useSingleServer().setAddress("redis://127.0.0.1:6379");
                final RedissonClient client = Redisson.create(config);
                RLock lock = client.getLock("lock1");
                try{
                    lock.lock();
                    RMap<String, String> rmap = client.getMap("map1");
                    for (int i = 0; i < 15; i++) {
                        rmap.put("rkey:"+i, "rvalue:22222-"+i);
                    }
                    System.out.println(rmap.get("rkey:10"));
                }finally{
                    lock.unlock();
                }
            }
        }
        ```

### Hazelcast 内存网格
* 另一个常见的内存网格：Apache Edgent 
* Hazelcast IMGD (in-memory data grid)
* 特性
    * 分布式的：数据均匀分布在集群所有节点上
    * 高可用：所有节点可写，根据使用自动同步数据到最近的节点；多副本
    * 可扩展的：扩缩容方便
    * 面向对象的：数据模型是面向对象的和非关系型的
    * 低延迟：基于内存，可用堆外内存（避开 GC 问题）
* vert.x 默认集成了 Hazelcast 

* 架构
    * 支持各种语言
    * 支持各种缓存相关技术
    * 内置分片、集群等功能
    * 内部基于分布式协议确保强一致性，可靠
    * 支持事务

* 部署模式
    * Client-Server 模式
        * 远程的集中式缓存：Hazelcast 多节点组成集群，应用服务的集群访问 Hazelcast 集群
        * 支持 Hazelcast 多节点组成集群（`远程+本地，得到由内存节点组成的网状结构`）
    * Embedded 模式
        * Jar 包作为依赖，直接放入应用程序：在每个 JVM 上开辟一块内存空间做本地缓存
        * 支持 Hazelcast 多节点组成集群（`远程+本地，得到由内存节点组成的网状结构`）

* 数据分区
    * 例，Map 结构，默认数据集有271个分区（可配），所有分区均匀（∵ 271是一个质数，除不尽）分布于集群所有节点上。支持多副本机制（副本间的同步依靠分布式的一致性协议实现），高可用。

* 集群与高可用
    * 默认 AP：集群都是自动化管理
    * 扩容和弹性自动计算平衡，业务无感知
    * 实际问题一：auto rebalance 产生性能抖动，一般可接受，但业务有感知。
    * 实际问题二：频繁重启操作，有可能导致线上脑裂，严重！

* 事务支持
    * 完备
    * 支持一阶段、两阶段

* 数据亲密性
    * 场景：数据分布在数据网格的不同节点上，当前操作所属节点和待操作数据不在同一个节点上，导致频繁的数据传输。
    * Hazelcast 的设计：代码手动/自动地部署到相关数据所在节点。
        * 定义数据分区接口：
        ```java
        public interface ParitionAware<T>{
            T getPartitionKey();
        }
        ```


