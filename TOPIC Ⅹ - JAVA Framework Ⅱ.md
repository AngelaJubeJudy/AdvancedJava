# TOPIC Ⅹ: JAVA Framework Ⅱ

## 1. 从 Spring 到 Spring Boot：29'35''
### Spring Boot 的出发点
* Spring 的装配和功能
    * 使用方式演化：`全`局XML配置-->分散到`类`上的`注解`(@Repository, @Component, @Service)-->配置类（@Bean注解放在`方法`上,方法的返回值变成Spring容器里的对象）
    * 外在：使用灵活，但注解越多配置越复杂
    * 内在：Spring的功能、组件逐渐庞大
    * “`非限定性框架`”：提供原始材料，不限制使用，可以做任何修改、搭配。
* Spring Boot 开发动力
    * 简化开发
    * 简化配置
    * 简化运行
    * “`限定性框架`”：关键技术选型已确定。在现有原材料的基础上做了初步整合（无需从头开始）。
    * Spring Boot 优化的核心：“`约定大于配置`”。
        * 类比：启动一个JAVA程序时，不需要配置所有JVM参数，仅使用 "java" 命令就可以运行；就是因为“约定大于配置”，参数基本都有默认值。
        * 默认值：约定大于配置。
        * 组件的整合：约定大于配置。

### Spring Boot 简化 Spring 的4点关键
* Spring 技术本身的`成熟和完善`，各种第三方组件的主动适配集成（Spring作为一种J2EE的实施标准），自动化装配技术的成熟。
* Spring 团队在`去web容器化`方面的努力。
    * 抽出 Tomcat 的内核 => “嵌入式 Tomcat”，放入依赖的JAR包。
    * Spring Boot 创建的web程序可以直接以工程JAR包运行，无需单独的 Tomcat web server容器依赖。
* 基于 `Maven`（JAVA构建、包管理、项目打包等环境的标准工具） 和 `POM`（Project Object Model，JAVA 的包管理、库依赖体系）的JAVA生态体系，整合POM模板。
* 避免大量 Maven 导入和各种版本冲突。
* 总结
    * Spring Boot 是 Spring 的一套快速开发、快速打包、快速运行的脚手架；关注`自动配置`，配置驱动。

### Spring Boot
#### 官网描述
* “Spring Boot 是创建独立运行、生产级别的Spring应用变得容易，你可以`直接运行`它。 ”
    * 翻译：Spring Boot 创建的应用可以直接运行。独立部署，不需要web容器。
* “我们对Spring平台和第三方库采用限定性视角，一次让大家能在最小成本上下手。”    
    * 翻译：开箱即用的默认装配。
* “大部分Spring应用仅仅需要少量的配置。”

#### 功能特性
* 创建`独立运行`的Spring应用
* 直接`嵌入Tomcat/Jetty/Undertow`，无需部署WAR包
* 提供`限定性的starter依赖`简化配置（“脚手架”）
* 在必要时`自动化配置`Spring和其他第三方依赖库
* 提供生产 produce-ready 特性，如指标度量、健康检查、外部配置等（系统运行过程中也有所帮助）
* 完全零代码生产，无需XML配置


## 2. Spring Boot 核心原理：27'24''
* Spring Boot 核心原理
    * `自动化配置`：通用的配置机制，简化配置核心。
    * `spring-boot-starter`：对应的框架技术和 Spring 框架做粘合。
* 配置
    * （入口）配置文件：application.yml 或 application.properties
        * 按`前缀`分组：相同前缀组成一组配置，提供给某个 `starter`；所有装配单元以 starter 组件为单位。
    * （加载）通过配置类加载成 Configuration，之后创建 Bean 并初始化。

* “约定大于配置”原则
    * 开箱即用，零配置
    * 默认约定
        1. `Maven 的目录结构`：默认resources文件夹存放配置文件，默认打包方式为 FatJar（打包所有依赖，有嵌入式web容器）
        2. 默认的`配置文件`（application.yml 或 application.properties）
        3. 多种配置文件，默认使用 `spring.profiles.active` 属性决定运行环境（开发/测试/生产）时的配置文件。
        4. `EnableAutoConfiguration` 默认对于依赖的 starter 进行自动装载。
        5. `spring-boot-start-web`（Spring和web的天然集成脚手架）中默认包含 spring-mvc 相关依赖以及内置的嵌入式web容器，简化了web应用的构建。

