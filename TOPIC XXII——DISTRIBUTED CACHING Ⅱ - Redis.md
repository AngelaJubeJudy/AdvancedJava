# TOPIC XXII: DISTRIBUTED CACHING Ⅱ: Redis


## 1. Redis 基本功能：34'17''
* redis server 的安装 
    * 下载、源码编译 
    * 操作系统自带的方式：brew, apt, yum 
    * docker 方式：拉取镜像启动
    ```bash
    <!-- 安装 -->
    docker pull redis
    docker run -itd --name redis-test -p 6379:6379 redis

    <!-- 查看 Redis 版本 -->
    docker image inspect redis:latest|grep -i version 

    <!-- 启动 -->
    docker start redis-test
    docker ps -a
    <!-- 进入容器，查看 redis 状态 -->
    docker exec -it redis-test /bin/bash
    $ redis-cli
    > info
    ```
    * 坑：以上方式默认无 `redis.conf` 配置文件
        * 解决：讲宿主机上的配置文件映射在 Docker 里
        ```bash
        docker run -p 6379:6379 --name redis01 -v /etc/redis/redis.conf:/etc/redis/redis.conf -v /etc/redis/data:/data -d redis redis-server /etc/redis/redis.conf --appendonly yes
        ```

* 性能测试
    * Redis 自带命令：redis-benchmark
    ```bash
    <!-- 在 Docker 容器的 shell 中运行以下测试命令 -->
    redis-benchmark -n 100000 -c 32 -t SET,GET,INCR,HSET,LPUSH,MSET -q 
    <!-- 不指定时，默认会测试大量命令 -->
    redis-benchmark -n 100000 -c 32 -q 
    ```

### 数据结构
* 基本数据结构
    * `字符串（string）`
        * 表示：int, string, byte[]
        * 二进制安全
        * `可以用来接受任意结构格式的数据`；上限512M
        * 可操作命令：[字符型] set/gte/getset/del/exists/append, [整数] incr/decr/incrby/decrby
        * 注：
            * 字符串 append 会使用更多内存（每次默认扩容一倍内存）。
            * 整数共享：能用尽量用，减少内存用量；副作用————多方引用，对 redis 的淘汰策略产生影响。
            * 整数精度：16位左右，一般够用；超出者丢精，建议使用字符型保存。
    * `散列（hash）`
        * 可看作 map 或 POJO 对象
        * Key-value 结构
        * 可操作命令：操作某个 key（hset/hget），操作整体（hmset/hmget），操作 map（hgetall/hdel/hexist/hlen/hkeys/hvals），操作整型（hincrby）
    * `列表（list）`
        * 相当于 JAVA 中的 LinkedList 
        * 按插入顺序排序的`字符串`链表（left 和 right 均可插入元素）
        * 插入时 key 不存在 --> 为该 key 创建一个新链表
        * 链表中所有元素均被移除  --> 当前 key 从 redis 中删除
        * 可操作命令：lpush/rpush/lrange/lpop/rpop
    * `集合（set）`
        * 相当于 JAVA 中的 set，无重复元素的 List 
        * 未排序的字符集合
        * O(1)，可操作命令：sadd/srem/smembers/sismember, sdiff求差集 / sinter求交集 / sunion求并集
    * `有序集合（sorted set）`
        * 与 set 型类似；不同点在于每个成员会关联一个数值 score（可重复分数），按分数从小到大排序。
        * 可操作命令：前缀“z-”，“zrev-”前缀会使分数按从大到小排序。

* 高级数据结构
    * Bitmaps 位图
        * 可操作命令：setbit/getbit/bitop/bitcount/bitpos
        * 位操作
        * 注：底层数据结构是字符串，最大可设置 2^32 个不同的 bit
    * Hyperloglogs 
        * 可操作命令：pfadd/pfcount/pfmerge
        * 使用概率的方式统计数据：小量数据表示大量数据范围；允许误差。最坏需要 12K 计算 2^64 个不同元素的基数。
    * GEO 地理信息
        * 可操作命令：geoadd/geohash/geopos/geodist/georadius/georadiusbymember
        * 实际应用：计算附近的人、餐馆等

### 单线程 / 多线程？
* redis 6 版本之前：IO 部分 使用 BIO 模型，单线程处理数据。
* redis 6 之后：IO 部分使用多线程 NIO 模型。
* redis 的 `内存数据处理线程`：一直是单线程！
* redis 的编程模型：`“确定性系统”`————在处理所有数据时必须使用单线程模型。


## 2. Redis 六大使用场景 / Redis 的 JAVA 客户端：31'42''
### Redis 六大使用场景
* `业务数据缓存`
    * 通用数据集中式缓存
    * 缓存实时热数据
    * 会话缓存（例，用户 token，多个服务器共享一个redis查询）
* `业务数据处理`
    * 非严格一致性要求的数据（先放入 redis，处理速度比数据库快很多；例，转赞评）
    * 业务数据去重（例，订单处理的幂等校验）
    * 业务数据排序（例，排行榜）
