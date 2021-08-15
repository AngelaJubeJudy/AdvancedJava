# TOPIC Ⅹ-Ⅵ: DISTRIBUTED TRANSACTION 分布式事务 

## 1. 分布式事务及 XA 分布式事务：47'35''
### 分布式事务
* 解决一致性问题
    * 每个数据库的操作都是一个事务；与数据库连接绑定
    * 单机事务————单机系统访问单机数据库的事务一致性。
    * 一致性问题：分布式多结点间的事务默认情况下无关
    * 分布式事务————在分布式条件下，多个结点的整体事务一致性。

* 分布式事务
    * 例：业务A和业务B强关联，但事务A成功事务B失败，由于跨系统，不被感知。从整体来看，数据不一致。
    * 思路一：理想状态
        * 多个数据库通过某种机制协调一致，不管本地事务有几个，都当作一个整体事务操作；要么同时提交要么同时回滚。
        * 场景：要求严格的一致性（例，金融交易类业务）。
        * solution：数据库支持XA协议
    * 思路二：一般情况
        * 容忍中间的短暂的不一致状态：通过定时任务检测出可能的不一致，通过补偿保证最终一致性即可。“补偿机制”，冲正。
        * 场景：准实时/非实时的处理（例，T+1的各类操作）。
        * solution 1：不用事务，业务侧补偿冲正
        * solution 2：柔性事务框架，保证最终的一致性

### XA 分布式事务
* 强一致性；关系数据库本身支持
* 设计思路：在现有事务操作模型上微调，实现分布式事务
    * 全局事务管理器

* 事务模型
    * AP, Application Program：由应用程序发起事务
    * RM, Resource Manager：多个，管理具体资源，如数据库
    * TM, Transaction Manager：事务管理器通知资源，控制协调本地事务提交/回滚。

* XA 接口（以下为6个核心操作）
    * `xa_start`：开启/恢复（当前MySQL结点上的本地事务，即分支事务）
    * `xa_end`：取消当前线程与事务分支的关联（=操作执行完了）
    * `xa_prepare`：询问RM是否准备好提交/回滚到数据库
    * `xa_commit xid [ONE PHASE]`：通知RM提交（使用`ONE PHASE`，表示使用一阶段提交；两阶段提交协议中，若只有一个RM参与，可以优化为一阶段提交）
    * `xa_rollback`：通知RM回滚
    * `xa_recover`：需要恢复的XA事务
    * Q：XA事务又叫两阶段事务？
        * A：以 xa_prepare 分界。

* 数据库对XA事务的支持
    * 命令行查看 InnoDB 是否支持 XA
    ```sql
    show engines;
    ```
    * 在 DTP 模型中，MySQL 属于 RM。
        * 分布式事务中存在多个 RM，由 TM 统一管理。

* MySQL 的 XA 事务
    * 注：XA 事务与非 XA 事务互斥（在当前 connection 上）
    * 状态图：XA START -> `ACTIVE` -> 执行一些SQL操作 -> XA END -> `IDLE`
        * 一阶段： -> XA COMMIT -> `COMMITTED`
        * 二阶段： -> XA PREPARE -> `PREPARED`
            * 提交： -> XA COMMIT -> `COMMITTED`
            * 回滚： -> FAILURE -> `FAILED` -> XA ROLLBACK -> `ABORTED`

* XA 事务处理时序图
    * 应用程序发起全局事务
    * TM 生成全局事务ID：xid
    * 应用程序执行全局事务的一系列操作
    * TM 分别向每个 RM (MySQL) 发送 XA START，开启事务；执行具体的SQL
    * 应用程序执行 XA COMMIT，TM 分别向每个 RM (MySQL) 发送 XA PREPARE
        * TM 确认所有 RM 都 OK，整体事务才 OK；接下来，向每个 RM (MySQL) 发送 XA COMMIT xid，各自提交。全局事务成功。
        * TM 确认中间发射管异常，则接下来向每个 RM (MySQL) 发送 XA ROLLBACK xid，各自回滚。全局事务失败。

* 单个 MySQL 在 XA 事务处理过程中的时序图
    * TM 分别向每个 RM (MySQL) 发送 XA START xid，开启多个分支事务
    * RM 执行接收到的 SQL
    * SQL 操作全部执行完毕，TM 分别向每个 RM (MySQL) 发送 XA END xid
    * TM 分别向每个 RM (MySQL) 发送 XA PREPARE xid
    * RM 准备好提交
    * TM 分别向每个 RM (MySQL) 发送 XA COMMIT xid