### 自动化配置
* run 起来！
    1. 应用程序的`入口`：类上加 `@EnableAutoConfiguration`注解，代码中使用 SpringApplication.run(ClassName.class, args) 运行。
    2. `配置类` WebConfiguration：类上加 `@Configuration`注解。
    3. `自动装配类` WebAutoConfiguration：类上加 `@Configuration`注解和 `@Import(WebConfiguration.class)` 注解。用来自动装配 WebConfiguration 配置类。
    4. `自动装配类` WebAutoConfiguration：类上加 `@Configuration`注解和 `@Import(WebConfiguration.class)` 注解。用来自动装配 WebConfiguration 配置类。
    5. resources 文件夹下创建 META-INF/spring.factories 文件：配置 `org.springframework.boot.autoconfigure.EnableAutoConfiguration=com.xxx.WebAutoConfiguration`，自动装配类的注入。

* Spring Boot 自动配置注解
    * `@SpringBootApplication`：说明当前类是 Spring Boot 的`主配置类`，通过运行当前类的 main() 方法即可启动 SpringBoot 项目。`核心启动入口`启动类。
    * @SpringBootConfiguration：自定义的加载。
    * @EnableAutoConfiguration：自动配置。
    * @AutoConfigurationPackage：包下的自动配置扫描。
    * @Import(WebConfiguration.class)：选择需要加载的类。
    * 加载所有在 resources 文件夹下的 META-INF/spring.factories 文件中存在的配置类。

* 条件化自动配置    
    * 为什么有这个？
    * `运行时灵活组装，避免冲突`。一套程序可以适应不同环境。
    * 例，@ConditionalOnBean（依赖某个Bean）, @ConditionalOnMissingBean（依赖某个Bean，没有Bean就初始化）, @ConditionalOnClass（依赖某个Class）, @ConditionalOnProperty（依赖某个属性）, @ConditionalOnResource（依赖某个资源）,@ConditionalOnSingleCandidate（有多个Bean，但自动化配置那个加了`@primary`的Bean）等等。还可以自定义条件，非常灵活。


## 3. Spring Boot Starter 详解：29'06''
* starter
    * 一个单独的子项目，单独打包；结构与一般的JAVA项目一致
    * 关键一：配置文件
        * spring.provides：写入当前 starter 的名字。
        * spring.factories：写入自动配置的类。
        * addtional-spring-configuration-metadata.json：描述当前 Spring Boot 组件的配置信息（类似Spring的XSD文件，校验配置文件的正确性以及自动提示）。
    * 关键二：SpringBootConfiguration类
        * 写入 spring.factories 文件中。
        * 是 Spring Boot 项目被拉起的入口点。
    * 不同环境下的配置文件：application-common.properties（可以用注解 @ActiveProfiles("common") 指定common环境，也可以在运行时加参数“--spring.active.profile=common”）


## 4. JDBC 与数据库连接池 / ORM-Hibernate / MyBatis：15'
### JAVA 数据库操作核心 API：JDBC
* 出发点：使用统一的编程模型访问不同的数据库
    * 通过 JDBC API 交互
* 每个数据库需要提供独一无二的驱动包，通过 DriverManager 加载
* 有了驱动，就可以创建与数据库服务器的远程连接 Connection
* 在 Connection 基础上创建会话 Statement
* ResultSet 表结构，作为数据库返回值
* 缓存优化定义：DataSource，Pool 连接池
* JDBC 接口的实现
    * 基于接口的好处：逐层包装，增强功能
    * 基于数据库的实际的 Connection，可以封装一个连接池 PooledConnection，再加上分布式的 XA 事务，变为 XAConnection.

### 数据库连接池
* 提高应用程序可用性的一些功能：池化，配置，探活，心跳，重连等。
* 常用连接池    
    * 早期：C3P0
    * DBCP（基于Apache 的 Commons 组件里的 CommonPool 组件，池化技术的通用底座）
    * Druid（阿里；自带对 SQL 性能的监控）
    * Hikari（Spring版本中的默认支持；稳定）

