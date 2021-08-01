# TOPIC Ⅹ-Ⅱ: PERFORMANCE & SQL OPTIMIZATION Ⅰ
## 5. 性能优化与关系数据库 MySQL：58'51''
### 性能优化
* 性能————综合性的复杂问题
    * 吞吐与延迟：系统对低延迟更敏感还是高吞吐更敏感。
    * 量化：制定业务指标指导入手方向。
    * 80/20 原则：先优化瓶颈问题，影响当前80%的性能。
        * 业务系统运行一定时间后，大部分问题会出在SQL数据库的库表结构、数据库本身性能、发送SQL命令三个方面。
    * 优化的`时机`
    * 脱离`场景`谈性能都是耍流氓！

* DB / SQL 优化：业务系统优化的的核心
    * 业务系统分类：计算密集型（CPU密集型；较少见），数据密集型
        * 常见业务系统：处于中间位置，偏向数据密集型。
    * 系统状态在数据库中存储
        * 业务处理本身无状态。
    * 业务系统
        * 规模扩大，数据量扩大：内部实现完全不一样。

### 关系数据库 MySQL
#### 关系数据库
* 以关系模型描述和表达数据库里的数据，以关系代数理论来操作和运算。
    * 表：一组关系的集合
    * 每行数据：关系的元组
    * 操作：关系本身的运算
    * E-R 图：对应数据库里表结构的关系
        * 实体 Entity：表
        * 属性：列
        * 关系 Relation：各表中记录的对应

* `数据库设计范式`————实体表的合理拆分：关系明确，冗余较少，表易维护
    * 1NF：关系R，当且仅当R中每个属性的值域只包含原子项（原子项=不可拆分项）。
    * 2NF：满足1NF，消除非主属性对码（码=主键；主键可由多列联合组成）的部分函数依赖。
    * 3NF：满足2NF，消除非主属性对码的传递函数依赖。
    * BCNF：满足3NF，消除非主属性对码的部分函数依赖和传递函数依赖。
    * 4NF：消除非平凡的多值依赖。
    * 5NF：消除不合适的连接依赖。

#### 数据库设计范式
* 1NF：消除重复数据
    * `每个列都是原子的`，不可拆分的基本数据项
* 2NF：消除部分依赖
    * 每个表都有 Primary Key
    * 所有列都与主键相关
    * 所有行都被主键唯一标识（`主键不重复`）
* 3NF：消除传递依赖
    * 从表只引用主表的主键
    * `所有列都与主键直接相关相关`
* BCNF：消除主键对码的部分依赖和传递依赖
    * 例，一张表（仓库+管理员+物品+数量） ==> 两张表（“仓库”[仓库+管理员]+“库存”[仓库+物品+数量]）
* 4NF，5NF：使用较少
    * 实际场景一：故意加一些冗余字段（常用字段），提高查询效率。
    * 实际场景二：不需要依赖主键去其他表查数据：从表也在当前表中。大部分查询都使用主表即可完成，提高查询效率。

#### `常见关系数据库`
##### 经典
* 开源DB：MySQL, PostgreSQL
* 三大商业DB：Oracle, SQL Server, DB2
##### 丰富的数据使用场景
* 内存DB：Redis（会丢数据）, VoltDB
* 图DB（指数级的扩散关系）：Neo4j, Nebula
* 时序DB：InfluxDB, openTSDB, Prometheus
* NoSQL DB：MongoDB, HBase, Cassandra, CouchDB
* 分布式DB：TiDB, CockroachDB, NuoDB, OpenGauss, OB, TDSQL

#### SQL 语言（Structured Query Language）
* 数据领域操作关系数据库的官方事实标准。
* 内部6个部分
    * `常用：DQL-查询, DML-操作, DDL-数据定义`
    * 其他：TCL-事务控制, DCL-数据控制, CCL-指针控制（游标操作）

* DQL
    * 例，保留字 SELECT, WHERE, HAVING, ORDER BY, GROUP BY
* DML   
    * 数据的增删改
    * 保留字 INSERT, UPDATE, DELETE
