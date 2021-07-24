# TOPIC Ⅸ: JAVA Framework Ⅰ
## 1. Spring 技术发展及框架设计：33'53''
### 1.1 技术发展
* 服务器分类：web server, HTTP server, J2EE server 
* 历史：使用 EJB，企业级容器层面的管控；重量级，成本高
    * Spring 框架应运而生（by Rod Johnson）：简化企业级应用，简化 JAVA、web 项目
    * Spring 框架成为 JAVA 领域的一种事实标准
* Spring 重要发布
    * (2006) Spring 2.5.x，支持了 JAVA 6 / J2EE 5
    * (2013) Spring 4.x，支持了 JAVA 8
    * (2014) `Spring Boot`：增强了引入、开发的便利性，改进使用相关体验；"`Build anything`"，构建一切
    * (2015) Spring Cloud：拥抱微服务，拥抱云原生；"`Coordinate anything`"，协调一切
    * Spring Cloud Data Flow: "Conenct anything"，连接一切
    * Web 服务器 Tomcat
    * 中间件 
        * 缓存中间件 Redis 
        * 消息中间件 RabbitMQ
* Spring 版本标记（[官网](https://spring.io/projects/spring-framework#learn)）
    * GA: Generally Available，基本可用
    * CURRENT：当前主干版本
    * SNAPSHOT：日常构建打包，较新，不稳定
    * RC：候选发布版本，相对稳定
    * RELEASE：基本可用的版本，稳定

### 1.2 框架设计
* 框架是什么？ 
    * 特定领域的、基于一定规则聚合的一组类库或工具的应用程序开发骨架
* 框架特性
    * `支撑性 + 扩展性`：普适的，不解决业务问题，但可以支撑添加业务特性
    * `聚合性 + 约束性`：框架代表一种技术选型（规则的聚合体）
* 技术发展聚合路径
    * 通用方法 --> 工具类 --> 类库 
    * 通用项目底座 + 类库 = 框架
    * 通用业务模块 + 框架 = “脚手架”
    * 多个脚手架 + 指定领域（通过参数控制） = “产品”
    * 多个领域 + 产品 = “平台”
    * 平台 + 多租户 = SaaS，云

* Spring的6大模块
    * 【常用】`Core: Bean / Context / AOP`
        * 最核心：Spring 就是 `Bean` 的管理（轻量级的 Bean，对比 EJB 的 Bean）
        * Bean 的增强：AOP
        * 统一管理 Bean 的容器：Context 
    * 【常用】Testing: Mock / TextContext
    * 【常用】DataAccess: Tx / JDBC / ORM
        * Tx：事务管理
    * 【常用】Spring MVC / WebFlux: web
    * Integration: remoting / JMS / WS
        * 常见技术的集成
    * Language: Kotlin / Groovy 
        * 多语言集成（基于 JVM 的非 JAVA 语言） 

* Spring的引入：一种协作研发模式
    * 以前：单体项目
    * 引入 Spring：
        * 项目天然`水平分层`（展示层，业务层，服务层，持久化层），层间对象和引用关系通过 Spring 的注解和配置解决，无需额外代码维护。
        * 项目`垂直分层`：按不同业务模块划分。
        * 项目组件化：细粒度拆解项目，更好地协作、控制。


## 2. Spring AOP 详解及 Spring Bean 核心原理：49'36''
### 2.1 Spring AOP (Aspect Orient Programming)
#### 预习
* 面向“多个模块具有相同的修改问题”的场景，`面向切面编程`
    * 保证开发者不修改源码的前提下，为系统中的业务组件添加某种通用功能
    * “代理模式”的典型应用
* AOP Terminology
    * Advice 通知：增强处理，描述何时执行+如何执行。分类：前置通知（aop:before），后置通知（aop:after-returning），环绕通知（aop:around；相当于前置通知+中间的实际方法执行+后置通知）。
    * joint point 连接点：能插入切面的点，为方法的调用之处。
    * PointCut 切点：可插入增强处理的连接点。表达式命中格式：“包名.类名.方法名”（例，"execution(* io.kimmking.aop.*.*(..))"）；当调用某方法时，切点被命中。
    * Aspect 切面：通知和切点的结合。
    * Introduction 引入：允许现有类添加新的方法/属性。
    * Weaving 织入将增强处理加入目标对象，并创建一个被增强的对象。
* Spring 框架中的 AOP 是通过动态代理实现的。

#### Spring AOP
* “计算机领域的任何问题都可以通过增加一个中间层来解决。”
* Spring 早期的核心功能：Bean 的管理、创建、生命周期内和其他对象间的引用装配
* 后期需求：中间层，实现对象包装，不改变原有 Bean 的定义功能；通过代理/字节码增强实现
* `IoC, Inverse of Control 控制反转`
    * 也称“`依赖注入（DI， Dependency Injection）`”  
    * 之前：上层依赖下层（对象A引用、操作对象B） 
    * 引入 Spring：运行期无需改代码，只需改配置文件（对象A依赖接口IB，运行时可以塞进对象 A 接口IB的不同的实现类的对象实例）
* Q：装配时有循环依赖，如何解决？（）
    * `属性之间的循环依赖`————A：在 Spring 中，两个相互依赖的对象，首先各自独立地创建（两个引用已存在），之后再对各自的内部属性进行装配。使用 AOP 的场景中，显式地拿到 Bean，通过代码显式地注入其他对象时，从中间层拿到的是代理类或运行期生成的子类，由于拿到的不是真实对象，所以不存在循环依赖。
    * 类的初始化，即构造函数中的对象间的循环依赖————A：无解。

* Spring中的一个类：可以注册成 Spring 中的一个 Bean（之后 Spring 将其初始化成一个可用对象）。
    * 需要做增强/做切面：中间加`代理类/增强类` 
        * 基于接口的类的对象：默认使用 `jdkProxy (JDK的动态代理)`，`生成代理`；对象的增强操作放在代理的方法代码中，最终再调用原始的对象，返回结果。
        * 非接口类型的对象：默认使用 `CGlib` 做`字节码增强`，`生成子类`；先做子类操作，再调用原本类的方法，返回结果。
        * 如果基于接口的类对象也使用字节码增强技术：开启 proxyTargetClass 选项。

* Student, Klass, School
    * 常用注入方法：@Autowired 默认按类型注入，@Resource 默认按名称注入
        * @Autowired(required = true)：启动时配置装载。
        * @Autowired(required = false)：调用属性或方法时再装配，软加载。
    * 常用 Spring AOP 的使用（等价）
        * `代码（AOP 的类） + XML`（将 AOP 的类注册成一个 Bean。然后定义 pointcut 和 aspect，匹配；这样代码和切面就能作用到所有切点上，即切点上发生切面）
        * `注解`：@Aspect, @Pointcut, @Before(value="切点方法"), @AfterReturning(value="切点方法"), @Around("切点方法")。需要在配置文件中开启自动代理，"<aop:aspectj-autoproxy/>"。
    * 执行顺序：around begin f() --> begin f() --> f() --> around finish f() --> finish f()

* 用途：针对已有代码的额外控制需求
    * 日志
    * 权限判断
    * 事务控制

* 与 CGlib 类似的可以做字节码增强的工具
    * JAVA中的动态代理：Java Proxy
    * ASM 库
    * AspectJ 库
    * Javassist 库

* 字节码增强 vs 反射
    * 字节码操作：运行期在内存里动态拼出的`新类型`。
    * 反射：破坏了面向对象的封装；窥探内部。`隐式调用`。
    * Instrumentation：Jar包在向JVM加载的中间层做一次预处理，替换JAR包中的字节码。
    * 字节码增强新工具：ByteBuddy

### 2.2 `Spring Bean 核心原理`
#### Bean的生命周期
* 早期：BeanFactory 接口
    * 后期多种能力加持：`ApplicationContext`，Spring 的核心容器，管理所有 Bean.
    
* Bean 的加载
    * `完整过程`：构造函数 --> 依赖注入 --> BeanName Aware --> BeanFactory Aware --> ApplicationContext Aware --> BeanPostPrecessor 前置方法 --> InitializingBean --> 自定义init()方法 --> BeanPostProcessor 后置方法 --> `使用` --> DisposableBean --> 自定义destroy()方法
        * 简化：加载 --> 使用 --> 关闭。
    * 特点：复杂
        * WHY? Spring 是对 Bean 管理的基础设施，适用统一控制 POJO、Server 等各种类型的 Bean，因此 Spring Bean 从加载到初始化再到启动，被抽象为一系列步骤。 
    * 流程简述：先new一个对象实例，然后查看是否有注入其他对象。接下来在配置的时候传进一些信息，如Bean的名称、Bean工厂、Context（通过 Bean 工厂和 Context 可以拿到其他Spring 内部的 Bean）。前置、后置处理相当于filter；在这两者之间是初始化Bean和启动运行Bean的步骤。destroy() 方法对应 init() 方法，关闭当前Bean.
    * 思考：与 ClassLoader 的加载过程有哪些相似之处？ 
    * 代码层面：doCreateBean() 方法，处理 Bean 的实例化、属性赋值、初始化、销毁（注册回调地址）等步骤。初始化过程中，先检查 Aware 装配，之后做前置处理，调用 init() 方法，然后做后置处理。
    * 加载过程中的 BeanFactory：负责 Bean 的定义，以及从 Bean 的定义到 Bean 的转换。
    * 加载过程中的 ApplicationContext：负责 Bean 的加工、增强。
    * BeanPostPrecessor 的2个初始化方法：postProcessBeforeInitialization(), postProcessAfterInitialization().


## 3. Spring XML 配置原理：21'18''
* 本节目标：Bean 如何通过 XML 配置进行配置和加载。

### 配置原理
* XML 本身的 schemas 定义（即描述XML文件格式的定义）
    * 格式一：XSD（即Spring中默认的格式），XML 的 schema 定义
    * 格式二：DTD，文档类型的定义
* `spring.schemas`文本文件：对 Spring 本身的 XML 文件的定义。
    * Spring-bean 的jar包中有 spring.schemas 这个文本文件，XSD文件在当前jar包中。
    * 用于校验 XML 文件内容/格式。
* `spring.handlers`：在运行期将XML的Bean的定义加载，变成实际运行的JAVA对象的 Bean。
    * ContextNamespaceHandler：处理在其命名空间下定义的元素，以DOM的形式读取为DOM对象结构，再将DOM对象结构转换成实际使用的Bean的类。
* 配置实例说明：XML 文件
    * 最外层 <beans> 的定义：头
        * xmlns: namespace（不加冒号表示当前文件默认的 NS），用于指定配置的对象所属的 NS.
        * `schemaLocation`：前后两个字符串匹配，一个与 NS 定义一致，另一个是 XSD 文件地址（本地/远程）。
    * 里层 Bean 本身的定义 <bean>
* 配置原理
    * 使用 Spring 自带的自定义标签，定义一个 applicationContext.xml 文件
        * 文件包含：<beans> 头，各种 <bean> 定义，其他 NS 中的属性定义。
    * 加载
        * 通过 spring.schemas 文件，schemaLocation 找到对应具体 JAR 包中的 XSD 文件，校验 XML 文件配置的正确性。
        * Spring 程序被加载和 Spring 容器初始化的过程中，schemaLocation 找到每个 NS 对应的 NamespaceHandler，将 DOM 对象树解析成对象，将内容交给NamespaceHandler，最终变成Spring的Bean.

* 配置简化：Apache 的开源项目 `ActiveMQ`
    * 自动化 XML 配置工具
    * 利用Spring @Comments 里的组件 `XmlBeans`，进行 XSD 和 Bean 之间的转换。
    * XmlBeans 类库：根据实体类本身的结构可以生成 XSD 文件，自动做类结构本身和 XSD 之间的相互转换。
    * 小插件 `Spring-xbean`：
        * 自动把Spring的Bean生成Spring需要的XSD文件。因此可以自动做一个通用的NamespaceHandler，将定义时XML中的对象属性转换成实际运行时的类属性（一一对应，完全匹配）。
    * 牺牲了灵活性：之前 XML 文件中配置的字段名、类对象结构，可以和 Bean 本身的结构不一致。

* 解析 XML 的工具
    * 类型一：DOM（全部加载到内存，解析成结构一致的 DOM 树）
    * 类型二：SAX/StAX（流式遍历节点，可以自定义visit模式）

* XML 和 Bean/POJO JAVA 对象的相互转换工具
    * xbean
    * XStream 开源框架

### Spring Bean 配置方式演化
* `XML 配置` / @AutoWire 注解注入。
* `半自动注解配置`：当前类在 Spring 加载时变成 Spring 的 Bean，放在容器中。
    * @Service, @Components, @Repository
* `Java Config 配置`
    * @Bean：一个方法的返回结果可以作为一个 Bean 放在容器中。
    * @Configuration 类：专门做注解相关的配置的类
* `全自动注解配置`
    * @AutoConfigureX 机制（静态）
    * @Condition 机制：运行时根据条件灵活的配置组装


## 4. Spring Messaging：24'11''
### Messaging 与 JMS
* Messaging：发送、接收消息，消息的流动。
* 工具包：javax.jms.*
* 应用场景举例
    * 同步转异步
        * RPC, HTTP：系统间的同步通信。
        * Messaging：消息统一发给`消息服务器 server broker`，由它负责投递到接收消息的各系统。间接通信，系统无需等待消息；更可靠，离线系统待接收消息不丢失。
    * 简化了多系统间通信的网络拓扑关系。
        * 之前：网状拓扑，当一个系统出了问题，因为其他系统与之有耦合关系，任何一个指向该系统的调用都会失败；系统稳定性差，影响集群内其他系统。有 N 个系统就有 N(N - 1)/2 条连线。
        * 采用MQ：有 N 个系统就有 N 条连接关系。
* JMS (Java Messaging Service)：JAVA 中的消息规范
    * 定义了消息本身的接口，消息的行为模式，客户端访问消息服务器时的角色、行为等。
    * 定义消息的2种模式
        * `Queue`：消息只能给某一个消费者。
        * `Topic`：广播给所有消费者。
    * `生产消费模式`：Producer --> Queue --> Consumer
    * `发布订阅模式`：Publisher --> Topic --> Subscribers
    * 常见的实现模式：[ActiveMQ](activemq.apache.org)
        * `Queue`：默认持久化（重启server消息不丢失）。
        * `Topic`：默认不持久化（重启server消息丢失；支持设置“持久订阅”）。

### 代码实例分析
* 安装并启动 ActiveMQ
    * 启动：
    ```bash
        bin/activemq start
    ```
    * 访问控制台 "http://localhost:8161"确认是否正常运行。
* 需要引入的包
    * spring.messaging
    * spring jms

* XML 配置文件
    * springjms-sender.xml
        * 配置连接工厂：<bean id="connectionFactory" class="org.apache.activemq.ActiveMQConnectionFactory">
        * 配置Queue：<bean id="queue" class="org.apache.activemq.command.ActiveMQQueue">
        * 使用连接工厂配置 template：<bean id="jmsTemplate" class="org.springframework.jms.core.JmsTemplate">
        * 连接工厂、Queue、jmsTemplate：来自pom.xml中引入的`activemq-client`包。
    * springjms-receiver.xml
        * 配置连接工厂：<bean id="connectionFactory" class="org.apache.activemq.ActiveMQConnectionFactory">
        * 配置Queue：<bean id="queue" class="org.apache.activemq.command.ActiveMQQueue">
        * 使用连接工厂配置 template：<bean id="jmsTemplate" class="org.springframework.jms.core.JmsTemplate">
        * 监听器的容器：定义在jms命名空间内，<jms:listener-container>；同时，在容器内部定义监听器 <jms:listener>.

* SendService.java
    * 加注解 @Component 变成 Spring 的一个 Bean
    * 注入一个 jmsTemplate：用于发送一条消息到 queue 里。
* JmsListener.java
    * implements MessageListener
    * 消息类：ObjectMessage
    * 收到消息时的动作：onMessage(Message m)
* JmsReceiver.java
    * 拉起 springjms-receiver.xml 的配置（listener 启动时会自动建立的 ActiveMQ 的连接）
* JmsSender.java
