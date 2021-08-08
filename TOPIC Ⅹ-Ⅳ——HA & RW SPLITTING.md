# TOPIC Ⅹ-Ⅳ: HA & RW SPLITTING

## 1. 从单机到集群 / MySQL 主从复制：62'38''

### 从单机到集群
* 单机 SQL 新需求：数据量增大，读写并发增加，系统可用性要求提升
* 单机 SQL 面临的问题
    * 容量有限，难扩容
    * 单个数据库的读写压力，特别是 QPS 过大，和分析类需求，占用的资源会影响业务事务
    * 可用性不足，宕机问题

* 单机MySQL技术演进
    * 读写压力（特别是读的压力影响写）————`多机集群`（一主多从），主从复制（一致性）+读写分离
    * 高可用性————`故障转移`，主从切换（复制关系改变）
    * 容量问题————`数据库拆分`，分库分表（垂直拆分，按业务；水平拆分，数据主键ID取模等方式），将整个节点的数据量变小
    * 分库分表导致的一致性问题————`分布式事务`，XA/柔性事务
        * 分布式事务：保证多个不同的数据节点间各个独立的本地事务的操作要么全部写入多个数据库，要么全部未写入回滚。
        * XA 事务：强一致性；`数据库底层`需支持 XA 协议，外层封装使用。
        * 柔性事务：弱一致性/最终一致性；`业务侧`建立的分布式协调机制，与数据库无关。

### MySQL 主从复制
* 核心
    * `主库写 binlog`
        * binlog 格式：
            * ROW：记录影响到的行数据；日志体量大；记录明确清晰，适合对一致性要求较高的场景。
            * Statement：仅记录操作的SQL语句；日志精简，不详细。
            * Mixed：混合前两种日志，根据操作，数据库服务器自动选择合适的记录方式。
        * 本地落盘：增删改的事务
        * 从库`订阅`主库，不断拉取 binlog 数据
        * 查看 binlog 内容（先找到数据文件夹）中相关操作
        ```mysql
        show variables like '%datadir%';
        mysqlbinlog -vv mysql-bin.000002;
        ```
    * `从库 relay log`
        * I/O 线程：从主库拉取的数据本地化成 relay log
        * SQL 线程：根据 relay log 顺序和指令执行 SQL 线程

* 原理
    * `异步复制`
        * 主库的事务在提交之前，先写一个 binlog，并分发给从库。从库接收后转化成本地的 relay log 并执行；本地也生成 binlog，再提交事务。
        * 问题：网络故障或宕机，会造成主从`数据不一致`；因完全异步，主库对从库的数据拉取执行情况不可知。
    * `半同步复制`
        * 插件默认未开启（需手动开启配置使用）
        * 保证 source 和 replica 最终一致
        * 主库的事务在提交之前，先写一个 binlog，并分发给从库；主库`等待至少一个从库`（不完全异步）确认已接受 binlog 数据，才将事务提交到数据库。
        * 可靠性较纯异步较好
        * 主库`退化`到传统的异步复制：当超过一定时间，主库没有收到从库的确认信息。
    * `组复制` MGR
        * 所有节点对等，不存在主从，支持多节点写入数据（提升了集群的并发处理能力）
        * 基于分布式 Paxos 协议实现组复制，保证分布式数据一致性
        * 单主模式/多主模式
        * 问题：都写，节点冲突
        * 一致性措施：binlog 之前的`验证阶段`，协调多节点冲突；先拿到资源的节点去处理。

