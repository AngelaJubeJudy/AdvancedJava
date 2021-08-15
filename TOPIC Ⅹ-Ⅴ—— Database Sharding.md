# TOPIC Ⅹ-Ⅴ: 数据库拆分与分库分表

## 0. 写在前面

* 单机MySQL技术演进
    * 读写压力（特别是高并发读的压力影响写）————`多机集群`（一主多从，每个MySQL节点上都是全量数据），主从复制（一致性）+读写分离
    * 高可用性————`故障转移`，主从切换（复制关系改变）
    * 容量问题————`数据库拆分`，分库分表（垂直拆分，按业务；水平拆分，数据主键ID取模等方式），将整个节点的数据量变小
    * 分库分表导致的一致性问题————`分布式事务`，XA/柔性事务
        * 分布式事务：保证多个不同的数据节点间各个独立的本地事务的操作要么全部写入多个数据库，要么全部未写入（回滚）。
        * XA 事务：强一致性；`数据库底层`需支持 XA 协议，外层封装使用。
        * 柔性事务：弱一致性/最终一致性；`业务侧`建立的分布式协调机制，与数据库无关。

* 思考：为什么要做数据库拆分？
    * 单机数据库已无法适应互联网发展：数据规模急速增长，带来容量、性能、可用性、运维成本4个方面的海量数据需求场景。
        * `容量`：超越容量水位 -> 索引技术增加，磁盘IO压力增大。
        * `性能`：B+树的索引深度增加（B-Tree / B+Tree：按块存储数据，适合`磁盘`中的索引）->磁盘访问的IO增加->查询性能下降；另外，高并发的访问请求使集中式数据库成为瓶颈。 
        * `可用性`：服务化的无状态（无状态 = 应用宕机再拉起对系统无感知，对数据正确性无影响，所以可以增加节点增加机器；系统的状态都维护在数据库，所有操作最终以数据库里的数据为准） -> 小成本随意扩容 -> 单一数据节点/简单的主从DB已无法满足需求。
        * `运维成本`：数据库实例规模达到阈值，主从同步、数据备份以及数据恢复的时间成本上升（系统可靠性的挑战）。

* 思考：主从复制能否解决？
    * 已解决：高可用，读扩展
    * 未解决：`单机`写性能，容量问题
        * 单个数据库容量太大，无法`备份`
        * `主从延迟`较高 -> 影响性能和稳定性
        * 无法直接在线上主库上`执行DDL`（所有DDL操作都会锁表）

* 提高容量的 solution：分库分表
    * 分布式DB，多个数据库，作为`数据分片的集群`提供服务
    * 好处：降低单节点写压力，提升整个系统的容量上限
    * 扩展方式指导原则————“`扩展立方体`”
        * x-axis：通过`克隆`整个系统复制，建`集群`（水平；最简单，整体扩展）
        * y-axis：通过解耦不同功能复制，`业务拆分`（垂直；按需，子系统的扩展）
        * z-axis：通过拆分不同数据扩展，`数据分片`（拆分同类数据，不同扩展方式）
    * 坏处：所有操作分散在不同数据库上，导致一个事务被破坏（一致性问题），需要引入分布式事务来解决。

* 数据扩展
    * 全部数据，x-axis：数据复制————主从结构、备份、高可用
    * 业务分类数据，y-axis：垂直分库分表————分布式服务化、微服务
    * 任意数据，z-axis：水平分库分表————分布式结构、任意扩容

## 1. 数据库垂直拆分：39'17''
* 淘宝的服务化契机
    * 问题一：服务不能复用（依赖内部库JAR包，代码配数据库去访问）
    * 问题二：连接数不够（MySQL的IO接入层是BIO，连接数非常宝贵，默认也很小值）
* 发展趋势，`微服务改造的基础`：垂直分库分表 -> 分布式服务化 -> 微服务架构
    * 数据中间件：TDDL
    * RPC 的框架：SSF
    * 数据拆分：3C（TC 交易订单数据, IC 商品数据, UIC 用户数据）
    * 微服务架构：专门访问数据库的服务单独部署；远程RPC调用接口 

### 分库分表
* 垂直`拆库`
    * 例，3C
    * 最常见
    * 含义：一个数据库按不同业务处理能力拆分成不同数据库
    * 问题：影响业务系统（数据库结构发生变化 -> SQL和关联关系也发生变化）
        * SQL 也拆分：原先大的关联查询拆分成几个小的查询在不同数据库操作，业务代码做查询结果的组合封装
        * 拆分方案：提前梳理，使影响范围可控

* 垂直`拆表`
    * 含义：针对单表数据量过（宽表）的情况，多单表进行拆分（一个主表 -> 一个核心表+多个子表）；效率较低，代码难维护，GC难度大
    * 问题：拆分点对原有业务影响很大，出现较大故障的风险增大