* DDL
    * 影响数据库中表结构的定义
    * 保留字 CREATE, ALTER, DROP
* DCL
    * 权限控制
    * 保留字 GRANT, REVOKE

#### MySQL 数据库
* MySQL：目前为止最成功的开源关系数据库。
* Sqlite：目前使用最广的装机量最大的开源关系数据库（嵌入式内库）。
* MySQL 的两个主流分支版本：`MySQL & MariaDB`
* 重要版本
    * 4.0：支持 InnoDB 插件，支持事务
        * InnoDB 后变为 MySQL 内的官方核心插件。
    * 5.6：历史使用最多
    * 5.7：目前使用最多（工作）
    * 8.0：最新、功能最完善（个人）
    * 5.6 vs 5.7：向下兼容，略有改动。
        * 5.7支持多主，引入了分布式的高可用（MGR高可用），加入了分区表 Partition 的功能，对 JSON 类型进行了丰富的支持，性能提升，修复了XA等问题。
    * 5.7 vs 8.0：兼容性上差异较大。
        * 8.0支持通用表达式（CTE），支持窗口函数，持久化参数（默认之前通过命令行修改的参数不会被持久化），自增列持久化，默认编码utf8mb4（真实的精确的UTF编码），DDL原子性，JSON增强（通过一些函数查询操作 JSON 的 KV），不再对 GROUP BY 默认隐式排序（大坑，数据库升级后查询结果出现差异）。

 
## 6. 深入数据库原理：36'19''
* MySQL 架构
    * 客户端：Connector
    * 服务端
        * 网络模块：`Connection Pool 连接池`（默认使用传统的BIO模式，因此连接的处理能力有限；对于MySQL来说长连接的`连接数`是一种宝贵的资源）
        * SQL Interface, Parser 解析器, Optimizer 对复杂SQL命令的优化, Caches 看是否命中缓存 & Buffers
        * 插件层（Pluggable Storage Engines，可插拔的存储引擎）：负责内存使用、索引、存储的管理；可选，可替换。例，MyISAM 经典引擎，InnoDB 常用引擎，归档引擎 Archive 等。
        * 文件系统：负责存储。
        * 管理工具。

* MySQL 存储
    * 独占模式（`默认`）：日志组文件（ib_logfile 和 ib_logfile1），表结构文件，`独占`表空间文件（*.ibd），字符集和排序规则文件，binlog二进制日志文件（记录DDL和DML操作），二进制日志索引文件。
    * 共享模式：通过 "innodb_file_per_table=OFF" 关闭每个表一个文件的模式；数据都在 “ibdata1”。

* MySQL 执行流程
    * `简化`：
        * client端发送SQL查询语句 --> server 先查看缓存 --> 
            * （`命中`&上一次执行到现在中间涉及的数据未经修改）返回结果。
            * （`未命中`） --> 解析器解析为AST（“抽象语法树”） --> 预处理器 --> 查询优化器（选择一个合适的执行计划） --> 查询执行引擎 --> 读取数据并执行计划 --> 引擎返回结果给调用方。
    * `详细`：
        * client端发送SQL更新语句 --> （进入`server层`） --> 连接器 --> 分析器 --> server 查看缓存 --> 
            * （`命中`）返回结果。
            * （`未命中`） --> 优化器 --> 执行器 --> （进入`引擎层`） --> 写 `undo log（用于事务回滚）` --> 查询记录所在目标页 --> 
                * 在内存中：直接拿到数据，更新内存。
                * 不在内存中：处理数据页和内存页之间的读写。
                *  --> 写 `redo log（用于事务提交）` --> 写 `binlog（用于主从复制）` --> 提交事务 --> 刷 redo log 盘，并让事务处于 commit-prepare 阶段 --> 刷 binlog 盘，并让事务处于 commit 阶段。

