# TOPIC Ⅷ: JAVA Concurrent Programming Ⅲ
## 1. 常用线程安全类型 / 并发编程相关内容：65'27''
* 引入问题：常用的集合类型都是线程不安全的。怎样实现线程安全的集合类型，从而在多线程的环境下使用集合类并保证应用程序的正确执行和数据的一致性？

### JAVA 常见集合类型
* JAVA 中的三个基础类型
    * 原生类型：int, float, long, double
    * 数组类型
    * 对象引用类型
    * 注：以上三种数据类型的嵌套构成了 JAVA 的所有数据类型。
* 集合类：在 java.util 包中
    * 线性数据结构三小类都是 interface，父类为 `Collection`（接口有迭代器定义） 
    * `线性`数据结构（一维）：`List` (ArrayList, LinkedList, Vector, Stack), `Set` (LinkedSet, HashSet, TreeSet), `Queue` -> Deque -> 子类 LinkedList
    * `键值类型`数据结构：Map (HashMap, LinkedHashMap, TreeMap), Dictionary -> 实现 HashTable -> 子类 Properties（默认只处理字符串的KV）
* 线程不安全（代码执行结果可能和预期不一致）

### List
#### ArrayList
* 基于数组实现，支持按下标访问元素
* 扩容操作，成本较高（因数据转移复制）；默认长度为10，扩容后为原来的1.5倍（向下取整为整数长度）
* 安全问题
    * ArrayList 的实现是线程不安全的。
    * `写冲突`：数据修改未考虑并发情况。
    * `读写冲突`：读写同一元素时发生数据不一致，拿到非预期数据，抛出 OutOfIndexArrayBound / ConcurrentModificationException 等异常。

#### LinkedList
* 基于链表实现；每个数据在内部是一个 Node，结构中包括数据 item，以及两个指针 prev 和 next，指向下一个和前一个 Node（双向链表）。同时 LinkedList 保存了第一个节点、头结点 first 和最后一个节点 last.
* 有默认大小；不需要指定大小，没有容量大小限制
* 安全问题
    * 写冲突
    * 读写冲突

### 线程安全
* solution-1: `读写操作都加锁`
    * 大锁
    * ArrayList 中所有的方法都加 synchronized：Vector类的实现。
    * 新的 List 实现原有类的包装：工具类 Collection 中有很多静态方法。如 Collections.synchronizedList(List<T> list)，强制将 List 操作都加上同步。
    * Arrays 工具类中的 asList 方法，生成不允许添加、删除的 List，可替换元素。
    * Collections 工具类中的 unmodifiableList 静态方法，生成只读 List，不允许增删改。
* solution-2：CopyOnWriteArrayList 类
    * 写————对写加锁（串行写；全局的锁 this.lock）
    * 读————快照思维：每个线程无锁并发读原容器，写的时候在各自的副本上（需加锁），写完替换原容器引用的指针即可（切换过程用 volatile 保证切换对读线程立即可见）。整个过程中，原容器没有任何变化。
    * 实现了`读写分离`：`最终一致`。
    * 适用场景：读多写少时高效处理。
    * 迭代器 COWIterator：迭代过程中用的是当前数组对象的快照（不会变）。

### Map
#### HashMap
* 空间换时间
* 填入数据量大：哈希冲突
    * 容量不要装太满，否则容易引起哈希冲突。
    * 负载因子：0.75，扩容到原来的2倍；太小，性能好但空间浪费多。
    * solution 之链表法：槽上是一个链表，每个节点是一个 Entry，包含k和v。
    * solution 之红黑树（从 N 到 logN）：JDK 8 以后，链表长度到8 & 数组长度到64时构建（数据规模较大时）。
* 安全问题
    * 写冲突
    * 读写冲突
    * `keys() 无序`：扩容时，因为取模的底数改变，一些数据可能就不在当前槽位的链表中了；如果过程中还有其他线程在读数据，有可能在扩容过程中形成死循环。