### 优缺点
* 优
    * 单库单表变小 -> 便于管理维护
    * 数据库集群的性能和容量提升
    * 系统和数据复杂度降低（简化了关联关系和业务复杂度）
    * 可作为微服务改造的基础
* 缺
    * 库数量增加 -> 管理复杂
    * 对业务系统侵入性强（影响了原有关联关系）
    * 改造过程复杂，易出故障（业务和数据库都有改动）
    * 拆分有上限（到一定程度无法继续）

### 一般做法
* 4步骤
    * 梳理拆分范围（尽量小）、影响范围（业务功能、代码、SQL）
    * 检查评估和重构影响到的服务（增加adpater或防腐层，将其与外围功能隔离，屏蔽影响范围）
    * 准备新的数据库集群，复制数据
    * 修改系统配置（指向新库），发布新版上线 

* 拆分前思考
    * 先拆系统？先拆数据库？
        * 先拆系统，公用数据库：常见做法
        * 先拆数据库：灰度问题，系统是同一套
    * 先拆多大范围（粒度）？
        * 复杂系统：先拆一个小块，调研影响范围和关联关系；经验复用到其他部分
        * 熟悉的系统：N小块一起拆分


## 2. 数据库水平拆分：44'50''
### 水平拆分
* 含义：对数据分片，不影响数据本身结构。
    * 数据库结构复制到不同数据库，仅拆分数据，降低单个表的数据量（索引层级变小，查询效率提高、性能提升）

* 类型
    * 分库：数据放在不同库
    * 分表：数据放在不同表

* 分库分表
    * 按主键分片
    * 按时间分片（当前表、历史表）
    * 强制按条件指定（新库，老库；VIP，普通会员）
    * 自定义方式（可利用中间件）