* MySQL 执行引擎（`存储引擎`）
    * MyISAM vs InnoDB：查询数据总量 SELECT count(*) FROM table 时，MyISAM 可以直接查到（有记录的数值，直接返回）。 

    存储引擎 | MyISAM | InnoDB | Memory | Archive  
    ---|---|---|---|---   
    存储限制 | 256TB | 64TB | 看内存大小 | 压缩在磁盘上
    事务支持 | x | √ | x | x
    索引支持 | √ | √ | √ | x
    锁的粒度 | 表锁 | 行锁 | 表锁 | 行锁
    数据压缩 | √ | x | x | √
    外键 | x | √ | x | x

* MySQL 对 SQL 执行顺序（先 --> 后）
    * `Stage 1：定位虚拟表`
        * FROM：找到表
        * ON：表之间的连接条件
        * JOIN：表之间的连接方式（左联/右联/内联/外联）
    * `Stage 2：虚拟表的筛选过滤`
        * WHERE：直接条件
        * GROUP BY：分组
        * HAVING + 聚合函数：条件
    * `Stage 3：选择展示的具体数据`
        * SELECT：选取字段
        * ORDER BY：行排序
        * LIMIT：具体条数限制
    * 注：以上顺序不固定，查询优化器会进行调整优化。

* MySQL 索引原理
    * 数据`按页分块`
    * InnoDB 使用 `B+ 树或哈希`实现索引
        * B+ 树：默认数据存储结构按主键索引的结构存储。`叶节点存储数据块（多条数据记录；数据块之间存在双向指针）`，其他结点存储索引。
        * 当前使用的数据前后的数据极大可能马上被使用，因此较接近的多条数据成为一块。块作为缓存，一次读取、操作磁盘。
    * Q：为什么对于 MySQl 的数据库，单表数据一般不超过2000万？
    * A：一般认为`三层`的索引结构是正常情况下性能较好的极限值。三层的B+树索引结构最多容纳的数据量为2100万左右。

* MySQL 数据库操作演示
    * 安装：安装文件 / Docker
    * 官方操作工具：MySQL-WorkBench
    * 数据库的逻辑表和数据库文件夹下的物理文件一一对应！
    * 常用操作
        * 创建数据库：`create database XXX;` / `create schema XXX;`
        * 查看配置：（例）show variables like '%dir%'; / show variables like '%port%'; / show variables like '%version%';
        * 查看建表语句：（例）show create table test1;
        * 查看表中有多少列：（例）show columns from test1;
        * 插入新数据：（例）`insert` into test1(id) values(30); / insert into test1 values(31)(32)(33);
        * 删除：（例）`delete` from test1 where id = 32;
        * 更新：（例）`update` test1 set id = 32 where id = 33;


## 7. MySQL 配置优化与数据库设计优化：38'31''
### MySQL 配置优化
* 查看参数配置（格式和内容相同）
    * Linux / Mac：my.cnf 文件（在安装文件夹下，或 etc/mysql 文件夹下）
        * 可以通过命令制定位置：mysqld --default-files <path>
    * Windows: my.ini 
    * 内容：两节配置
    ```ini
    [mysqld]
    server

    [mysql]
    client
    ```
    * 查看所有配置
    ```mysql
    show variables;
    show variables like '%innodb%';
    ```
    * 两类配置：全局的配置，仅针对当前 MySQL 会话的配置。
    ```mysql
    show variables like '%innodb%';
    show global variables like '%innodb%';
    ```
    * 访问配置变量（例，变量last_insert_id）
    ```mysql
    select @@last_insert_id;
    ```
    * 设置变量：MySQL8 以上的版本才加入持久化，重启之前的设置有效。
    ```mysql
    set last_insert_id=<value>;
    set global.last_insert_id=<value>;
    ```

