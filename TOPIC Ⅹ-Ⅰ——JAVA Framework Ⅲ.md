# TOPIC Ⅹ-Ⅰ: JAVA Framework Ⅲ

## 0. 总览
* JAVA8 Lambda 表达式：提升代码效率
* JAVA8 Stream 编程：提升代码效率
* Lombok 工具（借鉴其他语言中的特性）：简化代码
* Guava：JDK 上的工具增强

## 1. JAVA8 Lambda：40'3''
### Lambda 表达式
* Lambda 表达式
    * 可以看作一个匿名函数（不需要中间对象来表示，定义出来当作一个函数使用即可）
    * Lambda 演算体系（Lambda 演算模型与图灵机模型等价，可以作为计算机最底层的模型，也是图灵完备的）
    * 相当于一个`函数/方法签名`：Lambda 表达式通过参数、返回值等，无需方法名，就能作为用来唯一描述方法的签名。

* JAVA Lambda 表达式
    * 优势：简化了代码编写和实现。
    * JAVA 面向对象（所有函数/方法必须属于某个类） vs 面向函数（变量可以定义为函数；例，Scala）
    * `内部匿名类`：作为匿名函数的载体
    * 函数有无返回值在使用 Lambda 表达式中不做区分。（实现和编程模型上有差异）
    * `写法一：(parameters)->{statements;}`
    * `写法二：(parameters)->expression`
    * 注：JAVA 中使用 '->'，其他语言中多使用 '=>'.

* JAVA Lambda 表达式分类
    * 无参，有返回值："() -> 5"
    * 一个入参（可以省略参数的括号），返回值与入参相关："x -> 5*x"
    * 多个入参，返回值与入参相关："(x, y) -> y-x"
    * 明确指定入参的约束类型，返回值与入参相关："(int x, int y) -> y-x"
    * 入参为一个对象，无返回值："(String s) -> System.out.println(s)"

* JAVA8 vs JAVA7
    * 示例1：关键信息——接口 MyLambdaInterface 以及 接口方法 a(String s)。
        * JAVA8："MyLambdaInterface aBlkOfCode = (s)->System.out.println(s);"
            * 省略了参数 s 的类型，使用范围更广。
        * JAVA7：先实现一个接口 MyLambdaInterface 的类 MyInterfaceImpl，在类中重载接口方法；使用时实例化 "MyLambdaInterface anInterfaceImpl = new MyInterfaceImpl();"；或者用匿名类的方式。总之都要实现或表示一个类才能实现重载方法。
    * 示例2：关键信息——无返回值的方法，入参(MyLambdaInterface myLambda, String s)，方法体中调用了接口的重载方法。
        * JAVA8："enact(`s -> System.out.println(s)`, "Hello, world")"
        * JAVA7：先显示地实现接口，然后实例化具体的实现类，最后将变量传递给接口重载方法，实现调用。"enact(`anInterfaceImpl`, "Hello, world")"
        * 简化思路：用 Lambda 表达式代替了显示的类/匿名类（高亮部分）。

* 深入 JAVA8 函数式编程
    * 注解：@FunctionalInterface 
    * 接口
        * Predicate<T>：有入参，做条件判断后返回 true/false（类似断言）。
        * Function<T, R>：有入参，有返回值。
        * Consumer<T>：有入参，无返回值。“过程”。
        * Supplier<T>：无入参，有返回值。
        * 优化：使用更精确和明确的“`方法引用`”来表达函数式的封装接口。
            * 用上述4种类型来代表 Lambda 表达式；帮助封装 Lambda 表达式。
            * 例：通过 "ClassName::new" 来引用类的构造函数。

* JAVA 中的泛型（伪泛型）
    * “`擦除法`”：在编译后的字节码文件中无泛型信息；每次用到时进行一次类型检查。
    * 定义泛型时：对泛型进行约束；例，接口的子类（JAVA 支持接口的多继承/多实现），通过 extends Interface1&Interface2&....&Interfacen 实现。入参必须实现所有接口（否则约束不通过）！


