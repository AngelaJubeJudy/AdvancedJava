# TOPIC Ⅹ-Ⅲ: PERFORMANCE & SQL OPTIMIZATION Ⅱ

## 1. MySQL 事务与锁：56'15''
* 事务：client端和数据库会话过程中执行的一系列操作。
* `事务可靠性模型：ACID`
    * Atomicity 原子性：一次事务中的一批操作全部成功/失败。
    * Consistency 一致性：跨表、跨行、跨事务，业务意义上的匹配关系一直一致。
    * Isolation 隔离性：可见性，多个并发事务不相互干扰。4种隔离级别。
    * Durability 持久性：提交成功，持久化到磁盘中，不影响数据的正确性。
    * 平衡思考：性能 vs 可靠性

* InnoDB：支持事务的引擎
    * 常见实现：双写缓冲区，故障恢复，操作系统，fsync()，磁盘存储，缓存，UPS，网络，备份策略等

* 锁
    * 共享锁（S），排他锁（X）
    * `表级锁`
        * 意向锁：表明事务之后要进行哪种类型的锁定；“上锁之前需要先上意向锁”
            * 共享意向锁（IS）
            * 排他意向锁（IX）
            * Insert 意向锁
            * 命令：查看当前数据库上有哪些锁
            ```mysql
            SHOW ENGINE INNODB STATUS;
            ```
            * `锁类型的兼容性（X, IX, S, IS）`：X锁与所有锁都冲突，IS与除X外的锁都兼容；S和S、IS兼容，IX和IX兼容。
        * 其他表级锁
            * 自增锁（AUTO-IN）：为了并发操作ID不冲突，给内存里的自增加锁。
            * LOCK TABLES/DDL：在执行DDL或dump命令时显式上锁全表；后续 UNLOCK 执行解锁

    * `行级锁`
        * 记录锁（Record）：始终锁定`索引记录`，查询一条具体语句时上的锁。 
        * 间隙锁（Gap）：锁住一个`范围`（此处范围针对主键描述） 
        * 临键锁（Next-Key）：记录锁（最后的一条记录上了行锁）+间隙锁；可锁定表中不存在的记录
        * 谓词锁（Predicate）：空间索引

    * 死锁
        * 阻塞与互相等待
        * 增删改、锁定读
        * 死锁检测与自动回滚
        * 锁粒度与程序设计
        * solution 1：（主动）强制某任务失败，解除环形互相等待
        * solution 2：（被动）所有事务加超时时间
        * 建议：设计多并发事务对数据库的操作时，尽量降低锁的粒度；尽量把业务隔离开

* MySQL 事务
    * `隔离级别`（数据库的基本性能；涉及数据库的并发性、可靠性、一致性、可重复性）
        * `读未提交 READ UNCOMMITTED`：事务未提交时更改的数据对于其他事务都可见。
            * 不保证一致性 => 用的少！
            * 问题：dirty read 脏读（脏数据不确定，随时可能不存在）, phantom 幻读（每次读取的数据记录数不一致），不可重复读（每次读取的数据中同一条记录前后读的值不一致）
            * 使用场景：对数据一致性要求低，对性能要求高（可容忍并发事务间的影响）
            * 锁————以非锁定方式执行

        * `读已提交 READ COMMITTED`：只有提交的数据其他线程才能看到。
            * 每次查询都会设置和读取自己的`新快照`
            * 仅支持`基于行的 binlog`
            * UPDATE 优化：Semi-Consistent Read 半一致性读
            * 不加锁时的问题：幻读（不加间隙锁，不锁定记录之间的间隔），不可重复读
            * 锁————锁定索引记录

        * 可重复读 REPEATABLE READ
            * InnoDB 的默认隔离级别；使用了MVCC技术（多版本并发控制）。
            * 在事务启动第一次操作时创建一个版本的快照，之后事务其他操作看到的数据都基于该快照。（解决不可重复读问题）
            * 锁：使用唯一索引的唯一查询条件时，只锁定记录，不锁定间隙；锁定扫描到的索引范围，`加间隙锁/临键锁`阻止其他会话，保护当前范围。（解决幻读问题）

        * 可串行化 SERIALIZABLE （串行处理，性能最低）
            * 最严格的级别
            * 资源损耗最大，无法完全利用数据库多 CPU 的并发性能。

        * 设置隔离范围：全局，会话
        * 注：常见数据库（DB2, Oracle, SQL Server）默认的隔离级别都是`RC`，读已提交；MySQL默认的隔离级别是`RR`，可重复读。
        * 脏读、幻读、不可重复读常见解决方案：加间隙锁/临键锁，提高隔离级别
        * 事务隔离：数据库的基础特征。

    * 日志
        * `undo log` 撤销日志（保证原子性）
            * 用途：回滚，一致性读，故障恢复
            * 记录正向SQL操作的反向操作
        * `redo log` 重做日志 （保证持久性）
            * 底层数据块不是每次事务提交完都持久化
            * 记录事务对数据页做的修改
            * WAL (Write-Ahead Logging) 技术：顺序地、追加式写文件。
            * 文件：日志文件ib_logfile0 / ib_logfile1，参数innodb_lg_buffer_size，async()对磁盘的强刷。

    * MVCC (Multi-Verison Concurrency Control)
        * 目标：保证事务在执行时看到的数据快照的一致性；“快照机制”
        * 实现：在表中每行数据上都添加了3个隐藏列；DB_TRX_ID 事务ID, DB_ROLL_PTR 回滚指针（指向当前记录在undo log中记录的位置）, DB_ROW_ID 标识行 
        * 比较DB_TRX_ID 事务ID，比当前大则说明该行数据是在当前事务启动之后修改并提交上来的，不应该看到；小于等于则现在可见。
        * 事务链表：（一种优化）维护当前活动的、未提交的事务放入内存。

