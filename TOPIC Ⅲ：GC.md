# TOPIC Ⅲ：GC

# Part 1: GC
## 1. GC 的背景与一般原理：23'45''
* 为什么JVM上有GC？
    * 内存资源的稀缺性（相对于一直有的CPU资源更加稀缺）

### GC：内存控制管理器
* solution 1：`引用计数`
    * 简单的垃圾回收算法（一般有效）
    * 引用计数决定了当前仓库是否有用
    * 原理：引用计数 = 0，无人使用，可被回收
    * 实际：仓库之间也存在引用关系（导致多个对象之间形成引用环，引用计数不会=0，类似死锁；最终导致内存泄漏，随时间推移导致内存溢出、程序崩溃）
* solution 2：`引用跟踪——Mark and Sweep “标记清除算法”`
    * 从根对象出发，扫描所有可达对象，组成集合，可达对象不能被回收；其他不可达的可被回收/清除。
    * 并行 GC 和 CMS GC 的基本原理！！！
    * 优势：解决引用计数的循环依赖问题；只扫描少量存活对象。
    * mark 可达对象，sweep 不可达对象（清除 / 压缩=内存整理）
    * Q：对象一直在动态增减，如何保证标记和清除的正确性？
    * A：`STW, Stop The World`——在垃圾回收的那个时间点，让`当前 JVM 内部的所有线程暂停`。也叫 JVM 的 GC 暂停。时间越短越好，发生频率越低越好。

### 分代假设
* 堆内存分区：`年轻代 Young Generation，老年代 Old Generation`
    * 长期存活的对象：老年代
    * 新对象的创建：年轻代————新生代 + S0 + S1
    * 新对象的创建：先分配在`Eden区`，标记阶段Eden区存活的对象会被`复制`到存活区S0（S0和S1其中之一）。当Eden区再次要满时，把Eden区和S0里存活的对象复制到S1，然后`清除`Eden区和S0里剩余的对象（包括：不可达+可达但已经被复制到了S1区）。下一个使用周期，Eden区和S1区。
    * 两个特点：Eden区、S0和S1只有两个区一直有数据；垃圾回收时，绝大多数对象都会被清除，只有`少量存活`（进行mark）。
    * `复制算法 Mark-Copy`————因为有空余空间，Eden区、S0和S1只有两个区一直有数据，S0和S1有一个叫“from”，另一个叫“to”.
    * `移动算法 Mark-Sweep-Compact`————老年代没有继续分区。
    * 对象存活过一定的GC周期后，被移动到老年代。`老年代默认都是存活对象。`
    * 老年代空间整理方法：复制老年代中所有存活对象，从空间开始的地方一次存放。即“内存的碎片整理”。
* 可作为 `GC Roots` 的对象
    * 当前正在执行的方法里的局部变量和输入参数（∵ 方法执行完之前一直有效）
    * 活动线程本身（∵ 当前的活动线程数是固定且有限的）
    * 类的静态字段（∵ 全局有效）
    * JNI 引用
    * 特点：扫描根对象速度很快（∵ 当前的活动线程数、方法数是固定且有限的，类的静态字段、JNI 引用的数量较少）
    * 基于以上特点：GC 算法在增加堆内存时，不会影响 GC 标记阶段产生的暂停时间。


## 2. 串行GC / 并行GC：10'25''

### 串行 GC
* 通过 JVM 参数 `“-XX:+UseSerialGC”` 来配置
* 串行 GC 与堆内存————`单线程`的垃圾回收器
    * 年轻代：mark-copy 算法
    * 老年代: mark-sweep-compact 算法
    * GC 期间，不管处理哪个区，所有的应用程序都 STW ==> 使用效率不高。
    * 对年轻代的改进：参数 `“-XX:+UserParNewGC”` 可以对年轻代进行`并行`的GC（和 CMS GC 配合使用）。
* 适用场景：堆内存较小的 JVM，且是单核 CPU 时比较有用。