* 拆分建议
    * Q：DBA / 中间件：不建议分表，只建议分库；为什么？
    * A：
        * 分库：`提升整个集群的并行数据处理能力`（数据分散在不同数据库实例，适用不同磁盘，降低磁盘IO）；针对数据本身读写压力较大的场景。
        * 分表：降低单表数据量（但总的数据量没有变化->整体的磁盘IO和网络IO不会降低），减少单表操作时间，`提升单个数据库上的并行操作多表处理`能力`。表变多，DBA管理压力增大。
        * 每个 MySQL 实例上可以建虚拟的DB，类似于分表的效果。

* 优缺点
    * 优：解决容量问题；对系统的影响小于垂直拆分；部分提升性能和稳定性。
        * 业务系统侵入性较小
        * 利用中间件，做到对业务系统透明
    * 缺：集群规模大，管理复杂（多次操作）；复杂SQL支持（范围问题，业务侵入性、性能）；数据迁移问题（数据库的扩容、缩容）；一致性问题。

* demo: ShardingSphere-Proxy 实战
    * 新建数据库及表
    ```sql
    create schema demo_ds_0;
    create schema demo_ds_1;
    create table if not exists demo_ds_0.t_order_0 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
    create table if not exists demo_ds_0.t_order_1 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
    create table if not exists demo_ds_1.t_order_0 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
    create table if not exists demo_ds_1.t_order_1 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
    ```

    * 利用 ShardingSphere-Proxy 中间件将两个库两个表虚拟成一个数据库（sharding_db）
        * 修改配置文件：server.yaml 和 config-sharding.yaml
            * server.yaml
            ```yaml
            authentication:
                users:
                    root:
                        password: root
                        sharding: 
                            password: sharding
                            authorizedSchemas: sharding_db

            props:
            max-connections-size-per-query: 1
            acceptor-size: 16  # The default value if avaiable processors coutn * 2.
            executor-size: 16  # Infinite by default.
            proxy-frontend-flush-threshold: 128  # The default value is 128.
            proxy-transaction-type: LOCAL
            proxy-opentracing-enabled: false
            proxy-hint-enabled: false
            query-with-cipher-column: false
            sql-show: true
            check-table-metadata-enabled: false
            ```
            * config-sharding.yaml 分库分表配置：两个虚拟数据源配置在dataSources中，sharding规则配置在rules中。
            ```yaml
            
            ```
        * 启动（路径：\apache-shardingsphere-5.0.0-beta-shardingsphere-proxy-bin\apache-shardingsphere-5.0.0-beta-shardingsphere-proxy-bin\bin）
        ```shell
        bin/start.sh
        ```
    * 连接数据库，验证（显示“Server version: 8.0.23-ShardingSphere-Proxy 5.0.0-RC1”即已连接ShardingSphere的数据库，而非原始数据库）
    ```bash
    mysql -h 127.0.0.1 -P 3307 -uroot -proot -A
    ```
    * 使用数据库
    ```sql
    show schemas;
    use sharding_db;
    insert into t_order(user_id, status) values(1, "OK"),(1, "FAIL");
    insert into t_order(user_id, status) values(2, "OK"),(2, "FAIL");
    ```
    * 验证分库分表结果（以上插入的4条记录在真实数据库表里均匀分布，各一条）
    ```sql
    select * from demo_ds_0.t_order_0;
    select * from demo_ds_0.t_order_1;
    select * from demo_ds_1.t_order_0;
    select * from demo_ds_1.t_order_1;
    ```
    通过查询虚拟表 t_order，可将上述结果一并查出，
    ```sql
    select * from t_order;
    ```
    * 提升查询效率：附加精确查询条件，不用把所有库表查询一遍
    ```sql
    select * from t_order where user_id=2;
    ```


### 数据的分类管理 
* 目标：提升数据管理能力
* 明确对数据的要求 -> 选择合适的手段优化系统
* 不同数据的划分，采取不同处理方式
* 历史数据（不应占用线上资源，`冷数据`，压缩存储到磁盘），活跃数据（查询、操作需求更高，`热数据`，同时放在数据库和内存）；`温数据`放在数据库，正常查询；`冰数据`备份到磁盘类介质上，不提供查询。


## 3. 相关框架和中间件；如何做数据迁移：28'51''
### JAVA 框架层
* TDDL：淘宝分布式数据层
* Apache ShardingShpere-JDBC：长期维护

### 中间件层
* DRDS（TDDL 的升级版；闭源）
* Apache ShardingShpere-Proxy（Apache ShardingShpere-JDBC 的中间件版）
* MyCat / DBLE（MyCat 的升级版）
* Cobar
* Vitness（GO语言，YouTube）
* KingShard（GO语言）
* 技术演进
    * 原因：摩尔定律的失效，从多核时代到分布式的崛起
    * 分布式的3大问题，CAP：Consistency 一致性，Availability 可用性，Partition-Tolerance 分区容忍性
        * 不存在CAP三角，只能从CA、CP、AP 中选择实现
        * CA——传统的数据库
        * CP——NoSQL
        * AP
* 数据库的演进
    * 类库/框架（TDDL, Apache ShardingShpere-JDBC）：在单机数据库之上提供分库分表能力，在业务侧增强，类库/框架与业务系统打包在一起。
    * 数据库中间件：业务系统和数据库中间，模拟数据库
    * 路线一：分布式数据库（Spanner, Aurora, GaussDB, PolarDB, OceanBase, TiDB, CockroachDB, ...）
    * 路线二：数据网格
        * 类似服务网格
        * Sidecar

* 数据库中间件 ShardingSphere
    * 一套开源的分布式数据库中间件解决方案组成的生态圈
    * 3款产品：JDBC, Proxy, Sidecar
        * JDBC：同构场景；在 JAVA JDBC 接口之上封装的框架，直接在业务代码使用，支持常见数据库和 JDBC，性能较高。（JAVA only）
        * Proxy：异构场景；不同语言系统，只要有 MySQL 和 PostgreSQL 的驱动都可以连接使用。独立部署，对业务端透明；对业务系统侵入性小。
        * Sidecar
    * 提供的功能：标准化的数据分片、分布式事务、数据库治理
    * 引入成本比较：框架 < 中间件 < 分布式数据库/数据网格

* 数据迁移
    * 出发点：新系统与老数据
        * 异构数据迁移
        * 易出故障
    * 方式一：`全量`
        * 业务系统停机，dump 导出备份，新数据库上直接导入，重启新系统
        * 优：简单
        * 缺：停机时间随数据量上升，对业务影响较大
    * 方式二：`全量 + 增量`
        * 前提：所有库表都有时间戳，以及状态字段
        * 优：停机时间较短
        * 缺：数据库主库的读压力
    * 方式三：`全量 + 增量 + binlog`
        * 需要中间件支持：模拟从库，订阅读取 binlog，拿到数据，写入集群
            * 历史数据：历史 binlog，全量
            * 实时增量数据：主库正在执行的，增量
        * 优：不用额外寻找增量的时间点，也不需要去主库读取数据；平滑迁移，新老数据库可并行使用；可实现多线程断点续传，并发数据同步；可实现自定义复杂异构数据结构；可实现自动扩缩容。

    * 中间件工具：`ShardingSphere-Scaling`（模拟MySQL从库）
        * 支持数据全量和增量同步
        * 支持断点续传和多线程数据同步
        * 支持数据库异构复制和动态扩容
        * 可视化配置