* Demo
    * 查看 InnoDB 当前状态
    ```mysql
    SHOW ENGINE INNODB STATUS;
    ```
    * 行锁
        * 关闭自动事务（MySQL默认使用了自动事务，每执行一条SQL都是一个事务）
        ```mysql
        set autocommit = 0;
        ```
        * 对一个事务上一个X锁，再查看 InnoDB 当前状态（事务ID加一；当前事务上有一个行锁，“1 row lock”；当前事务不可见的事务ID大于等于当前事务ID）
        ```mysql
        select * from test1 where id=5 for update;
        ```
        * 新开一个事务，被锁，再查看 InnoDB 当前状态（lock_mode X locks rec but not gap waiting）
        ```mysql
        update test1 set id=4 where id=5;
        ```
        * 回滚
        ```mysql
        rollback;
        ```
    * Gap 锁
        * 针对一条不存在的记录（id=3），再查看 InnoDB 当前状态（lock_mode X locks gap before rec insert intention waiting）
        ```mysql
        select * from test1 where id=3 for update;
        insert into test1 values(3);
        rollback;
        ```
        * 在锁某条中间不存在的记录时，会把区间上锁，但区间两边都是开区间，可以被其他事务操作。
        * 范围操作，查看锁（被命中30，“X, GAP, INSERT_INTENTION”；未被命中28和31，“X, GAP”）；可能对性能产生很大影响。
        ```mysql
        select * from test1 where id>25 for update;
        insert into test1 values(28);
        insert into test1 values(31);
        rollback;
        ```
    * 排查问题：查看 `performance_schema.data_locks` 表，查看当前锁的情况 (IX; X, GAP; X, REC_NOT_GAP 等)
    ```mysql
    select * from performance_schema.data_locks;
    ```


## 2. DB 与 MySQL 优化：58'55''
* 开篇思考：用一个SQL，实现对ID小于5的数据倒排，对ID大于5的数据顺排。
    * ORDER_BY 之后可以加函数
    ```mysql
    select * 
    from dbsql.user_info
    where id < 10
    order_by if (id<5, -id, id);
    ```
    * 掌握某些工具和技巧，简化并快速解决实际中的复杂问题。

### SQL 优化
* 如何发现需要优化的SQL————“发现问题”
* SQL 优化方法————“办法”
* SQL 优化的好处————“效果”

* 模拟需求：版本一
    * 需求一：用户信息表，存储基本用户信息。
        * 表名加前缀“-t”，字段名加前缀“-f”
        * 设置主键
        * 设置引擎，字符集（`utf8mb4，真正的UTF-8`）
        ```mysql
        CREATE TABLE 't_user_info'{
            'f_id'  BIGINT(20)  NOT NULL AUTO_INCREMENT  COMMIT '自增ID',
            'f_username'  VARCHAR(20)  NOT NULL DEFAULT ''  COMMIT '用户名',
            'f_idno'  CHAR(19)  NOT NULL DEFAULT ''  COMMIT '身份证号',
            'f_age'  SMALLINT(11)  NOT NULL DEFAULT 0  COMMIT '年龄',
            'f_gender'  TINYINT(11)  NOT NULL DEFAULT 0  COMMIT '性别',
            PRIMARY KEY('f_id')
        } ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMIT = '用户信息';
        ```

    * 需求二：根据身份证号查详情（唯一索引）；根据用户名密码登录（验证）；统计当日新增用户个数。

    * 需求三：用户表增长100万，CPU升高，查询变慢；定位问题。
        * 针对`慢查询`，增加索引
        ```mysql
        alter table table_name add index index_name(column_list);
        ```