### ORM（对象和关系模型的映射）
* Hibernate    
    * 世界范围内流行的开源对象关系映射框架
    * 先配置面向对象的Bean，对象的属性和数据库字段一一对应；使用 HQL 操作对象中的属性，用面向对象的方式写 SQL；Hibernate 返回的数据自动变成配置好的映射关系。
    * 先定义`实体类`和 hbm 映射关系文件（描述类和数据库表的对应关系）。
    * 操作数据库的3种方式：HQL, Native SQL, Crtieria. 
        * 使用SQL进行操作时，Hibernate会针对不同数据库进行定制化转换。
    * 优势：可以使用JPA接口操作（作为JPA规范的适配实现）。

* MyBatis
    * 国内流行
    * 配置：可以用XML或注解配置映射，将接口和POJOs映射成数据库种的记录
    * 半自动化ORM
        * 原因一：需要使用 mapper.xml 映射文件定义map规则和需要使用的SQL
        * 原因二：需要定义 mapper类/DAO，基于XML规则操作数据库
        * 以上：可以使用工具生成基础的mapper.xml和mapper类/DAO
        * 使用经验：继承自动生成的mapper，可以很好地区分继承的和自己写的。无特殊需求，可以把SQL写在mapper接口的方法上。

* Hibernate vs MyBatis
    * 一般场景：Hibernate 使用更便利，不用写SQL。
    * MyBatis：原生SQL（XML语法；直观，无转换/变形）；DBA友好（事前SQL审计友好，性能分析调优方便）。繁琐。


## 5. Spring / Spring Boot 集成 ORM / JPA：46'18''
### JPA (Java Persistence API)
* 持久化API，基于ORM规范
    * 一组API，底层适配真正能做ORM的框架（Hibernate, OpenJPA, Toplink等）
* 操作实体对象
* 核心：EntityManager 实体的管理器

### Spring JDBC and ORM
* 封装JDBC接口，使用连接池等技术，操作管理DataSource ==> `Spring JDBC 组件`
* 封装JPA接口，操作EntityManager ==> `Spring ORM 包`
* Spring操作非关系型数据库：类似JPA操作关系型数据库（使用面向对象操作）

* `Spring 管理事务`
    * `声明式`事务配置：事务引入和管理的方式
        * JDBC层：`编程`式事务管理（手动声明、关闭、开启、回滚）
        * Spring：`事务管理器 + AOP`（拿到事务，没问题就提交，有问题就回滚；`无侵入`实现，业务代码不用显式地打开、提交、回滚事务，通过配置AOP切面管理事务）。
    * 事务的传播性：外层已开启一个事务，是否需要传播到内层。默认做到一个事务中 / 开启新事物 / 其他策略。
    * 事务的隔离级别：平衡线程安全和互相影响下的性能。不加锁 / 串行化（最严格）。
    * 只读
    * 事务的超时性
    * 回滚：指定单一异常类 / 多个异常类。

* Spring 集成 MyBatis
    * 首先扫描项目包
    * 包中的resources文件加下有各实体的mapper.xml配置
        * 实体类与数据库中的表的对应：字段，SQL操作
        * 配置数据源
        * 配置事务管理器
        * 配置 sqlSessionFactory：数据源，mapper.xml 的注入
        * mapper在MyBatis里相当于DAO：配置MapperScannerConfigurer扫描，加载实际的Mapper类（有@Mapper注解）
    * Spring Boot 集成更简单

* Spring 集成 Hibernate / JPA
    * 配置文件
        * 配置 `EntityManagerFactory`：注入数据源，指定JPA的适配器是Hibernate的JPA，指定实体类的位置，指定其他配置属性
        * 配置事务管理器（EntityManager接口由Hibernate适配器自动生成）
        * 其他类似上述配置MyBatis内容
    * 实体类：注解 @Entity，指定表名 @Table(name="xxx"), @Column(name="yyy")

### Spring / Spring Boot 使用 ORM 的经验
* 本地事务
* 多数据源
* 数据库连接池配置
* ORM内的复杂SQL，级联查询
* ORM辅助工具、插件