* 针对以上过程思考：执行过程中，事务失败怎么办？
    * 业务 SQL 执行过程中，某个 RM 崩溃？
        * TM 可感知，执行 XA ROLLBACK 全体回滚。
    * 全部 PREPARED 后，某个 RM 崩溃？
        * TM 可感知，执行 XA ROLLBACK 全体回滚。
    * XA COMMIT 时，某个 RM 崩溃？
        * TM 可感知，收集各 RM 的提交结果，重试未成功的提交。最终所有提交成功。
    * MySQL > 5.7 的版本修复：在 XA PREPARE 时完成写 binlog 的操作，防止再次重连时把已经 PREPARED 的事务回滚。

* JAVA 中的分布式事务框架 
    * `Atomikos`：老牌，性能高，扩展性好，标准的 XA 实现；事务日志写在文件；只支持单机事务恢复。
    * JBOSS `Naratana`：性能较高，扩展性好，标准的 XA 实现；事务日志写在文件或数据库中；支持集群模式事务恢复。
    * Seata：非标准的 XA 实现

* XA 分布式事务的3点注意
    * 同步阻塞问题：默认情况下并不改变事务的隔离级别。如果对数据一致性要求严格，可以将 XA 事务隔离级别设置为 SERIALIZABLE，串行化的方式。极端场景下需要跨库严格一致时，将多个 MySQL 上的隔离级别都设置为串行化，再用 XA 分布式事务；此时性能较差。
    * 单点故障：TM 作为协调者，一旦出错，整个事务将无法继续；此时对整个系统的资源占用非常严重。解决事务管理器的高可用问题。
    * 数据不一致：在二阶段提交的阶段二，由于局部网络异常或发送 commit 请求过程中 TM 发生故障，导致部分 RM 提交失败时出现数据不一致。常规事务管理时，做好监控和告警后人工处理，在网络抖动时重试。

* 实战操作
```sql
--- 查看InnoDB 是否支持 XA 事务
show engines;
use db;

--- 开启 XA 事务
xa start 'java1';
insert into test1 values(1000),(2000);
xa end 'java1';
xa prepare 'java1';
xa recover 'java1';
xa commit 'java1';
--- 检查 XA 事务是否提交成功
select * from test1;

--- 开启 XA 事务
xa start 'java2';
insert into test1 values(3000),(4000);
xa end 'java2';
xa prepare 'java2';
xa rollback 'java2';
--- 检查 XA 事务是否回滚成功
select * from test1;
```


## 2. BASE 柔性事务：12'07''
* 事务的发展：本地事务 -> XA（二阶段）强一致性事务 -> BASE 最终一致性事务
* 事务分类
    * 刚性事务：实现了 ACID 事务要素；对事务隔离性要求很高，资源锁定，并发操作不互相干扰。
    * 柔性事务：实现了 BASE 事务要素；通过业务逻辑，将互斥锁操作从资源层面上移到业务层面。
        * 放宽一致性要求，提高系统吞吐量。

### BASE 事务要素
* `Basically Avaiable 基本可用`：保证分布式事务的各个参与方不一定同时在线。
* `Soft State 柔性状态`：允许系统状态更新的延时（短暂不一致，客户不一定能够察觉）。
* `Eventually Consistent 最终一致性`：通过消息传递保证系统的最终一致性。

### BASE 柔性事务
* 业务系统：需要额外地实现相关接口（有业务侵入性，业务侧事务设计比之前复杂）
* 一致性：最终一致性
* 隔离性：`业务方`保证（设计使当前业务不会读取其他业务正在操作的数据）
* 并发性能：略微衰退
* 适合场景：长事务 & 高并发

### 常见模式
* TCC / Saga
    * 手动补偿处理
    * 写代码撤销业务对数据库的操作
* AT
    * 自动补偿
    * 自动分析业务对数据库的操作，生成反向操作


## 3. TCC/AT 及相关框架：41'41''
### 常见模式
#### TCC 模式
* 在业务侧重新模拟了XA事务的处理阶段
* 两个阶段
    * Try：完成业务检查，预留业务资源（类比XA的 prepare）
        * 缺：对业务的侵入性
        * 优：可并发检查；独立于数据库，不需要数据库支持分布式事务
    * 根据所有业务的 Try 状态操作：都成功，confirm；有失败，cancel