### 并行 GC
* 通过 JVM 参数 `“-XX:+UseParallelGC”, “-XX:+UseParallelOldGC”, “-XX:+UseParallelGC -XX:+UseParallelOldGC”` 来配置（当并行 GC 不是默认时）
* 串行 GC 与堆内存————`线程数可指定`的垃圾回收器
    * 年轻代：mark-copy 算法
    * 老年代: mark-sweep-compact 算法
    * 指定线程：参数 `“-XX:+ParallelGCThreads=N”`，不指定时默认为 `CPU 核心数`
* 适用场景：多核服务器
* 主要目标：增加整个系统提供的吞吐量
    * 设计一：GC 期间，所有 CPU 的资源都用来并行地进行垃圾回收（一定时间内STW时间更短；其他时间段 CPU 资源专注于业务处理）
    * 设计二：2个 GC 周期的间隔期内无 GC 线程运行，无系统资源的额外消耗。
* 注：吞吐量最优 ！= GC 暂停时间最短，因此`并行 GC 的单次 GC 暂停时间较长`。
* 注：JDK 6\7\8 默认为并行 GC，从 JDK9 以后的版本都是 G1.


## 3. CMS GC： 21'7''
### Mostly `Concurrent` Mark and Sweep Garbage Collector
* 通过 JVM 参数 `“-XX:+UseConcMarkSweepGC”` 来配置
* CMS GC 与堆内存
    * 年轻代：STW方式的 mark-copy 算法 ———— 参数 `“-XX:+UserParNewGC”` 可以对年轻代进行`并行`的GC
    * 老年代: mark-sweep 算法（不压缩）
* 特点：避免老年代 GC 时暂停时间过长；大部分时间GC线程和业务线程可以一起并发执行
    * 老年代标记清除完之后，不做内存碎片整理；改用索引（`free-list 技术`），在其上记录当前所有可用的内存空间位置
    * “mark-and-sweep” 阶段不直接全程的STW，不做所有业务线程的 GC 暂停（业务线程的连续性）
* 主要目标：Concurrent
    * 设计：GC 期间，默认有1/4 CPU 核心数的资源用来并行地进行垃圾回收
* 两点注意
    * 少量的GC线程和大量的业务线程会竞争CPU资源
    * 老年代GC的过程中还会有少量的年轻代Minor GC
* JAVA 8 上 CMS 的最大 Young 区大小与 GC 线程数有关：332.8M = 64M * GC线程数 * 13/10

### 并行 vs 并发
* 相同点
    * 可以使用多个线程进行 GC
* 不同点
    * 并行————使用所有 CPU 的核心线程数
    * 并发————做 GC 的线程和业务线程大多数时候可以同时运行

### CMS GC 执行的6个阶段
* 阶段1和4非并发，需要做全线STW
* 阶段2、3、5、6：并发
#### 1. Initial Mark
* 三件事
    * 标记所有根对象  
    * 标记根对象直接引用的对象 
    * 标记年轻代指向老年代的对象（JVM内部有一个集合 RSet 用于记录跨代的对象引用）
* 本阶段：`精确`标记对象
#### 2. Concurrent Mark
* 从上一个阶段已标记对象向下找引用，遍历整个老年代所有堆内存的对象
* 注：内存里的关系时刻在`变化`（∵ 没有全线STW），且GC线程与业务线程并发执行，标记随时可能变化
* 本阶段：标记不精确
#### 3. Concurrent Preclean 并发预清理
* 处理上一阶段可能遇到的关系变化情况：识别变化区域，“脏区”
    * `Card Marking 卡片标记`：JVM 用卡片的方式将变化区域标记
