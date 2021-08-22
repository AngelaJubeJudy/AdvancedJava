# TOPIC Ⅹ-Ⅷ: DISTRIBUTED SERVICES Ⅱ——Dubbo

## 1. Dubbo 框架介绍及技术原理：59'4''
### Dubbo 框架介绍
* 历史
    * 产生于阿里 B2B 的实际业务需要
    * 2011年开源：支持RPC，组件灵活可替换，支持分布式服务化，适用性强
    * 2013-2017：维护频率下降，但时长占用量很高
    * 2017年重启维护
    * 后续 Dubbo 3.0 将与云原生技术紧密结合
    * 国内存量用户最多（增量 Spring Cloud 后来居上）

* Apache Dubbo 主要功能
    * 特点：高性能、轻量级的开源 JAVA 服务框架
    * 6大核心能力
        * 面向接口代理的`高性能 RPC 调用`
            * 高性能：经过良好的设计，经过市场的检验
        * `智能负载均衡`
            * 内置策略，智能感知
        * `服务自动注册和发现`
            * 准实时的注册中心，能准实时地感知各应用节点的上线和下线
            * 系统的水平扩展能力
        * `高度可扩展`能力
            * Dubbo 结构：一个微内核+N个插件（所有组件都是插件，非常灵活）
        * 运行期`流量调度`
            * 内置条件判断、脚本等路由策略，通过配置不同路由规则实现
            * 与微服务相关
        * 可视化的`服务治理与运维`
            * 控制台工具

    * 基础功能：`RPC 调用`————Dubbo 内核
        * 核心抽象模型：Provider 服务提供者注册自己到 Registry 注册中心，Consumer 消费者通过注册中心去订阅服务，拿到服务提供者列表；任何服务发生变动，注册中心会通知消费者。消费者 invoke 服务提供者的过程状态会被 Monitor 监控统计。
        * 主路：Provider 服务提供者，Consumer 服务消费者
        * 旁路：Registry 注册中心，Monitor 监控；异步调用，设计方式一致（ Factory + Monitor/Registry + Service）
        * 基于 RPC，Dubbo 还支持：
            * 多协议（包括序列化、传输、RPC）
            * 服务注册发现（支持多种注册中心的基础设施；例，Zookeeper）
            * 配置、元数据管理
        * 框架特点：`分层`设计，可任意组装和扩展任意模块

    * 扩展功能：`集群，高可用，管控`
        * 集群，负载均衡
        * 治理，路由
        * 控制台，管理与监控台

* Dubbo 成功的秘诀：灵活扩展 + 简单易用（开箱即用）   

### Dubbo 技术原理
* 【♥】整体架构
    * 总览：
        * 纵向：服务消费者相关  + 服务提供者相关
            * `服务消费者相关：Business, RPC, Remoting`
            * `服务提供者相关：User API（可直接调用）, Contributor SPI`
            * SPI: Service Provider Interface，由服务提供的、可自己替换扩展实现的接口
        * 横向：10层
            * 1层：Service 层（Business 模块，业务接口层）
            * 9层：Dubbo 定义的（RPC, Remoting 模块；shown as below）

* RPC 模块
    * `config 配置层`
        * 对外配置接口（用户可直接调用）
        * 以 ServiceConfig（服务提供者侧）, ReferenceConfig（服务消费者侧） 为中心
        * 使用方式：初始化上述配置类；通过 Spring / Spring Boot 解析配置（生成配置类）
    * `proxy 服务代理层`
        * 服务接口透明代理
        * 生成服务的`客户端 Stub` 和`服务器端 Skeleton`
        * 以 ServiceProxy 为中心，扩展接口为 ProxyFactory
    * `registry 注册中心层`
        * 封装服务地址的注册与发现
        * 以`服务 URL` 为中心（使用URL作为服务的描述方式，支持多参数附加），扩展接口为 RegistryFactory, Registry, RegistryService  
    * `cluster 路由层`
        * 封装多个提供者的路由及负载均衡，并桥接注册中心（拿到服务列表）
        * 以 `Invoker` 为中心（代表对远程方法的调用），扩展接口为 Cluster, Directory, Router, LoadBalance 
    * `monitor 监控层`
        * RPC 调用次数和调用事件监控
        * 以 Statistics 为中心，扩展接口为 MonitorFactory, Monitor, MonitorService
    * `protocol 远程调用层`
        * 封装 RPC 调用
        * 以 Invocation（调用）, Result（响应结果） 为中心，扩展接口为 Protocol（协议入口点）, Invoker（封装的调用）, Exporter（服务暴露）