* 三段逻辑（三个操作各自都是独立的事务！）
    * `准备操作 Try`：
    * `确认操作 Commit`：真正执行业务逻辑（类比XA的 commit）
    * `取消操作 Cancel`：释放 Try 预留的业务资源（类比XA的 rollback）
* 过程
    * 业务应用启动事务，通知事务协调器
    * 业务应用调用 Try 接口（在各个服务节点上），冻结所需的业务资源
    * 业务应用提交/回滚事务，通知事务协调器
    * 事务协调器调用 Confirm/Cancel 接口
* 注意
    * 允许空回滚：未成功的 Try，回滚检测，做空回滚。
    * 防悬挂控制：Try 请求超时（对调用方/被调用方），网络抖动，请求乱序，先 Confirm/Cancel 再 Try，发生悬挂。后续到达的 Try 被拒绝。 
    * 幂等设计：重复发送 Confirm/Cancel 请求，幂等的操作，多次操作结果一致。

#### SAGA 模式
* 无 Try 阶段，直接提交事务
    * 执行每个事务并记录过程；失败时挨个反向回滚
    * 对业务的侵入性小于 TCC 模式
* 复杂情况下，对回滚操作的设计要求较高
    * 每个事务都很复杂，撤销需保证反向
    * 注：所有撤销操作都必须做幂等

#### AT 模式
* 优化：使用中间件或框架
    * 有SQL执行失败：执行反向SQL把之前的操作撤销
    * 适用于简单的 SQL 操作
* 两阶段提交，自动生成反向 SQL
    * 一阶段：拦截用户对数据库的SQL，分析后自动生成反向SQL
    * 二阶段

### 柔性事务下的隔离级别
* 事务特性
    * Atomicity 原子性————正常情况下保证
    * Consistency 一致性————最终一致性
    * Isolation 隔离性————中间过程可以读到部分结果；隔离性一般，需要业务侧保证
    * Durability 持久性———— commit 的数据（依赖参与的数据库的持久性保障）
* 隔离级别
    * 一般：读已提交（`全局锁`），读未提交（无全局锁）

### 框架
#### Seata
* 支持 TCC / AT
* 事务生命周期管理
    * TM：事务管理器
    * TC server：事务协调器，管理各个分支事务（承担了 TCC 模式中 TM 的大部分功能）
        * 优：微服务节点的单点故障不会影响整体
        * 缺：TC server 宕机，整个分布式事务无法执行
* Seata - TCC
    * 三阶段：Prepare, Commit, Rollback
* Seata - AT
    * 两阶段提交
        * 一阶段：业务数据和回滚日志都在本地事务中提交，在本地事务所在数据库中。释放连接锁和资源。
        * 二阶段：异步化快速提交。如需回滚，通过一阶段的回滚日志进行反向补偿。
    * 全局锁：读写隔离
        * 本地锁：控制本地操作。提高并发能力。
        * 全局锁：控制全局的提交。降低并发操作对性能相互间的影响粒度。

#### hmily
* 开箱即用的分布式事务解决框架，基于 TCC 模式
* 高级功能
    * 支持嵌套事务
    * 支持RPC事务恢复（高稳定性）
    * 基于异步的 Confirm/Cancel 设计（高性能）
    * 基于 SPI 和 API 机制设计
    * 本地事务的多种存储支持
    * 事务日志的多种序列化支持
    * 基于高性能组件 disruptor 的异步日志（高性能）
    * 实现了 SpringBoot-Starter，开箱即用
    * 事务管理器采用 AOP 思想，与 Spring 无缝集成，天然支持集群
    * 实现了基于 VUE 的 UI 界面，方便监管

* 生态良好
    * 分布式事务的解决方案：多种微服务接入技术、各种异常处理机制、事务的调度和恢复、UI 管理控制、日志存储等多方面的强大支持。

### ShardingSphere 对分布式事务的支持
* ShardingSphere：支持分布式事务框架的集成，但不实现分布式事务
* ShardingSphere 支持 `XA 事务`的常见开源实现（良好的封装、抽象、适配）
    * 在 ShardingSphere 分库分表 Sharding Transaction Manager 的基础上，支持 XA Sharding Transaction Manager，之上包装 XA Transaction Manager。
    * 拟合层 JTA Transaction Manager：支持 Atomikos, Narayana 等框架。
* ShardingSphere 支持 Seata 的`柔性事务`
    * SeataShardingTransactionManager 事务管理器：将 Sharding Transaction Manager 的各个阶段适配到 Seata 的事务管理器和事务协调器上。