* 本阶段：标记不精确
#### 4. Final Remark 
* 处理上一阶段也可能遇到的关系变化情况：此阶段进行STW
* 完成老年代中所有存活对象的标记
* 本阶段：标记`精确`
* 注：CMS GC 会在 Young区对象较少时做Final Remark，避免连续触发多次STW
#### 5. Concurrent Sweep 
* 并发清理不再使用的垃圾对象
#### 6. Concurrent Reset
* 重置JVM内部CMS相关的数据和状态，为下一次 GC 循环做准备
#### 优点：GC 过程多阶段，大多数时候并发，短时间STW，对业务影响最小

#### 缺点：内存不连续，老年代标记完无压缩/碎片整理，导致GC时间不可控


## 4. G1 GC： 22'16''
### Garbage First GC 
* CMS GC 的重大改造：“启发式算法”
* 优先清理堆内存中垃圾最多的区（在并发阶段估算每一region的垃圾数量），提高回收效率  
* 设计目标：进一步控制 STW 的时间，且时间可预期、可配置 
    * JVM 参数 `“-XX:_UseG1GC -XX:MaxGCPauseMillis=50”`（默认200毫秒）
    * 吞吐量和延迟之间的平衡
* G1 GC 与堆内存
    * `Region`（不再分年轻代和老年代）：每次只回收一部分小区间，Collection Set
    * 每个 Region 的作用随内存使用需求改变（Eden / Survivor / Old）：更灵活
    * 以`增量`方式处理垃圾
    * STW 时：回收所有标记为年轻代的region以及一部分标记为Old的region

### 配置参数
参数 | 类型 | 占Java Heap的大小 | 备注
---|---|---|---
G1NewSizePercent | -XX | 5% | `初始`年轻代
G1MaxNewSizePercent | -XX | 60% | `最大`年轻代
G1HeapRegionSize | -XX | -- | 单位：MB，默认是堆内存的1/2000；取值：1、2、4、8、16、32；设置较大数值可以允许大对象进入region 
ConcGCThreads | -XX | -- | `与Java应用一起执行的GC线程数量`，默认是Java线程的1/4（与CMS GC一样）；减小数值=提高GC并行效率+提高系统内部吞吐量，如果垃圾过多不建议减小数值，否则垃圾处理很慢
`+InitiatingHeapOccupancyPercent` | -XX | （默认）45% | IHOP，G1内部并行回收循环启动的阈值（当老年代的使用率超过45%，JVM启动GC）
`G1HeapWastePercent` | -XX | 5% | G1停止回收的最小内存大小
GCTimeRatio | -XX | -- | 花在应用线程和GC线程上的时间比率，默认是9（并行GC默认是99）；GC的工作时间计算 = 100 / (1 + GCTimeRatio).
MaxGCPauseMillis | -XX | -- | GC运行平稳后，能够控制每次GC时间不超过这个`预期`数值；默认200

### G1 GC 的注意事项
* 缺点：某些情况下，G1 GC 触发 `FullGC`，`退化`成串行GC，导致单次GC时间的整体延时上升，影响正常的业务
* 原因一：并发模式失败
    * G1启动标记周期时，垃圾太多，老年代已被填满，此时G1GC会放弃标记工作，退化
    * 解决：增加堆内存大小 / 调整GC周期 / 增加GC周期
* 原因二：晋升Old失败
    * 解决：增加G1 GC保留内存（用于“复制”）百分比 / 减少IHOP（提前启动标记周期） / 增加并发GC线程数
* 原因三：巨型对象分配失败
    * 解决：增加堆内存 / 调整region大小


## 5. ZGC / Shenandoah GC：25'23''
* JAVA 11/12里的高级GC策略
### Java 11: ZGC
* 通过 JVM 参数 `“-XX:+UnlockExperimentalVMOptions -XX:+UseZGC”` 来配置
    * 未引入的Java版本需要开启实验性开关；内置了ZGC的无需该JVM参数
* 特点
    * 暂停时间非常短，即`“低延迟”`：控制在10ms内
    * 可以支持`大范围`的堆内存（小空间和超大堆内存都可以）
    * 因为GC延迟短，整体系统的吞吐量就会下降（但与G1相比下降不超过15%）