* Remoting 模块
    * `exchange 信息交换层`
        * 封装请求响应模式，同步转异步
        * 以 Request, Response 为中心，扩展接口为 Exchanger, ExchangeChannel, ExchangeClient, ExchangeServer
    * `transport 网络传输层`
        * 抽象 mina 和 netty 为同一接口
        * 以 Message 为中心，扩展接口为 Channel, Transporter, Client, Server, Codec（编解码）
    * `serialize 数据序列化层`
        * 可复用的工具
        * 扩展接口为 Serialization, ObjectInput, ObjectOutput, ThreadPool

* 框架设计
    * 服务的一次调用先经过 Proxy（由 ProxyFactory 提供；采用动态代理或字节码技术生成一个代理）；
    * 接下来经过 Filter（是否本地调用，是否需要 mock 或 cache；否，则不会远程调用）；
    * 接下来经过 Invoker（封装了 cluster 相关功能）；
    * 接下来通过 Registry 拿到 Directory（可用服务提供者的列表）；
    * 接下来经过 LoadBalance（找到具体的本次要调用的服务提供者）；
    * 接下来经过 Filter（本次调用的增强）；
    * 接下来经过 RPC 协议的 Invoker （封装了RPC协议）；
    * 接下来通过 client 端发出请求；
    * 接下来经过 Codec 编码和 Serialization 序列化之后，请求来到服务端；
    * 接下来经过 ThreadPool 服务端的线程池接受请求；
    * 接下来经过 Server 处理请求；
    * 接下来经过 Exporter 暴露服务；
    * 接下来经过 Filter 做响应的增强处理；
    * 最后经过 Invoker 去调用本地的真实的服务接口的实现类。

* SPI 的应用
    * SPI vs API
        * API：可直接调用的、由框架提供的业务处理能力
        * SPI：需要自己做实现类的接口
    * `ServiceLoader 机制`
        * 控制反转
        * 解决的问题：框架侧无法感知业务侧的、关于框架接口A的实现类
        * 方法：在 resources 文件夹下创建 META-INF 文件夹，`接口的全限定接口名`作为文件名。内容写作`实现类的全限定类名`。框架侧采用 ServiceLoader.loadService 机制，只需 load 接口，JDK 就会扫描当前系统 JVM 加载的所有 Jar 包，是否有上述文件；有，则 new 出接口对应的实现。
    * 类似机制
        * Callback：框架侧预留一个集合，放置各接口的实现类。
        * EventBus：中间位置；业务侧订阅接口类型的 Event 消息 AEvent，框架侧将参数信息封装在 AEvent 对象中，EventBus 拉起具体的业务方法去处理 AEvent 对象。
        * Dubbo 的 SPI 扩展：在写配置文件时，需要将接口实现类名称等于一个名称（例，在Protocol中，配置 xxx=com.alibaba.xxx.XxxProtocol）
    * Dubbo `启动时`，进行所有 SPI 扩展的装配；装配完的对象都缓存在 ExtensionLoader 中（避免二次加载）。
    