* 实战
    * Step 1——新建两个文件夹：mysql1, mysql2；分别放入 my.cnf 配置文件：  
    mysql1/my.cnf
    ```bash
    [mysqld]
    bind-address = 127.0.0.1
    default_authentication_plugin=mysql_native_password
    port = 3316
    server-id = 1
    datadir = 数据文件夹./data
    socket = 随便指定

    sql-mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
    log-bin=mysql-bin
    binlog-format=Row
    ```

    mysql2/my.cnf
    ```bash
    [mysqld]
    bind-address = 127.0.0.1
    default_authentication_plugin=mysql_native_password
    port = 3326
    server-id = 2
    datadir = 数据文件夹./data
    socket = 随便指定（和mysql1的不同）

    sql-mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
    log-bin=mysql-bin
    binlog-format=Row
    ```
    * Step 2——使用配置文件 my.ini (Windows) 或 my.cnf (Linux/Mac) 进行数据库的初始化：
    ```bash
    mysqld --defaults-file=my.ini --initialize-insecure 
    ```
    非安全的初始化，即 root 密码可以为空
    * 查看 data 文件夹内容，确认初始化是否成功
    * Step 3——连接数据库（用命令 `show variables like '%port%';` 确认连接的数据库）：
    ```bash
    mysqld -h 127.0.0.1 -P 3316 -uroot
    ```
    * Step 4——配置主节点
        * 创建账号，进行复制工作（创建，授权，权限刷新，查看主库状态）
        ```bash
        mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '123456';
        Query OK, 0 rows affected (0.11 sec)

        mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
        Query OK, 0 rows affected (0.12 sec)

        mysql> flush privileges;
        Query OK, 0 rows affected (0.10 sec)
        ```
        * 查看主库状态：binlog 文件是 mysql-bin.000003，当前需要同步的偏移量是305.
        ```bash
        mysql> show master status;
        +------------------+----------+--------------+------------------+-------------------+
        | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
        +------------------+----------+--------------+------------------+-------------------+
        | mysql-bin.000003 |      305 |              |                  |                   |
        +------------------+----------+--------------+------------------+-------------------+
        1 row in set (0.00 sec)
        ```
        * 查看当前数据库
        ```bash
        mysql> show schemas;
        ```
        * 新建数据库
        ```bash
        mysql> create schema db;
        ```
    * Step 5——配置从节点
        * mysql命令登录到从节点：mysql -uroot -P3316
        * 配置（指定MASTER的IP和端口，binlog名，登录账号信息，偏移量）
        ```bash
        mysql> CHANGE MASTER TO
            MASTER_HOST='localhost',  
            MASTER_PORT = 3316,
            MASTER_USER='repl',      
            MASTER_PASSWORD='123456',   
            MASTER_LOG_FILE='mysql-bin.000003',
            MASTER_LOG_POS=305;
            
            //MASTER_AUTO_POSITION = 1;
        ```
        * 新建数据库
        ```bash
        mysql> create schema db;
        ```
        * 验证：查看当前数据库是否与主库一致
        ```bash
        mysql> show schemas;
        ```
    * Step 6——操作
        * 在主节点，创建新表，插入数据
        ```bash
        mysql> use db;
        mysql> show tables;
        mysql> create table t1(id int);
        mysql> insert into t1(id) values(1),(2);
        ```
        * 在从节点，发现主库信息未同步；查看 slave 状态，发现是验证问题。
        ```bash
        mysql> use db;
        mysql> show slave status;
        ```
        * 解决方案一：在主库从库配置文件中增加 "default_authentication_plugin=mysql_native_password" 后重启主库从库。
        * 解决方案二：修改当前认证插件，修改加密方式；然后刷新权限。
        ```bash
        mysql> select host,user,plugin from mysql.user;
        mysql> alter user 'repl'@'%' IDENTIFIED with mysql_native_password by '123456';
        mysql> flush privileges;
        ```
        * 重启从库；验证是否主从复制成功。
        ```bash
        mysql> drop schema db;
        mysql> start slave;
        mysql> show schemas;
        mysql> use db;
        mysql> show tables;
        ```
        * 在主节点插入新数据；检查从库，数据条目未更新。（原因：主库上修改用户权限的操作也被同步到了从库，从库 relay 时失败）
        ```bash
        mysql> insert into t1(id) values(4),(8);
        ```
        * 在主节点操作：
        ```bash
        mysql> drop schema db;
        mysql> show master status;
        ```
        * 在从节点重新开始同步
        ```bash
        mysql> drop schema db;
        mysql> stop slave;
        mysql> CHANGE MASTER TO
            MASTER_HOST='localhost',  
            MASTER_PORT = 3316,
            MASTER_USER='repl',      
            MASTER_PASSWORD='123456',   
            MASTER_LOG_FILE='mysql-bin.000003',
            MASTER_LOG_POS=2390;
        mysql> start slave;
        mysql> show slave status;
        ```
        * 在主节点新建表：
        ```bash
        mysql> create schema db;
        mysql> use db;
        mysql> create table t1(id int);
        ```
        * 在从节点验证同步成功，自动一致。
        ```bash
        mysql> show schemas;
        mysql> use db;
        mysql> show tables;
        ```
        * `在主节点上的操作不想同步到从库：暂时关闭 binlog`，再操作。
        ```bash
        mysql> set SQL_LOG_BIN=0;
        mysql> create schema dbx;
        mysql> set SQL_LOG_BIN=1;
        ```