#### LinkedHashMap
* 父类：HashMap
* 改进：对 Entry 集合添加了一个双向链表，保证了所有元素在链上的分布是`有序`的。
    * 有序：支持插入顺序和访问顺序（应用：LRU 缓存）。
* 安全问题：同 HashMap

#### ConcurrentHashMap
* HashMap 线程不安全的改进：分段锁（大锁的改进）
* 原理：一个大的 HashMap 中定义16个 segment，降低锁粒度。
    * `concurrentLevel` = 16；“`并发级别`”，可调
    * 每个段里是一个完整的 HashMap
    * 最多允许16个线程并发地操作16个 segment
* 退化（所有并发线程都focus在同一个segment时）：HashMap + 大锁
* 类似数据库的分库分表
* JAVA 7中
    * 第一次哈希取模：使用 hashcode 的高位数据 
    * 每个 Segment 内的哈希取模：和院线一致 
* JDK 8中s
    * 大规模 HashMap 时使用红黑树代替链表
    * 去掉了segment，因为红黑树有天然的分支
    * 可以采用无锁技术（乐观锁 CAS 等）

### 并发集合类的线程安全问题解决方案总结
* ArrayList, LinkedList：采用“副本机制”做改进————CopyOnWriteArrayList
    * 读：副本
    * 写：根据副本生成一个新的数组对象，写操作，然后替换原副本的引用
* HashMap, LinkedHashMap：采用分段锁或 CAS 做改进————ConcurrentHashMap
    * segment 降低锁的粒度
    * 无锁机制


## 2. 并发编程经验总结：22'19''

### 并发编程相关内容：4种经典利器
* ThreadLocal 类
    * 每个线程本地的变量读写的机制：线程间`数据隔离`
    * 解决的问题：并发的线程安全问题
        * Q：一个方法要调用很多其他方法，最里层的调用又需要最开始这个方法中某个变量。
        * solution 1: 全局变量（代码改动量小，但线程间共享，还会有并发安全问题）。
        * solution 2: 显式传递参数（逐层直到最里层的调用处；代码改动量大）。
        * sulition 3: ThreadLocal 类。
    * 同一个线程，跨方法（其中可能有不可修改的框架方法）调用栈地调用：最外层将要操作的数据放入 ThreadLocal.
    * 在`当前线程内部`进行变量和数据的传递。

* Stream in JDK8
    * parallel() 方法：将单线程执行变成并行多线程的线程池处理。
        * 创建出和当前 CPU 核心数大小一致的线程池。
    * 思路：`流水线化的处理模型`，将批量数据的`单线程处理和多线程的并发处理`在接口编程 API 模型使用层面做了统一。

* 伪并发问题
    * 与并发冲突类似的问题，由并发类型的操作触发 
    * 例：表单的大量重复提交
        * 浏览器端：隐藏按钮 / 移除点击事件；（弊端）不安全
        * 服务器端：session 中的表单编号在服务器端验重

* 分布式下的锁和计数器
    * 分布式环境下，超出了线程的协作机制，是`并行`的操作。
    * 例：秒杀时，大量用户并发捡库存。
        * 全局锁

### 经验与原则
#### 加锁前的考虑
* 粒度：能小则小（意味着大部分代码可以并发执行）
* 性能（提升效率）
* 重入（防止自己卡死）
* 公平（防止线程饿死）
* 自旋锁（Spinlock，大大降低使用锁的开销）
* 场景：必须基于业务场景

#### 线程间协作与通信 
* 线程间的共享
    * 传递变量 / 使用全局静态变量（线程共享堆内存上的数据）
    * lock（显式）
    * synchronized
* 线程间的协作
    * Thread 类的 join()
    * Object 类的 wait(), notify(), notifyAll()
    * 需要返回值：Future / Callable
    * 并发工具类，基于CAS：CountDownLatch, CyclicBarrier
* 思考：进程间如何共享&协作？