* Dubbo 服务如何暴露？
    * 例：InjvmProtocol 协议（不走远程）
        * InjvmProtocol（封装了 RPC 所有细节）
        * InjvmExporter（负责暴露）
            * step 1: ServiceConfig （配置实际服务的相关描述）
            * step 2: ProxyFactory （创建代理）
            * step 3: Invoker 
            * step 4: Protocol（封装所有） 
            * step 5: Exporter（暴露；也是调用的入口点）
        * xx Invoker（自己的 Invoker）
    * 注：所有服务都使用 `URL 的方式`描述！
    
* 服务如何引用？
    * 通过 ServiceReference 实现
    * ReferenceConfig：配置对远程服务的调用
    * 流程
        * step 1: ReferenceConfig：配置远程调用
        * step 2: 指定 Protocol
        * step 3: 引入 Invoker 
        * step 4: ProxyFactory 转换成真正的远程调用
        * step 5: ref
    
* 集群 & 路由
    * 位于 Dubbo 的 Cluster 模块
    * Directory 目录服务：list of invokers, 每个 invoker 代表了对某个服务提供者的引用；负责从注册中心拉取当前服务的所有可用的服务提供者列表。
    * Router 路由：负责选择此次调用能提供服务的 invokers 集合。
        * 方法：Condition, Script, Tag 打标签
    * LoadBalance：从上述 invokers 集合中选择单个的服务提供者。
        * 方法：Random, RoundRobin, ConsistentHash

* 泛化引用 GenericService
    * 已知接口、方法、参数，不需要对本地调用创建一个 Stub 存根，采用`反射`的方法即可调用服务。
    * 方法一：使用 Spring
    ```java
    // 配置：generic="true"
    // <dubbo:reference id="barService" interface="com.foo.BarService" generic="true"/>
    // 创建代理，返回GenericService类型
    GenericService barService = (GenericService) applicationContext.getBean("barService");
    // 反射方式调用远程服务：方法sayHello()
    Object result = barService.$invoke("sayHello", new String[]{"java.lang.String"}, new Object[]{"World"});
    ```
    * 方法二：不使用 Spring
    ```java
    // 配置类
    ReferenceConfig<GenericService> reference = new ReferenceConfig<GenericService>();
    // 配置接口、方法、参数
    reference.setInterface("com.xxx.XxxService");
    reference.setVersion("1.0.0");
    reference.setGeneric(true);
    // 建桩
    GenericService genericService = reference.get();
    // 反射调用
    genericService.$invoke("sayHello", new String[]{"java.lang.String"}, new Object[]{"World"});
    ```

* 隐式传参
    * Context 模式
        * 上下文变量传到另外一侧：
        ```java
        RpcContext.getContext().setAttachment("index", "1");
        ```
        * 此参数可以传播到 RPC 调用的整个过程，透过网络被感知。
        * 实现：HTTP请求，请求头中置入多组KV；TCP请求，Dubbo在原先序列化的报文数据前额外增加一小段头，置入多组KV。

* mock
    * 例，
    ```bash
    <dubbo:reference id="helloService" interface="com.foo.HelloService" mock="true" timeout="1000" check="false>
    ```
    * 期望：本地开发调试，只调用本地mock；方便测试
    * Dubbo 框架中的流程
        * 服务的一次调用先经过 Proxy（由 ProxyFactory 提供；采用动态代理或字节码技术生成一个代理）；
        * 接下来经过 Filter（是否本地调用，是否需要 mock 或 cache；否，则不会远程调用）。
        * 在本地寻找相同接口名，但后缀为Mock的实现类；有，加载并作为当前Bean的实现类；无，则需要先实现。



## 2. Dubbo 应用场景及最佳实践：39'31''
### Dubbo 应用场景
* 场景一：分布式服务化改造
    * 数据改造：拆分
    * 服务设计：分布式服务化，根据数据设计
    * 不同团队相互配合
    * 开放、测试、运维

* 场景二：开放平台
    * 平台发展的两个模式
        * 开放模式：微内核 + API；星状/网状结构
        * 容器模式：开放一套 SPI，集成服务能力
    * API 与 SPI 
        * 分布式服务化与集中式ESB
        * ESB：抽象各应用的多种服务能力，包装成 Web Service，放在 ESB 总线上；ESB 作为企业服务能力的集成点，集中管控。