* 主从复制的局限性
    * 主从延迟问题
        * 数据不一致：从库是旧数据
    * 应用侧需要配合读写分离框架
        * 应用侧：一般只配置了一个数据源，无法让多个数据库平坦所有的读写压力
        * 应用侧：需要配合读写分离框架
    * 不解决高可用问题
        * 需要额外的机制支持



## 2. MySQL 读写分离与高可用：69'36''

### MySQL 读写分离
* 主从复制在业务系统例的应用
    * 配置多个数据源（集群，一主三从，从读主写），实现读写分离

* `动态切换数据源版本1.0`
    * [基于 Spring / Spring Boot，配置多个数据源](week5)   
    * 根据具体的service方法是否会操作数据，注入不同的数据源（注解/参数）
    * （改进一）简化自动切换数据源：基于操作 AbstractRoutingDataSource 和自定义注解 readOnly 等
        * 基础设施 AbstractRoutingDataSource：基于抽象数据源自定义一个数据源，其他实际的数据源创建在虚拟数据源内部；外层使用抽象数据源。
        * 根据业务条件或自定义标记：自动切换数据源。
    * （改进二）支持配置多个从库。
    * （改进三）支持多个从库的负载均衡：路由算法。灵活使用从库，提高效率。

* `数据库框架版本2.0`
    * 版本1.0的问题
        * 切换数据源的`侵入性问题`：需要在代码层面做很多工作。
            * 期望组件自动识别当前代码应该走主库还是从库，减少侵入，只需配置读写分离规则。
        * 降低侵入性会导致“写完读”数据不一致问题。
    * 改进方式————`ShardingSphere-jdbc` 的 Master-Slave 功能
        * SQL 解析和事务管理，自动实现读写分离
            * select：走从库
            * update, delete, insert：走主库
        * 解决“写完读”不一致问题
            * 只要遇到一个写操作，之后`同一事务内部`其他操作全都走主库。
    * 实战：使用ShardingSphere-jdbc 5.0.0-alpha 实现读写分离配置

* `数据库中间件版本3.0`
    * 版本2.0的问题
        * 对业务系统仍有侵入：配置数据源 & 添加读写分离规则 & 改写复杂SQL & ....
        * 对旧系统改造不友好
            * solution：多个读写分离、主从复制的数据库作为一个单独的虚拟数据库使用；仅修改数据库连接字符串（连接指向）。
    * 改进方式————`MyCat / ShardingSphere-Proxy` 的 Master-Slave 功能
        * 部署一个中间件：读写分离、主从复制的规则配置在中间件
        * 中间件模拟一个 MySQL 服务器：对业务系统几乎零侵入
    * 实战：使用ShardingSphere-proxy 5.0.0-alpha 实现读写分离配置

### MySQL 高可用
* 目标
    * 读写分离：提升数据库集群读的能力。
    * 故障转移：提供 `failover 能力`。
        * 数据库集群：主库宕机，主从自动切换
        * 业务侧：连接池有心跳检测和自动重连机制
        * 好处：整体自动从故障中恢复，无需人工干预，正常提供服务 
    * 容灾角度
        * 热备：出了问题，大家都能提供服务，平摊压力
        * 冷备：备份在顶替宕机主库时承担压力，平时没用

* 定义
    * 系统持续可用的时间，更少的不可用服务时间
    * 一般用SLA/SLO衡量：`SLA = 可用时间/总时间`
        * 两个9：8760h * 1% = 87.6h （全年宕机时间）
        * 三个9：8760h * 0.1% = 8.76h （全年宕机时间）
        * 四个9：8760h * 0.01% = 0.876h = 52.6min （全年宕机时间）
        * 每提升一个9就是质的飞跃，成本很高。
        * Q：99.95% 小于3.5个9：-log_10(1-99.95%) = 3 + log_10(5) ≈ 3.3

* 常见策略
    * 多个实例不在一个服务器/机架上：防止物理机宕机对集群的影响
    * 跨机房和可用区部署：防止机房故障
    * 两地三中心、三地五中心容灾高可用方案（中心=机房）
    
* MySQL 高可用方案0：主从手动切换
    * 操作：主节点宕机，重新配置从变主；修改应用系统的数据源配置；重启系统。
    * 可能问题
        * 数据不一致
        * 需要`人工干预`
        * 代码和配置的侵入性很强

