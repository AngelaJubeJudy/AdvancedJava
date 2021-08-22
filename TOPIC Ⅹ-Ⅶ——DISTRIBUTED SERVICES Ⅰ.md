# TOPIC Ⅹ-Ⅶ: DISTRIBUTED SERVICES Ⅰ——分布式服务化 
## 1. RPC 基本原理及技术框架：31'55''
### RPC 基本原理
* RPC, Remote Procedure Call 远程过程调用
    * 用于异构型分布式系统间的通讯
    * 像调用本地方法一样调用远程方法
        * Stub 存根进程：远程的本地代理
        * Stub + RPC Runtime：屏蔽了远程过程调用的网络调用细节，负责参数的编解码、网络通信
        * 例：
        ```java
        // 生成远程调用的本地存根 Stub；'Rpcfx'，RPC框架
        UserService service = Rpcfx.create(UserService.class, url);
        // 本地存根 Stub service 拦截请求
        User user = service.findById(1);
        ```
    * 思考：如何做到本地方法调用时转换成远程？

* 简化版 RPC 原理————“像调用本地方法一样调用远程方法”
    0. client 端本地调用
    1. 本地代理存根：Stub
    * 拦截请求本身的信息：server URL，参数，方法等
    2. 本地序列化/反序列化
    * 打包请求本身的信息并序列化成二进制
    3. 网络通信
    * 通过 socket 将请求发送给服务器端
    4. 远程序列化/反序列化
    * 服务器端反序列化出请求本身的信息
    5. 远程服务存根：Skeleton
    * 找到对应的远程的本地的服务实现
    6. 调用实际业务服务
    7. 原路返回服务结果
    * 成功 / 失败
    8. 返回结果给本地调用方
* 注意处理异常！

* 5个关键原理
    1. `设计`：RPC 是`基于接口`的远程服务调用
    * client 端和 server 端必须`共享`信息：“`服务契约 / 服务的接口契约（Service Contract）`”
        * POJO实体类定义（方法参数和返回值，实体类的定义）
        * 接口的定义
        * `服务契约`的定义
            * REST: WADL，or，接口文档
            * WebService: WSDL 
            * PB(Protocol Buffer): IDL 
    * 角色定义：
        * 远程 = service provider
        * 本地 = service comsumer
    2. `代理`：接口的动态代理/实现类
    * JAVA的实现：动态代理，AOP实现
    * C#的实现：有远程代理
    * Flex的实现：可以使用动态方法和属性
    3. `序列化`
    * 3种类型
        * 语言原生的序列化（无需引入第三方包即可使用；不能跨平台使用）：RMI, Remoting
        * 二进制（平台无关，跨语言使用；数据量小，信息精简）：Hessian, avro, kyro, fst 等
        * 文本（天然跨平台；人类友好，数据量较大）：JSON, XML 等
    4. `网络传输`
    * 方式一：TCP/SSL/TLS（安全传输层协议TLS与应用层协议无缝耦合，创建加密通道需要的认证）；性能更好
    * 方式二：HTTP/HTTPS
    5. `查找实现类`
    * 通过接口查找服务端的实现类；skeleton
        * 一般通过`注册`的方式（例，Dubbo）

### RPC 技术框架
* RPC 技术框架
    * 各语言内置：（JAVA）RMI，（.NET）Remoting
    * 远古时期
        * Corba (Common Object Request Broker Architecture)：公共对象请求代理体系结构
            * 底层结构基于面向对象模型
            * 模块组成：OMG接口描述语言（OMG Interface Definition Language, OMG IDL），对象请求代理（ORB），IIOP标准协议（网络ORB交换协议）
        * COM (Component Object Model)：组件对象模型
            * 组件技术
            * 平台无关、语言中立、位置透明、支持网络的中间件技术

* 常见的 RPC 技术
    * 类型一：Corba / RMI /.NET Remoting
    * 类型二（基于 HTTP 的规范）：JSON RPC, XML RPC, WebService (2个框架：Axis2, CXF)
    * 类型三（序列化基于二进制）：Hessian, Thrift, Protocol Buffer, gRPC
        * Hessian：基于 HTTP，二进制序列化方式；性能高，使用广泛。
        * Thrift：基于 TCP，二进制序列化方式；早期一个 server 端口开启一个服务进程，无需查找服务实现，现一个端口支持多个服务。
        * gRPC：当前云原生环境下的 RPC 标准（实现借鉴了PB）。


## 2. 如何设计一个 RPC：25'8''
### 设计一个 RPC 框架
* 思考
    * 基于共享接口/IDL？
    * 动态代理 / AOP？
    * 序列化用什么？基于文本/ 基于二进制？
    * 网络传输基于 TCP 还是 HTTP？
    * 服务端如何查找实现类？（实现类和接口绑定的 skeleton 的设计）
    * 异常处理（在服务端处理异常，返回封装后的结果和标识位给 client 端）