* 场景三：BFF
    * BFF：直接作为前端使用的后端
    * 基于 Dubbo 实现 BFF
    * 一般不建议：最好中间再加一层粘合剂层（Controller层/Web层），业务 Service 层最好不要改变。
        * 灵活支持前台业务，即向中台发展。

* 场景四：通过服务化建设中台
    * 基于 Dubbo 实现业务中台
    * 业务服务能力包装成 API：沉淀出稳定、可复用的业务能力
        * 支持前台快速变化的需求，让后台的基础设施相对稳定

### Dubbo 最佳实践
* 开发分包
    * `服务接口、服务模型、服务异常`：通用的放在 API 包中
    * 服务接口
        * 尽可能大粒度：每个服务方法代表一个功能（避免一致性问题）
        * 建议`以业务场景为单位`划分，抽象聚合相近业务，防止接口过多
    * 不建议使用过于抽象的通用接口，无明确业务语义，不便于后期维护
    
* 环境`隔离`与分组
    * 部署多套：不便于同一管理
    * 多注册中心机制：每个注册中心负责一部分服务的注册
    * group 机制：服务天然分组，逻辑隔离，group间服务地址隔离
    * 版本机制
        * 接口新增方法、模型新增字段：可向后兼容
        * 接口删除方法、模型删除字段：不可向后兼容，必须通过变更版本号升级
    * tag 机制

* 参数配置
    * `通用参数：以 Consumer 端为准`。
        * 如果 Consumer 端没配置，使用 Provider 端的数值。
    * Provider 端的配置：与提供服务的能力相关
    * 建议在 Provider 端配置的 Consumer 端属性
        * timeout
        * retries
        * loadbalance
        * actives（消费者的最大并发调用限制）
    * 建议在 Provider 端配置的 Provider 端属性
        * threads
        * executes

* 容器化部署
    * `注册的IP问题`：容器内提供者使用的IP，如果注册到ZK（注册中心在外部），消费者无法访问。
    * 解决方法一：docker 使用宿主机网络
    ```bash
    docker xxx -net xxxxx
    ```
    * 解决方法二：docker 参数指定注册的IP和port，“-e”参数
    ```bash
    <!-- 注册到注册中心的IP地址 -->
    DUBBO_IP_TO_REGISTRY=XX.XXX.XXX.X
    <!-- 注册到注册中心的端口 -->
    DUBBO_PORT_TO_REGISTRY=XXXXX
    <!-- 监听IP地址 -->
    DUBBO_IP_TO_BIND=XX.XXX.XXX.X
    <!-- 监听端口 -->
    DUBBO_PORT_TO_BIND=XXXXX
    ```

* 运维与监控
    * 管理控制台 Admin 功能较简单，需要按需定制开发
    * 可观测性：tracing 全链路跟踪, metrics 指标监控, logging 日志统计分析 (可以用ELK)
        * tracing：APM 工具
        * 监控指标数据的展示：Promethus + Grafana 

* 分布式事务
    * `柔性事务`：SAGA, TCC, AT
    * 实现一：Seata（AT）
    * 实现二：Dubbo + hmily（TCC）
    * Dubbo 不支持 XA

* 重试与`幂等`
    * 场景：服务调用失败，`默认重试2次`；若健康设计不幂等，会造成业务重复处理。
    * 如何设计幂等接口？
        * 去重，允许重复（ID放在bitmap中，按位操作，处理非常快）
        * 类似乐观锁机制（ID作为判断条件）

### 深入学习 Dubbo 源码
* Dubbo 重点模块（对照核心框架学习）
    * `核心概念层`
        * common
        * config
        * filter
        * rpc/remoting/serialization
    * `集群与分布式`
        * cluster
        * registry/configcenter/metadata