* MySQL 高可用方案1：`主从手动切换`
    * 在数据库和应用系统之间加一个中间层；数据库除了问题，只需调整中间层的配置。
    * 操作：
        * 中间层用 `LVS四层代理+Keepalived` 实现多节点的自动探活 + 请求路由流量分发；
        * 应用系统侧配置 VIP 或 DNS，实现配置不变更；无需重启应用系统。
    * 可能问题：
        * 手工处理主从切换：手动调整 VIP 或 DNS
        * 中间层：大量的配置和脚本定义

* MySQL 高可用方案2：`MHA (Master High Availability)`
    * 成熟方案：一套作为MySQL高可用环境下故障切换和主从提升的高可用软件。
    * 优势
        * 基于Perl语言开发，一般30秒内主从切换
        * 主从切换时，能直接访问主节点的数据和日志，判断是否与从库一致。若不一致，自动同步差异数据到从库，再将从库提升为主库。彻底解决数据丢失问题。
    * 可能问题：
        * 需要配置SSH信息（比对和拷贝文件）
        * 至少3台服务器 
        
* MySQL 高可用方案0~2：MySQL 外部

* MySQL 高可用方案3：`MGR (MySQL Group Replication)`
    * 在 MySQL 内部实现数据可靠性复制，主从切换也在内部实现，`无需外部干预`
    * 操作：主节点宕机，将自动根据一致性协议选举某个从变为主。
        * 解决了数据不一致问题
    * 优势：无需人工干预，基于组复制，保证数据一致性。
    * 可能问题：
        * 外部（应用程序或中间层）获得状态变更：需要读取数据库中`记录主从状态变化的表`。
        * 外部需使用 LVS/VIP 配置（物理上还是单独的多个数据库，仍需中间层） 
    * MGR 特点
        * 高一致性（基于分布式 Paxos 协议实现组复制；读写基于有最新数据的副本）
        * 高容错性（自动检测机制，只要超过半数的节点不宕机，整体即可继续工作；超过半数的节点不可用时，有内置的`防脑裂保护机制`强制不对外提供服务）
        * 高扩展性（节点的增删会自动更新组成员信息；新节点加入后，自动从其他时间节点同步`增量数据`，直到与其他数据一致）
        * 高灵活性（提供单主模式和多主模式）
            * 单主模式：主库宕机后能自动选择主；所有写入都在主节点进行。
            * 多主模式：支持多节点写入（无主从之分，多写多活）。
    * 适用场景
        * 弹性复制
        * 高可用的分片

* MySQL 高可用方案4：`MySQL Cluster`
    * 完整的数据库层高可用方案
        * 客户端通过官方工具中间层接入所有的多个数据库副本
    * MySQL InnoDB Cluster 高可用框架
        * 组成一：MGR 核心组件
            * 提供DB的扩展、自动故障迁移：复制加高可用的内核
        * 组成二：`MySQL Router`（作为代理，上接应用程序，下接多个基于MGR的从库）
            * 轻量级中间件，提供`负载均衡`和`应用程序连接目标的故障转移`
            * 专为 MGR 量身打造：`通过 MySQL Router 和 MySQL Shell，用户可以利用 MGR 实现完整的、数据库底层的解决方案。`
            * 其上配置了读写分离、高可用规则。
        * 组成三：`MySQL Shell` (Cluster Admin 管理控制台)
            * 新的、统一的 MySQL 客户端：对MySQL执行数据操作和管理，轻松配置管理 InnoDB 集群。 
            * 多种接口模式
            * 可设置群组复制及 Router
            * 支持通过JS, Python, SQL 对关系型数据模式和文档行数据模式进行操作

* MySQL 高可用方案5：`Orchestractor` 编排器
    * 是什么？
        * 一款 MySQL `高可用`和`复制拓扑管理工具`。
        * 基于GO语言开发，不仅实现了 MySQL 的高可用，还实现了中间件本身的高可用。
        * 支持复制拓扑结构的调整，自动故障转移，手动主从切换。
        * `后端`存储元数据 + `Web界面`展示MySQL复制的拓扑关系及状态&更改MySQL实例的复制关系和部分配置信息
        * 提供命令行和 API 接口：便于运维管理。
    * 特点  
        * `自动发现 MySQL 的复制拓扑关系`，并在 Web 界面图形化展示
        * `重构复制关系`，可以在 Web 界面拖图进行复制拓扑关系变更
        * 检测主节点异常，可自动/手动恢复，通过 Hooks 进行自定义脚本灵活配置
        * 支持命令行和 Web 界面管理复制
    * 优势
        * 直接在 UI 界面内通过拖拽改变主从关系。

  
    