### Java 12: Shenandoah GC
* 通过 JVM 参数 `“-XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahZGC”` 来配置
    * 未引入的Java版本需要解锁实验性开关 
* 极大改善JVM内部的GC暂停时间
    * 无论是Young区还是Old区，绝大多数GC线程都可以和业务线程并发执行

### GC 算法总结
* STW 时长（大->小）：SerialGC最大，ParallelGC较大，CMS GC降低单次GC时间，G1做增量的整理与回收（进一步降低单次GC时间），ZGC超低延迟，Shenandoah GC是G1的改进版（和ZGC类似）
* 吞吐量：ParallelGC > CMS GC, G1 > ZGC
* 并行：
    * ParNew在串行GC基础上改造，和CMS GC配套使用
    * Parallel Scavenge 年轻代，Parallel Old 老年代：多线程GC，高吞吐
* 发展趋势
    * 串行 --> 并行：利用多核CPU优势
    * 并行 --> 并发：追求低延迟
    * CMS --> G1：降低单次GC暂停时间
    * G1 --> ZGC：低/无停顿GC
* 业务选择
    * serial + serial old：年轻代和老年代都串行；单线程，低延迟；桌面系统
    * ParNew + CMS：多线程，相对低延迟
    * Parallel Scavenge + Parallel Scavenge Old：多线程，高吞吐；web系统
* 脱离场景谈性能都是耍流氓



# Part 2: GC & JVM
## 1. GC 日志解读与分析：50'16''
### JVM调优的三个指标
* GC 
* 线程运行情况
* 内存的使用情况

### 模拟GC的情况
* GCLogAnalysis.java 文件：模拟业务系统
    * Young 区：1秒内不断新建对象
    * Old 区：垃圾对象缓存在另一个对象中（有引用while外的'cachedGarbage'，因此GC时缓存不会被回收，从而进入老年代）
        * 先编译.java文件
        * 运行：参数 `-XX:+PrintGCDetails`
        ```bash
        java -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:gc.demo.log -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * 注：以上命令中存在“[JDK9及以后版本启动脚本兼容性问题导致项目无法启动](https://blog.csdn.net/weixin_44305208/article/details/113915321)”问题。
    * JVM有默认堆内存配置参数，只执行 "java GCLogAnalysis" 时（日常）。
    * 日志解读
        * 第一段：堆内存的变化情况（包括：GC发生原因 + GC暂停时间；GC执行前后的内存大小变化）
        * 第二段：CPU 使用情况
        * Full GC 做 Old 区 GC 时，Young 区被清空。
        * 不同参数下的GC次数比较：`Xmx/Xms` 设置为较小值时，Full GC次数变多，GC更频繁；更容易出现`堆内存溢出（OutOfMemoryError）`。`Xmx/Xms` 设置为较大值时，GC暂停时间会变长。
        * 不配置参数`Xms`会导致Full GC的次数增多，单位时间内GC频率上升。因为堆内存小了（蓄水池小了），容纳的对象少，需要频繁回收。
    * 概念辨析
        * Young GC vs Full GC (Young GC + Old GC) ————
        * Minor GC 小型 vs Major GC 大型 ———— 一般Young GC被叫做Minor GC，对堆内存的影响较小。
    * 不同 GC 算法下的辨析（JDK 8默认为并行GC算法）
        * 串行GC（`DefNew`，Young区GC）：
        ```bash
        java -XX:+PrintGCDetails -XX:+UseSerialGC -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * 并行GC：
        ```bash
        java -XX:+PrintGCDetails -XX:+UseParallelGC -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * CMS GC（`Parnew` 针对 Young 区，`CMS GC` 针对 Old 区）：
        ```bash
        java -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * 注：CMS GC 发生过程中有可能会发生一次或多次 Young GC
        * G1 GC（过程最复杂，可以只看概要 '`-XX:+PrintGC`'）：
        ```bash
        java -XX:+PrintGCDetails -XX:+UseG1GC -Xmx1g -Xms1g GCLogAnalysis
        ``` 
        * G1 GC各阶段：
        > Evacuation Pause: young ———— 纯年轻代模式转移暂停
        > Concurrent Marking ———— 并发标记
        > 阶段一：Initial Mark ———— 初始标记
        > 阶段二：Root Region Scan ———— Root区扫描
        > 阶段三：Concurrent Mark ———— 并发标记
        > 阶段四：Remark ———— 再次标记
        > 阶段五：Cleanup ———— 清理
        > Evacuation Pause (mixed) ———— 转移暂停（混合模式）
        > Full GC (Allocation Failure)

