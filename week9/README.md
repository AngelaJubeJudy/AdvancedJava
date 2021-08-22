# WEEK 9

## Obligatory

3. （`必做`）改造自定义 RPC 的程序：

* 尝试将服务端写死查找接口实现类变成泛型和反射；
    * 在 RpcfxInvoker.java 中，
    ```java
    // Object service = resolver.resolve(serviceClass);//this.applicationContext.getBean(serviceClass);
    // 作业1-1：改成泛型
    GenericService service = (GenericService) context.getBean(serviceClass);

    // ...
    
    // Object result = method.invoke(service, request.getParams()); // dubbo, fastjson,
    // 作业1-2：反射调用
    Object result = service.$invoke(request.getMethod(), request.getParams());
    ```

* 尝试将客户端动态代理改成 AOP，添加异常处理；
    * Spring AOP 的使用
        * Spring中的一个类：可以注册成 Spring 中的一个 Bean（之后 Spring 将其初始化成一个可用对象）。
            * 需要做增强/做切面：中间加`代理类/增强类` 
            * 基于接口的类的对象：默认使用 `jdkProxy (JDK的动态代理)`，`生成代理`；对象的增强操作放在代理的方法代码中，最终再调用原始的对象，返回结果。
        * `代码（AOP 的类） + XML`（将 AOP 的类注册成一个 Bean。然后定义 pointcut 和 aspect，匹配；这样代码和切面就能作用到所有切点上，即切点上发生切面）

* 尝试使用 Netty + HTTP 作为 client 端传输方式。

--------------------------------


7. （`必做`）结合 dubbo + hmily，实现一个 TCC 外汇交易处理，代码提交到 GitHub:

* 用户 A 的美元账户和人民币账户都在 A 库，使用 1 美元兑换 7 人民币 ;
* 用户 B 的美元账户和人民币账户都在 B 库，使用 7 人民币兑换 1 美元 ;
* 设计账户表，冻结资产表，实现上述两个本地事务的分布式事务。


## Optional

1. （选做）实现简单的 Protocol Buffer/Thrift/gRPC(选任一个) 远程调用 demo。

2. （选做）实现简单的 WebService-Axis2/CXF 远程调用 demo。

4. （选做☆☆）升级自定义 RPC 的程序：

    尝试使用压测并分析优化 RPC 性能；
    尝试使用 Netty + TCP 作为两端传输方式；
    尝试自定义二进制序列化；
    尝试压测改进后的 RPC 并分析优化，有问题欢迎群里讨论；
    尝试将 fastjson 改成 xstream；
    尝试使用字节码生成方式代替服务端反射。

--------------------------------

5. （选做）按本周学习的第二部分练习各个技术点的应用。

6. （选做）按 dubbo-samples 项目的各个 demo 学习具体功能使用。

8. （挑战☆☆）尝试扩展 Dubbo

    基于上次的自定义序列化，实现 Dubbo 的序列化扩展 ;
    基于上次的自定义 RPC，实现 Dubbo 的 RPC 扩展 ;
    在 Dubbo 的 filter 机制上，实现 REST 权限控制，可参考 dubbox;
    实现一个自定义 Dubbo 的 Cluster/Loadbalance 扩展，如果一分钟内调用某个服务 / 提供者超过 10 次，则拒绝提供服务直到下一分钟 ;
    整合 Dubbo + Sentinel，实现限流功能 ;
    整合 Dubbo 与 Skywalking，实现全链路性能监控。
