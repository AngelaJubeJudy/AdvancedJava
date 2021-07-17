# WEEK 1

## Obligatory

2.（`必做`）自定义一个 Classloader，加载一个 Hello.xlass 文件，执行 hello 方法，此文件内容是一个 Hello.class 文件所有字节（x=255-x）处理后的文件。

3.（`必做`）画一张图，展示 Xmx、Xms、Xmn、Meta、DirectMemory、Xss 这些内存参数的关系。
* 1. [√]打开 Spring 官网: https://spring.io/
* 2. [√]找到 Projects --> Spring Initializr:  https://start.spring.io/
* 3. [√]填写项目信息, 生成 maven 项目; 下载并解压。
* 4. [√]Idea或者Eclipse从已有的Source导入Maven项目。
* 5. [√]增加课程资源 Hello.xlass 文件到 src/main/resources 目录。
* 6. 编写代码，实现 findClass 方法，解码方法
* 7. 编写main方法，调用 loadClass 方法；
* 8. 创建实例，以及调用方法
* 9. 执行.

 

## Optional

1.（选做）自己写一个简单的 Hello.java，里面需要涉及基本类型，四则运行，if 和 for，然后自己分析一下对应的字节码。

4.（选做）检查一下自己维护的业务系统的 JVM 参数配置，用 jstat 和 jstack、jmap 查看一下详情，并且自己独立分析一下大概情况，思考有没有不合理的地方，如何改进。
注意：如果没有线上系统，可以自己 run 一个 web/java 项目。

5.（选做）本机使用 G1 GC 启动一个程序，仿照案例分析一下 JVM 情况。


## 提示
* JDK7及之前是永久代，`JDK8`及以后是Meta区。
* 常量池位于方法区之中, 方法区位于`Meta区`之中
* Mata区占用的是`非堆`内存，不是堆外内存，也不是直接内存
* 直接内存(Direct)属于堆外内存，不属于非堆，和Meta不在一起
* 堆外内存(Direct, Native),实际上位于`JVM进程内部`
* `直接内存`，和栈是不同的空间。
* -Xmx 和 -Xms 设置的是整个堆内存的大小，而不是老年代。
* 和年轻代(young/nursery)不一样，新生代实际上是 Eden 区, 由 -Xmn 与存活区的比例来控制
* 栈内存不在堆内存之中，是另一个独立的部分。 -Xss 控制的是一个线程的栈空间大小
* 注意区分线程栈以及内部的栈帧结构。
* 编码风格: 建议增加`中间变量`，增加可读性，可读性和可维护性是构建大型复杂系统的基石。
    * 注意`关闭输入输出流`，最好是在哪里打开，就在同一个方法内将其关闭。