### 工具
* 在线（可视化）：GCEasy
    * 地址：gceasy.io
    * 操作：把GC的log文件上传 / 拷贝log文件粘贴在输入框
* JAVA 包：GCViewer

### 课后小结
* 如何查看、分析不同GC配置下的日志信息？
* 各种GC有什么特点和使用场景？


## 2. JVM 线程堆栈分析/内存分析与相关工具：40'15''
### JVM线程模型
* 三个层面
    * JAVA层面：Thread对象
    * JVM层面：JavaThread （thread.start()之后）
    * OS层面：系统线程（物理线程；运行完之后线程被终止，在OS层面被销毁）
* 种类
    * 用户自定义业务线程（除以下几种之外的线程）
    * JVM内部线程
        * VM 线程（单例）
        * 定时任务线程（单例）
        * GC线程（多个）
        * 编译器线程（JVM运行时产生的热代码被编译为本地代码）
        * 信号分发线程（例，ctrl+C中断线程）
* 安全：JVM调用物理线程干活时，干活代码里插入了检查的安全点；干活期间不断检查
    * 在检查点上暂停
    * JVM安全点状态：所有线程都处于安全点状态（线程暂停，线程栈在这一点上不变）
* 工具
    * jstack
    * jcmd
    * kill -3
    * JMX
    * jconsole
    * fastthread.io（提交一个线程栈用于检查）

### 内存分析与相关工具
* Q：一个对象，1000个属性 vs 1000个对象，每个一个属性
    * 后者占用内存更多
    * 对象在内存中的结构：对象头 + 对象体 + alignment
    * 对象头 = 标记字 + class指针 + 数组长度
    * 对象体 = padding + 实例数据
    * 对象的字节数不是4字节（32位）或8字节（64位）的倍数时，需要对齐！！！
    * 对齐的2种方式：（内部）padding，（外部）alignment
* 查看对象占用内存的工具
    * 开源框架 JOL (Java Object Layout)：用于查看对象内存布局
    * Java API 中的Instrumentation类里的getObjecySize()方法：估算对象占用内存
    * 命令行 'jmap -histo pid'：列出所有实例数和占用的字节数
    * 实战：Byte 类一个占用 16 bytes，Integer 类一个占用 16 bytes（由此可见，包装类型的内存占用远大于原生类型）
* 总结
    * `64位JVM`中：对象头占用12个字节，以 `8-Byte 对齐`因此需要占用16个字节（`一个空类的实例`）
    * `32位JVM`中：对象头占用8个字节，以 `4-Byte 对齐` 
    * 64位JVM需要多消耗堆内存！！！
* 包装类型
    * Integer: 占用16个字节（= 标记字8 + class指针4 + int类型数据4）
    * Long: 占用24个字节（= 标记字8 + class指针4 + long类型数据8 + 对齐4）
    * 压缩指针：堆内存不大时，JVM开启4字节保存指针，节约内存空间
* 多维数组和字符串
    * 多维数组：每多一个维度，都是new一个单独的对象，额外占用16字节
    * 二维数组：每个嵌套的第二维都是一个单独的对象，额外占用16字节
    * 上例：int[128][2]，则内存占用计算为 [(8+4+4) + 4*2]*128 + 16 = 3600字节
    * 上例：int[256]，则内存占用计算为 4*256 + (8+4+4)) = 1040字节
    * 字符串对象：一个String类有24字节的额外开销