* 【♥】结合需求的实战思考
    * `数据类型`是否越大越好？——字节数别浪费（空间损耗影响性能，复杂的业务场景会放大这种不必要的浪费）
        * 数字：TINYINT, SMALLINT, MEDIUMINT, INT, BIGINT, DECIMAL, FLOAT, DOUBLE
        * 字符串: CHAR, VARCHAR, ENUM, SET, BLOB, TEXT
        * 日期：YEAR, DATE, TIME, DATETIME, IMESTAMP
        * solution：相对保守地估计，再加一点余量。

    * `存储引擎`的选择
        * InnoDB：默认引擎，绝大多数情况下的选择
        * ToKuDB：针对归档数据，有高压缩比

    * DBA 指导手册 / 数据库设计规范

    * 简单的 SQL
        * 避免`隐式转换`：类型不兼容的，如 VARCHAR 类型的字段被赋值了整型值，SQL不会报错。因为 SQL 中存在数值类型和字符型的隐式转换。通过 “show warnings;” 命令可以查看隐式转换警告。问题在于此时索引的条件失效，会产生意想不到的查询结果。另外，因隐式转换不走索引，对性能会产生影响，降低效率。

    * 定位问题
        * `慢查询日志`：（重点查看以下）
            * Rank，哪些SQL语句执行最慢（Rank=1 的最慢）
            * Response time，处理时间
            * Row examine，处理的数据记录数
            * min，最少执行时间
        * 应用和运维的`监控`
            * 关注：采集间隔，计算指标，数据来源
            * DBA 分析

    * 索引的类型（`B-Tree / B+Tree更适合索引`）
        * Hash：适合`内存`中的索引。
            * key取哈希值，散列到桶中。
        * B-Tree / B+Tree：按块存储数据，适合`磁盘`中的索引。
            * 每一块：键，primary key；指针，存储子节点地址信息；数据，除主键外的数据。
            * B-Tree 树的优化：B+Tree 树。（两大改进）所有数据放在叶节点，父节点存储的key和指针数量变多，优化了层数；相邻数据块用双向指针连接，减少回溯父节点的过程。

    * 为什么`主键单调递增`？
        * 避免出现“页分裂”问题：在中间插入数据，会导致当前块分裂为多个块，B-Tree 树结构变动较大，性能变差。所以主键单调递增，在尾部追加新数据。

    * 为什么主键长度不能过大？
        * 影响每个数据块能容纳的数据条数

    * （查询速度）按主键 vs 按非主键
        * 都是按索引，但按主键更快
        * 聚集索引 vs 二级索引
        * `B+Tree树默认按主键顺序索引`，所有数据的顺序关系就是主键的顺序关系；“聚集索引”。
        * 按非主键创建的索引：单独的索引文件；“二级索引”，不直接对应数据。通过非主键的索引查询一条记录，先在索引中找到主键ID，然后使用主键ID查询记录；多了一步回表。
        * Q：使用哪些列作为索引更好？
        * A：`字段选择性` = DISTINCT(col)/count(*)：字段值的重复性。重复性越低，选择性越好，越适合作为索引；等于1时最好。

    * 组合索引的构建
        * 问题：索引冗余
        * 例，根据“`最左原则`”，索引 (username, name, age) 会覆盖 (username) 和 (username, name) 两个索引，后两个冗余。
        * 2条原则：长索引可以覆盖短索引，短索引冗余；有唯一约束的，和其他列构建组合索引，产生冗余。

    * 修改表结构的危害
        * DDL：创建/删除表，修改表结构。
        * 加索引：修改表结构的操作，涉及整个表的索引的重建，且过程中会锁表，影响主从同步（增加延时），占用数据库资源。

    * 数据量
        * 初期设计：考虑系统增量，合理使用字段类型
        * 新增字段：增加额外的从表（用主表主键ID关联）
        * 增加索引：在停机维护阶段进行