* 参数配置优化
    * `连接请求`的变量（有默认值）
        * max_connections 最大连接数
        * back_log 半连接状态的连接数
        * wait_timeout 等待超时 & interactive_timeout 交互状态下的等待超时

    * `缓冲区`变量
        * key_buffer_size 索引内存中的buffer大小（影响索引操作的速度）
        * query_cache_size 负责server层的、针对查询结果的缓存（MySQL8 中无；对数据修改较为频繁的场景中，该缓存经常失效，效率不高，简化 MySQL 的设计实现）
        * max_connect_errors
        * sort_buffer_size=1M 排序缓冲区大小（重要；若很小值，则排序需要借助磁盘实现，影响效率）
        * join_buffer_size=2M 连接表缓冲区大小（重要）
        * max_allowed_packet=32M 发送给 MySQL server 的最大数据包大小
        * thread_cache_size=300

    * `配置 InnoDB` 的几个变量
        * `innodb_buffer_pool_size`=128M 内存缓冲区大小（重要！key查询的各种缓存都会使用该区域）
        * innodb_flush_log_at_trx_commit 
        * innodb_thread_concurrenct=0
        * innodb_log_buffer_size
        * innodb_log_file_size=50M
        * innodb_log_files_in_group=3
        * read_buffer_size=1M 读取（重要！）
        * read_rnd_buffer_size=16M 随机读取（重要！）
        * bulk_insert_buffer_size=64M 批量插入（重要！）
        * binary log 

### MySQL 数据库设计优化
#### 【♥】`最佳实践`
* 1. 恰当选择引擎 
    * 不需要事务，数据操作量大————MyISAM
    * 强事务————InnoDB
    * 数据量小，不需要持久化————Memory
    * 数据归档————Archive；Toku（有大量重复数据时，压缩效率超高，能够大大减少网络数据流量）

* 2. 库表命名
    * `有意义的命名`
    * 数据量较小：用前缀表示不同模块
    * 数据量较大：用模块名作为数据库的名字
    * 字段名：实际操作 / 参数类型前缀

* 3. 合理拆分宽表
    * 提高执行效率
    * 利用`范式`

* 4. 选择恰当的数据类型 
    * 原则：`明确，尽量小`。
    * 例，char 定长，varchar 变长。
    * 一般情况下，不建议使用 text/blob/clob 类型；影响每个数据块能容纳的数据条数，性能明显下降。使用 blob/clob 类型时，需要对数据库进行两次操作（一次存储其他列，一次用update方式对使用该类型的列打开一个流再提交）。
    * 文件/图片存入数据库？`优化`：直接存成文件，放在应用服务器的磁盘中，或分布式文件系统中；数据库字段放置文件路径/分布式文件系统例的URL。
    * 时间日期：（`一致性`要求严格）数据库的时间函数 / （一致性要求不很严格）应用服务器的时间。注意避免时区产生的问题。
    * `数值精度`：尽量避免使用对精度要求较高的数值。如果碰到，使用`字符串`的方式表示，或变相使用科学计数法表示。

* 5. 是否使用外键、触发器？ 
    * 尽量不使用。

* 6. 唯一约束和索引的关系？
    * 数据库默认会对唯一约束产生索引。

* 7. 是否可以冗余字段？
    * 可以适当冗余；有时能提高查询效率。

* 8. 是否使用游标、变量、视图、自定义函数、存储过程？
    * 不建议使用，有可能没有代码执行的效率高，且很难移植。

* 9. 自增主键的使用问题?
    * 数据量不大：建议使用。
    * 数据量很大：不适用。

* 10. 能够在线修改表结构？
    * 尽量不要，会导致直接锁表。
    * 可以在系统压力较小/停机维护期间修改。

* 11. 逻辑删除 vs 物理删除
    * 建议逻辑删除，标识位。利于数据的跟踪审计。

* 12. 要不要加 create_time, update_time 等时间戳?
    * 建议给关键表全加。
    * 对数据迁移有很大作用。

* 13. 数据库碎片问题
    * 定期压缩表空间文件。
    * 可以在系统压力较小/停机维护期间压缩。

* 14. 如何快速导入导出、备份数据
    * 导出：先查询，再存储————需要锁表（确保数据对齐）；在系统压力较小/停机维护期间
    * 导入：代码，脚本，load data 文件；迁移工具。
    * 经验：先导入所有数据，再重新建立所有的索引和约束。
        * 原因：提高效率，减小数据移动次数。