* 大问题：内存泄漏（OOM, OutOfMemory）
    * 解决方案一：加大堆内存容量
    * 解决方案二：增大 PermGen / Metaspace 区的大小（原因：加载到内存的类太多或体积太大，超出PermGen区的大小）
    * 高版本的JVM可以支持卸载元数据区的class：使用 '`-XX:+CMSClassUnloadingEnabled`' 参数
    * 解决方案三（诱因——不能创建本地线程了，堆内存快用完了）：降低Xss / 调整操作系统的线程数限制 / 调整代码减少线程使用
    * 内存Dump分析工具：Eclipse MAT, jhat


## 3. JVM 分析调优经验：29'51''
### 经验指标一：分配速率 Allocation Rate
* 年轻代的新对象的分配（单位时间内的内存分配量）
    * 单位：MB/sec
    * 过高：影响系统性能（业务的资源变少），产生巨大GC开销
    * 持续大于回收速率：OOM
    * 较低：健康（与回收速率基本持平）
    * 分配速率和回收速率都很高：亚健康
* 新对象创建发生在`Eden区`：分配速率高，Eden区快速被填满，导致`Minor GC高频发生`（STW频率上升；进而影响吞吐量）
    * Q：Eden区占Young区80%空间，Young区占堆内存1/3空间
    * `2 solutions: 增大Young区 / Young区和Old区等比例增大`
        * 隐患——“`蓄水池效应`”：Young GC每次暂停时间变长（频率降低）

### 经验指标二：晋升速率 / 提升速率 Premature Promotion
* 从年轻代晋升到老年代的速率（单位时间内的晋升到Old区的数据量）
    * 单位：MB/sec
    * 存活时间短的过早晋升：Major GC / Full GC 暂停时间变长，影响系统吞吐量
    * Q：老年代上的GC算法是针对存活时间较长的对象设计的
    * `2 solutions: （相对/绝对，通过修改参数实现）增加年轻代大小 / 减少每次业务处理的内存使用量`
        * 主体思路：`让临时数据在年轻代存得下`
* 计算
    * 晋升到老年代的部分 = 堆内存减少的数量 - Young区减少的数量
* 3个现象
    * 测试：配置"`-Xmx24m -XX:NewSize=16m -XX:MaxTenuringThreshold=1`"参数模拟
    * 短时间内的大量 Full GC
    * 每次 Full GC后，老年代使用率较低：对象存活时间短
    * 分配速率的数值与晋升速率接近


## 4. JVM 疑难情况问题分析：27'17''
### Arthas：JVM分析诊断利器
* 阿里的开源工具

### 从现象收集指标，通过关联性分析异常 
* 来源一：业务日志
    * 依赖，请求压力等
* 来源二：系统的资源使用情况
    * 硬件，网络，架构，负载等
* 来源三：性能
    * 数据库连接数、索引等，中间件，底层软件
* 来源四：操作系统日志
* 来源五：APM
* 来源六：`排查应用系统`（优化效果非常明细；成本小，不用修改代码）
    * GC问题，配置文件，线程，代码，单元测试等
* 来源七：资源竞争、坏邻居性能
* 来源八：疑难问题

### 实战分析
* 问题描述：GC暂停时间峰值较高，且时间发生突然；需要控制在200ms以内。
* 分析
    * CPU使用率较低，系统负载很低
    * JVM堆内存：Full GC 导致了长久的暂停；未配置GC算法，使用了默认的 Parallel GC
    * 换成 G1 GC 后，暂停时间峰值更高了
    * 分析GC日志，2个可疑点：物理内存超高（k8s的资源隔离没做好，其实都是物理机的内存），并行GC线程数超高（k8s的资源隔离没做好，72核对应了48个线程在4个core上资源竞争，上下文切换频繁）