## 2. JAVA8 Stream：35'32''
* 优势：大大简化了`集合编程`。
* 将一批数据当作stream流来操作。
    * 数据以集合形式来操作，集合在 JAVA8 中使用`泛型`来表示其元素。
        * 泛型`运行期`的判断：可以通过`反射`获取泛型对象的元数据。
        * 例，List<T> & List<User> & List<AppUser>.
        * 伪泛型：List<AppUser> 与 List<User> 无关。
        * 真泛型：List<AppUser> 可能是 List<User> 的一个子类型；类型真实存在。
        * `多个泛型约束条件`：通过 <T extends Interface1&Interface2&....&Interfacen> 实现。

* 流
    * 来自`数据源`的`元素队列`，并且支持`聚合操作`。
    * 关键词一：元素队列。元素排好队等待加工处理，类似流水线。
    * 关键词二：数据源。可以是数组、集合、I/O Channel、generator 等。
    * 关键词三：聚合操作。例，filter, map, reduce, find, match, sorted 等。
    * 流的操作 vs 集合上的操作
        * Stream 最重要的使用特征：`Pipelining`. Stream 上的各种操作串成一个管道流水线，流水线内部可以对一系列处理进行优化。
        * 内部迭代：无需显式迭代（迭代器/For循环），使用 `Visitor 模式`，则所有流的处理相当于附加在流上的 Visitor 模式。
    * 流的创建：使用集合类型（List, Collection 等类型 .stream），数组（Arrays.asStream()）。

* Stream 操作
    * `中间操作`：流不被截断。
        * 选择与过滤：
            * filter(Predicate p)，保留流中断言结果是true的元素。
            * distinct() 去重。
            * limit(long maxSize) 截断流，其他元素还可以继续流动。
            * skip(long n) 跳过前 n 个元素；不足 n 个返回空流。
        * 映射：
            * map(Function f)：将元素逐个转换成其他形式。
            * mapToDouble(ToDoubleFunction f)：转换成 Double 形式。
            * mapToInt(ToIntFunction f)：转换成 Int 形式。
            * mapToLong(ToLongFunction f)：转换成 Long 形式。
            * flatMap(Function f)：折叠在集合类型中的元素全部平铺在流中。
        * 排序（产生新流）
            * sorted()：按自然顺序。
            * sorted(Comparator comp)：在比较器中实现 CompareTo() 方法，复杂的排序策略。
    * `终止操作`：截断，汇总流上数据得到结果并返回。
        * 查找与匹配：allMatch, anyMatch, noneMatch, findFirst, findAny, count, max, min.
        * 归约：reduce（需要初始值）
        * 收集：collect
            * toList List<T>, toSet Set<T>, toCollection Collection<T>, count, summaryStatistics 统计
        * 迭代：forEach
            * 例，
            ```java
                map.forEach((k, v) -> System.out.println("key:value = " + k + ":" + v));
            ```

* 实战
    * 集合：CollectionDemo.java
    * 流：StreamDemo.java
        * 流操作中间处理过程的结果全部被包装为 `Optional，避免链式操作过程中的空指针异常`。例，first 被包装为 Optional 而不是直接 Integer 类型，
        ```java
        Optional<Integer> first = list.stream().findFirst();
        ```
        * 例，归约中的初始值，
        ```java
        // 0, 1, 2, 3：初始值放在流的最前面，第一个元素和0一起归约运算 0+1
        int sum = list.stream().filter( i -> i<4).distinct().reduce(0,(a,b)->a+b);
        System.out.println("sum="+sum);
        // 1, 1, 2, 3：初始值放在流的最前面，第一个元素和0一起归约运算 1*1
        int multiply = list.stream().filter( i -> i<4).distinct().reduce(1,(a,b)->a*b);
        System.out.println("multiply="+multiply);
        ```
        * list.stream().parallel() 与 map.entrySet().parallelStream()：告诉JVM在执行stream操作时可以使用线程池，用并行的多线程。
    * Fluent API：一直不需要中断。
    * 终止操作：