* 实战：rpc01 项目
    * `rpcfx-core：框架核心`
        * api 部分：定义请求（封装了接口名、方法名、参数列表）、响应（结果集、状态、封装的异常）
        * client 部分（class Rpcfx）：
            * 创建代理
            * 实现对远程服务器的调用（RpcfxInvocationHandler，调用时运行 invoke()，将接口名、方法名、参数列表封装在 request 对象里，request 对象通过 OkHttp 请求传给服务端）
        * server 部分（class RpcfxInvoker）：RpcfxResponse invoke(RpcfxRequest request)，通过 resolver 先将接口名转换为本地的服务实现类，通过反射拿到本地方法，结果序列化后封装在 response 对象里，状态成功 / 异常序列化后封装在 response 对象里，状态失败。
    * rpcfx-demo-api：接口的定义，实体类的定义（共享）
    * `rpcfx-demo-consumer：服务的消费者`
        * 首先创建动态代理（使用服务端配置暴露的服务路径）
        ```java
        UserService userService = Rpcfx.create(UserService.class, "http://localhost:8080/");
		User user = userService.findById(1);
		System.out.println("find user id=1 from server: " + user.getName());
        ```
        * invoker 中封装 request 对象
        * OkHttpClient 辅助发送请求、接受响应
    * `rpcfx-demo-provider：服务的提供者`
        * 暴露一个路径: http://localhost:8080/，将请求信息自动转换为一个 request 对象；结果封装为 RpcfxResponse 类型
        ```java
        @PostMapping("/")
        public RpcfxResponse invoke(@RequestBody RpcfxRequest request) {
            return invoker.invoke(request);
        }
        ```
        * 将服务注册到 Zookeeper
        * invoker 中通过 resolver 查找到 Spring 实现类，通过 getBean 拿到具体实现

* RPC 原理一：`设计`
    * 实战：rpcfx 里的 API 子项目
    * 共享 POJO 实体类定义和接口定义
* RPC 原理二：`代理`
    * 实战：rpcfx 里的默认使用动态代理
    ```java
    public static <T> T create(final Class<T> serviceClass, final String url, Filter... filters) {
        return (T) Proxy.newProxyInstance(Rpcfx.class.getClassLoader(), new Class[]{serviceClass}, new RpcfxInvocationHandler(serviceClass, url, filters));
    }
    ```
    * 其他方式：字节码生成技术，生成运行时的实现类
* RPC 原理三：`序列化`
    * 实战：rpcfx 里的默认使用 JSON
    ```java
    // 序列化
    String reqJson = JSON.toJSONString(req);
    System.out.println("req JSON: " + reqJson);
    // 反序列化
    return JSON.parse(response.getResult().toString());
    ```
* RPC 原理四：`网络传输`
    * 实战：rpcfx 里默认使用 HTTP
    ```java
    OkHttpClient client = new OkHttpClient();
    ```
* RPC 原理五：`查找实现类`
    * 实战：
        * rpcfx 里默认使用 Spring getBean 
        ```java
        @Override
        public Object resolve(String serviceClass) {
            // 根据 serviceClass 接口名查找 Bean
            return this.applicationContext.getBean(serviceClass);
        }
        ```
        * rpcfx 里服务实现类的注册
        ```java
        @Bean(name = "xxx.api.UserService")
        public UserService createUserService(){
            return new UserServiceImpl();
        }

        @Bean(name = "xxx.api.OrderService")
        public OrderService createOrderService(){
            return new OrderServiceImpl();
        }
        ```

### 从 RPC 到分布式服务化
* 大规模`分布式业务场景`里的考虑
    * 多个相同服务如何管理？
    * 服务的注册发现机制
    * 如何做到负载均衡、路由等集群功能？
    * 请求量较大时，熔断、限流等治理能力
    * 重试等策略
    * 高可用、监控、性能等

* 典型的分布式服务化架构
    * 大规模分布式服务化下的 RPC 增强：在 client 端和 server 端对 RPC 本身的机制做增强。
    * `注册中心`
        * 多个服务的提供者（多个服务端）
        * 从服务端到注册中心：注册中心知晓每个服务的可用实例，与服务部署状态一致。
        * 从注册中心到客户端：住粗中心通过客户端的服务发现去更新自己的服务列表。
    * 客户端
        * `服务发现`
        * client————调用模块：负载均衡，容错，透明
        * RPC 协议：序列化，协议编码，网络传输（双向传输）
    * 服务端
        * `服务暴露`
        * server————处理程序
        * 线程池
        * RPC 协议：反序列化，协议解码，网络传输（双向传输）