* `全局一致计数`
    * 全局流控计数
    * 实际场景：秒杀库存，抢红包
    * 全局 ID 生成：全局唯一 ID，用 key 模拟全局 sequence，性能较高，实现简单
* `高效统计计数`
    * 全局 bitmap 操作（转化为 int 或 Long，进行位操作）：ID 去重，记录访问 IP 等
    * 访问量（UV, PV），非严格一致性要求的大批量数据，使用 Hyperloglogs 型
* `发布订阅与 Stream`
    * 模拟 MQ 
    * Pub-Sub 模拟队列（例，订阅 key: 'comments'）
        * 发布（向队列中发送消息）
        ```redis-cli
        publish comments msg1
        publish comments msg2
        publish comments msg3
        ```
        * 订阅（可以看到所有消息，含最新，Ctrl+C 退出消息读取）
        ```redis-cli
        subscribe comments
        ```
    * redis 5.0版本新增数据结构：`Redis Stream`（消息队列机制）
* `分布式锁`
    * 分布式多机场景全局地锁住某些资源
    * 获取锁（例，key: 'dlock'）————单个`原子性`操作
        ```redis-cli
        <!-- 'NX' 机制代表有key就设置值，不存在不设置 -->
        <!-- 'PX 300000' 代表该分布式锁的超时时间（ms），保证在最坏的情况下一定能释放锁 -->
        set dlock my_random_value NX PX 300000
        ```
        > 注：redis 的单线程模型决定了设置值的操作一定有先后顺序（`串行`）！则只有第一个设置值的并发线程会成功。设置成功，则拿到了该分布式锁。
    * 释放锁
        * 注：释放当前业务处理拿到的锁 --> `先判断，有再删除`
        * 注：两个原子性操作合在一起不是原子性操作，∴ 写一个 `LUA 脚本`交由 redis 执行，串行单线程处理，从而具有`事务性`。

### Redis 的 JAVA 客户端
* Jedis
    * 官方客户端，类似 JDBC；对 redis 命令的封装
    * 该驱动包基于 BIO，线程不安全，需要配置连接池来管理所有连接
    ```java
    // demo
    Jedis jedis = new Jedis("localhost", 6379);
    System.out.println(jedis.info());
    jedis.set("uptime", new Long(System.currentTimeMillis()).toString());
    System.out.println(jedis.get("uptime"));
    jedis.set("teacher", "Cuijing");
    System.out.println(jedis.get("teacher"));
    ```
* Lettuce（主流推荐）
    * 该驱动包基于 Netty NIO，API 线程安全
    * in pom.xml: 
    ```xml
    <dependency>
        <groupId>io.lettuce</groupId>
        <artifactId>lettuce-core</artifactId>
    </dependency>
    ```
    * in application.yml: 
    ```yaml
    spring:
        datasource:
            username: root
            password:
            url: jdbc:mysql://localhost:3306/test?useUnicode=true&characterEncoding=utf-8&serverTimezone=UTC
            driver-class-name: com.mysql.jdbc.Driver
        cache:
            type: redis
        redis:
            host: localhost
            lettuce:
            pool:
                max-active: 16
                max-wait: 10ms
    ```
* Redission
    * 该驱动包基于 Netty NIO，API 线程安全
    * 亮点：实现了大量`分布式的功能特性`（在不同应用节点间共享数据）


## 3. Redis 与 Spring 整合 / Redis 高级功能：47'15''
### Redis 与 Spring 整合
* Soring Data Redis 组件 
    * 核心：RedisTemplate（可配置基于 Jedis, Lettuce, Redission）
    * 使用方式：类似 MongoDBTemplate, JDBCTemplate 或 JPA
    * Template 中封装了 redis 基本命令

* Spring Boot 与 Redis 集成
    * 引入 spring-boot-starter-data-redis