## 3. Lombok / Guava：33'37''
### Lombok
* 常规写JAVA对象需要：getter, setter, toString()，有参无参构造函数
* Lombok类库：Builder自由构造函数，链式构造初始化，自动生成logger（不用在每个类显式定义一个logger），
    * 优势：借助`注解`，控制有固定操作模式的行为。
    * 注解：@Setter, @Getter, @Data 组合（5种注解的组合）, @XXXConstructor 各种构造函数, @Builder 链式操作, @ToString, @Slf4j 动态在类中添加logger。
        * 空参构造函数——@NoArgsConstructor，全参构造函数——@AllArgsConstructor
        * @Data: Equivalent to @Getter @Setter @RequiredArgsConstructor @ToString @EqualsAndHashCode.
    * 实战：LombokDemo.java

### Guava
* 增强优化
    * 用于集合、缓存，支持原语、并发性、常见注解、字符串处理、I/O、验证的实用方法。
* 好处
    * 标准化：Google 托管。
    * 高效，可靠：快速有效扩展了 JAVA 标准库。
    * 优化

#### 功能
* `Collections————对 JDK 集合的扩展`
    * 不可变集合 => 做防御性编程（在合作、线程安全的场景下有意义）
    * 新集合类型 => 多值的、双向的
    ```java
    private static void testMap(List<Integer> list) {  // 多值
        //Map map = list.stream().collect(Collectors.toMap(a->a,a->(a+1)));
        Multimap<Integer,Integer> bMultimap = ArrayListMultimap.create();
        list.forEach(a -> bMultimap.put(a,a+1));
        print(bMultimap);
    }
    private static void testBiMap(List<String> lists) {  // 双向
        BiMap<String, Integer> words = HashBiMap.create();
        words.put("First", 1);
        words.put("Second", 2);
        words.put("Third", 3);
        
        System.out.println(words.get("Second").intValue());  // 通过 key 找 value
        System.out.println(words.inverse().get(3));  // 通过 value 找 key
        
        Map<String,String> map1 = Maps.toMap(lists.listIterator(), a -> a+"-value");
        print(map1);
    }
    ```
    * 强大的集合工具类 => 提供 java.util.Collections 中没有的集合工具
    * 扩展工具类
* Caches————内置 `Guava Cache` 实现，`本地缓存`
    * 使用Builder模式添加配置参数：CacheBuilder.newBuilder().XXX().yyy()....
        * 容量，超时时间，数据移除监听器
    * 实际应用：ZooKeeper 的 client 端的缓存。
* `Concurrency————并发`
    * 实现 ListenableFuture，可以完全`异步`使用的 Future，Future 上添加一个 callback
* `Strings————字符串处理`
    * 拼接、拆分、填充等`细节`处理
    ```java
    private static List<String> testString() {
        // 字符串处理
        List<String> lists = Lists.newArrayList("a","b","g","8","9");

        String result = Joiner.on(",").join(lists);
        System.out.println(result);
        
        String test = "34344,,,34,34,blahblbah";
        lists = Splitter.on(",").splitToList(test);
        System.out.println(lists);
        return lists;
    }
    ```
* `EventBus————事件总线`
    * 实现进程内的调用方和被调用方之间的`解耦`：发布-订阅模式的组件通信
        * 调用方 post 事件 & 被调用方处理事件：`时序上同步，处理上异步`（调用方和被调用方可以在不同包中实现）
    ```java
    static EventBus bus = new EventBus();
    static {
        bus.register(new GuavaDemo());  // 注册当前类到 EventBus 上
    }

    private static void testEventBus() {
        Student student2 = new Student(2, "KK02");
        System.out.println(Thread.currentThread().getName()+" I want " + student2 + " run now.");
        bus.post(new AEvent(student2));  // 调用方：post 事件
    }
    
    @Data
    @AllArgsConstructor
    public static class AEvent{
        private Student student;
        public AEvent(Student student2) {
        }
    }
    
    @Subscribe
    public void handle(AEvent ae){  // 被调用方：可以处理 AEvent 类型的事件
        System.out.println(Thread.currentThread().getName()+" "+ae.student + " is running.");
    }
    ```
    *  Q：如何打破模块间的依赖关系，产生反向调用？
    * 【方式一：Spring IoC AOP 注入】
    * 【方式二：SPI + ServiceLoader】JDK的机制：SPI (Service Provider Interface) + ServiceLoader.load
        * SPI：框架本身提供了一个接口，没有实现，需要扩展自己实现，再注入容器。
    * 【方式三：Callback/Listener 机制】项目的模块A 实现 Listener 机制，Listener 集合中存放需要调用的接口实例。同一项目的模块B 实现接口，然后将接口的实现类塞入模块A 的 Listener 集合。则模块A 在执行代码时可以用接口类型的方式挨个调用集合中的实现。
    * 【方式四：EventBus】模块A 中 new 出一个全局的 EventBus，定义某种 Event 类型（例，AEvent）。模块B 实现处理 AEvent 类型事件的方法（入参为 AEvent 类型的事件），加上 @Subscribe 注解，并将所在的实现类注册到全局的 EventBus。调用方 post 一个 AEvent 类型的事件，模块B 中的方法就会被调用处理事件。