* 【♥】总结
    * 写入优化
        * `大批量数据的插入`：数据库解析数据的压力增大，成本上升
            * solution 1: PreparedStatement，减少SQL解析。先发送一个SQL语句，中间的参数用问好占位；再发送多次参数提交给数据库。解析成本仅一次。
            * solution 2: 多值（INSERT语句中拼多条记录） / 批量（PreparedStatement中ADD BATCH）插入。
            * solution 3: Load Data原生命令，文本文件直接导入数据。
            * solution 4: 先把约束和索引去除，导入数据；之后一次性重建所有约束和索引。

    * 数据更新
        * GAP LOCK：范围可大可小
        * 注：能不用范围尽量不用范围，能精确就精确；尽量缩小范围粒度

    * 模糊查询
        * LIKE：默认前缀匹配（例，“%s”比“s%”慢）
        * 数据量大：不走索引性能很差。（解决方案）建立`全文检索`的倒排索引；ElasticSearch / solr，可以做到各类组合条件下的查询，全文检索类工具。

    * 连接查询
        * 问题：选择`驱动表`。驱动表越小，数据越明确。
        * 避免笛卡尔积（A*B*C*...）。

    * 索引失效
        * 与空的比较操作：NULL, not, not in
        * 函数（用函数也走不了索引）
        * 减少使用 'or'：使用 'union'（做了去重；'union all' 不去重）
        * 数据量大：放弃所有条件组合都走索引的幻想，直接全文检索。
        * 必要时：'force index', 告诉数据库强制走某个索引。

    * 查询 SQL 怎么设计？
        * 平衡查询的数据量和查询次数（多次高效查询）
        * 避免不必须的大量重复数据的传输（计算放在数据库侧，极大减少数据传输次数）
        * 避免使用临时文件排序或临时表（使用磁盘，降低效率）
        * 分析类需求，可以采用临时表/汇总表进行


## 3. 常见场景分析：26'40''
### 实现主键 ID
* 数据库自带的：自增主键
    * MySQL: AUTO_INCREMENT
    * SQL Server: IDENTITY(1,1，从1开始每次增加1)
    * 坏处：分库分表时产生冲突
    * 解决方案：使用全局唯一的ID
* 序列 sequence
    * Oracle, DB2
    * 数据库的自增计数表：多个表可以使用同一个sequence（原子计数，跨表ID不重复）
* 模拟 sequence
    * 在数据库中创建一张表，设置`3列（sequence name，当前值，步长）`
    * 全局的分布式锁，将各种并发请求串行化
    * 步长：（考虑序号不连续的情况）加长，提升操作性能，相当于取了一段数据（而非每次取一个数据记录）
    * 坏处：丢失一部分，则序号占用不连续；整体上自增，易被他人利用来估计数据增量/数据规模，泄漏商业机密。
* 当前主流方式一：`UUID`
    * 随机大数，基本不重复
    * 坏处：大字符串，占空间
* 当前主流方式二：`时间戳 / 时间戳+随机数`
    * 时间戳+随机数，减少同一时间产生的主键ID冲突
* 当前主流方式三：`snowflake 雪花算法`
    * “每一片雪花都是不同的”
    * 对“时间戳+随机数”方式的改进
    * 三段信息：当前机器，时间戳，在内存里不断自增的一段数字
        * 当前机器——降低了主键ID整体趋势递增的出现频率
        * 时间戳——递增
        * 自增序号——保证了相同时间内创建的主键ID是不同的

### 高效分页
* 分页原理：总数count，分页大小PageSize，根据传参pageNum查询，返回数据。
    * 常见需求
* 常见实现
    * 分页插件：只需提供查询SQL（外部自动封装count计算）
    * select count(*) from (提供的查询SQL)
    * 性能坑：当提供的SQL很复杂时，不管查出的数据量多大都很慢
* 改进一 
    * Q：当提供的SQL很复杂时，不管查出的数据量多大都很慢
    * A：确定查询的记录总数只需要查主表，重写count
    * select count(1) from (提供的查询SQL)
* 改进二 
    * Q：大数量级的分页：'limit 100000,20'（每页100000条数据，100000记录之后再取20条记录作为当前页）
    * A：降序查询（只查询20条）
* 改进三
    * Q：大数量级的分页：'limit 100000,50000'
    * A：技术向，带上一页的ID来小范围查询下一页的数据，ID索引，无需limit，精确定位
* 改进四
    * A：需求向，非精确分页
* 继续改进
    * Q：要求对所有条件都精确分页，且数据量很大
    * A：全文检索

### 乐观锁与悲观锁
* 悲观锁
    * 例，在释放锁之前，其他事务会被以下锁阻塞
    ```mysql
    select * from XXX for update;
    ```
    * 重，影响性能
    * 无锁 / 乐观锁
* 乐观锁
    * 先尝试操作，有冲突再重新读，重新尝试，本地自旋
    * 例，加一个条件判断，看当前读取的值是否已被其他事务修改，
    ```mysql
    select * from XXX;
    update XXX where value=oldValue;
    ```
* 锁的竞争不是很激烈时，乐观锁的效率远高于悲观锁。