* Spring Cache 与 Redis 集成
    * in pom.xml: 
    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-cache</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    <dependency>
        <groupId>net.sf.ehcache</groupId>
        <artifactId>ehcache</artifactId>
        <version>2.8.3</version>
    </dependency>
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis-ehcache</artifactId>
        <version>1.0.0</version>
    </dependency>
    ```
    * 默认使用全局的缓存管理器 CacheManager，实现自动集成
    * 使用 ConcurrentHashMap 或 ehcache 做缓存时，无需考虑序列化（因为是本地缓存，都在 JVM 内部）。
    * 使用 redis 做缓存时，默认用 JAVA 的对象序列化，对象需要实现 Serializable 接口；支持自定义配置序列化方式。

* `MyBatis 项目集成 cache 示例`
    * 增加缓存机制，加速 ORM 操作数据库的读操作处理
    * operation 1：【数据库层】集成 Spring Boot 与 MyBatis，实现简单的单表操作，对外配置 REST 接口。
    * operation 2：【ORM层】配置 本地ehcache + MyBatis 集成，实现 MyBatis 二级缓存（若命中缓存，结果在 MyBatis ORM 层直接返回，无需访问数据库）。
    * operation 3：【Service级别缓存，更高效】配置 Spring Cache + ehcache，实现 Service 方法级别缓存。
        * Controller 调用 Service 方法：命中缓存，直接返回；未命中，执行 mapper 中的代码。
    * operation 4：修改配置，Spring Cache 中的本地缓存 ehcache 替换为 redis 远程缓存（共用的集中式缓存）。
    * operation 5：修改配置，Spring Cache 中的 JAVA 对象序列化替换为 jackson json 序列化。
    * operation 6：以上的每一种改动，可以使用 wrk 压测接口性能，比较不同场景下的性能差异，进一步分析总结。
    * operation 7：尝试调整不同配置和参数，理解 cache 原理和用法。

### Redis 高级功能
* Redis 事务
    * Q：最终数据以 DB 为准，不要求 Redis 强一致，为什么还需要实现 Redis 事务？ 
    * `单线程模型`可以很方便地实现事务机制
    * Redis 命令
        * 开启事务：multi
            * 之后的操作显示“QUEUED”，表示接下来的所有命令（提交前）都缓存到了队列，暂未执行。
        * 提交事务给 Redis Server：exec
            * 打包并执行命令。
        * 撤销、回滚：discard
    * 优化：Watch 实现乐观锁
        * watch key，发现有变化 --> 事务自动失败。

* Redis Lua
    * Redis Server 内部内置了 LUA 脚本引擎。
    * 类似于实现 open resty 时，在 nginx 中集成 LUA jit 引擎。
    * 执行脚本：
    ```redis-cli
    <!-- 执行零参数 LUA 脚本 -->
    eval "return'hello java'" 0
    <!-- 传参：key = "MK2", value = "MK222" -->
    eval "redis.call('set',KEYS[1],ARGV[1])" 1 lua-key lua-value 
    eval "redis.call('set',KEYS[1],ARGV[1])" 1 MK2 MK222
    ```
    * 预编译（加快访问速度）
        * 加载脚本，返回 `SHA-1 签名字符串（之后用来代表脚本）`：
            ```redis-cli
            script load "脚本片段"
            ```
        * 调用 shastring 方法（"shastring" 代表脚本内容，keynum 代表 key 的数量）：
            ```redis-cli
            evalsha "shastring" keynum [k1 k2 k3 ...] [param1 param2 param3 ...]
            ```
    * 单线程：原子性，每个脚本的执行都不会被其他线程打断；每个脚本的执行都能保证事务（出错则不会提交）。

* Redis 管道技术（Pipeline）
    * “管道命令”，在 OS 中用 telnet 或 nc 命令发送一连串`毫不相关的命令`（命令间以“/r/n”回车换行），交给 Redis Server 执行：结果批量返回；类似一种 redis 内部支持的批量处理。

* Redis 数据恢复与备份
    * （默认备份方式）`RDB` ~ frm
        * 全量备份数据文件
        * 执行 save：生成 dump.rdb 文件，包含当前 redis 中所有数据。
        * 执行 bgsave：异步执行，在后台生成 dump.rdb 文件。
        * 通过“config get dir”命令查看 dump.rdb 文件存储路径。
        * 恢复：dump.rdb 文件放在 redis 的“/data”文件夹下，重启 redis，初始化。
    * 追加日志文件`AOF` ~ binlog
        * 所有操作以命令的方式记录在 AOF 文件中。
        * 需要配置：
            * 文件名：appendfilename "appendonly.aof"
            * AOF 文件和 Redis 命令的同步频率（刷新频率）：appendfsync always 每条都同步 / everysec 每秒同步 / no 不同步
        * 恢复：AOF 文件可以在 Redis 启动时自动加载。
            
* 性能优化
    * 内部核心优化点一：内存
        * 配置参数 hash-max-ziplist-value 64 或 zset-max-ziplist-value 64：用 ziplist 优化 hash 和有序集合的内部表示，减少内存使用，提升 redis 内存使用效率。
    * 内部核心优化点二：CPU
        * 因为是单线程 CPU，永远不要阻塞！！！
            * LUA 脚本中不要有特别耗时的操作
            * 谨慎使用范围操作（例，"keys *"等）
            * SLOWLOG：redis 默认超过 10ms 的就会记录在 SLOWLOG 中，保留最近的128条。 

* 分区（内存容量问题）
    * 类比数据库的垂直拆分
    * 多个业务系统：共用？分开用？
        * 数据量都很小：共用。
        * 不考虑资源和成本的情况下，尽量分开，避免相互干扰。
        * 做好 key 的规划，规范取名：（分布式三大块）服务 => 服务的全限定名称[前缀：“业务线.产品.模块.功能.方法”]，缓存 => key，MQ => MQ队列名。
    * 大规模缓存资源：专人维护
        * 原发团队：申请缓存资源并配置

### 使用经验 
* 性能
    * client 端：线程数（4~8个）和连接数（<10,000）不宜过大
    * 统计和评估当前缓存的性价比：监控操作读写比和缓存命中率
* 容量
    * 确保缓存资源充分利用
    * 监控注意增量变化（增量大，影响缓存使用效率）
* 资源管理和分配
    * 尽量使用独立的 redis
    * 控制 redis 资源的申用，规范环境和 key 的管理（防止冲突和数据错乱）
    * 监控 CPU 的使用，防止单线程模式下的高延迟卡顿