* `Reflection————反射`
   

## 4. 设计原则与模式、单元测试：49'20''
### 设计原则
* `面向对象`的设计和编程原则：`SOLID`
    * The Single Responsibility Principle：每个类只做一件事（多功能解耦）。
    * The Open Closed Principle：每个类对于修改封闭，对于扩展开放（更强复用）。
    * The Liskov Substitution Principle：相同接口的不同子类在实例化定义时等价。
    * The Interface Segregation Principle：每个接口都是单独的抽象，隔离；不同的实现类应尽量少依赖接口/抽象类。
    * The Dependency Inversion Principle：上层不依赖下层，抽象不依赖于实现。

* 最小知识原则：KISS
    * 目标：`高内聚，低耦合`————可扩展、可维护的代码设计原则
    * 上下游依赖关系较少，单线依赖

* 编码规范：消除歧义
    * [Google](https://google.github.io/styleguide/javaguide.html)
    * [Ali](https://github.com/alibaba/p3c)：扩展了命名和数据库等相关规范。

### 设计模式
* `GoF 23`：23个经典设计模式————`面向接口`编程，特定场景下的通用解决经验。
    * `创建型`（对象的创建）：Factory Method, Abstract Factory, Builder, Prototype, Singleton.
    * `结构型`（对象的组装、转换）：Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy. 
    * `行为型`（对象的特定功能实现）：Interpreter, Template Method, Chain of Responsibility, Command, Iterator, Mediator, Memento, Observer, State, Strategy, Visitor.

* 设计模式与反模式
    * 模式的3个层次
        * 解决方案层：宏观架构
        * 组件层：框架
        * 代码层（GoF 23）
    * 其他模式
        * EIP：企业集成模式
        * 事务模式
        * I/O 模式
        * Context 模式
        * 状态机
    * 反模式 = 死用模式

### 单元测试
* 单元测试 = 白盒测试 + 自动化测试
    * 基本假设：其他零件都是好的，仅测试当前零件
* 测试粒度（小 -> 大）：单元测试（业务方法；开发人员编写，数量>业务方法） -> 集成测试（服务） -> 功能测试（端到端；UI） 
* 优势
    * 明确所有的边界处理
    * 保证代码符合预期
    * 在开发时期提前发现问题，降低 bug 修复成本
    
* 工具
    * JUnit: TestCase, TestSuite, Runner
        * 每个测试方法：TestCase
        * 一组测试方法：TestSuite
        * Runner：运行 TestSuite
        * 单线程运行
    * SpringTest
    * Mock 技术
        * Mockito
        * easyMock
* 经验
    * 每个方法一个case，且断言要充分、提示要明确
    * 应覆盖所有边界条件
    * 充分使用 Mock
    * 不好写测试，则反向优化代码（解决代码设计中的问题）
    * 批量测试使用参数化的单元测试
    * 默认是单线程的（不同操作系统上执行顺序不同，单测有可能失败，“环境污染问题”）
        * 尽量少地修改全局变量
        * （下一条）
    * 合理使用 before, after, setup 准备环境
    * 合理使用通用测试基类（避免重复）
    * 配合 checkstyle、coverage 等工具
    * 制定单测覆盖率基线

* 常见陷阱
    * 尽量不使用外部的数据库和资源
    * 若必须使用外部数据库和资源，考虑嵌入式数据库、事务的自动回滚
    * 静态变量污染问题
    * 测试方法的顺序在不同环境下不一致问题
    * 单测总时间较长的问题