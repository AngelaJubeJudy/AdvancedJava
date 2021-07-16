# GC 与堆内存

## 0. 堆内存分区
* 年轻代 Young Generation
    * 年轻代分区：Eden + S0 + S1
    * 特点：Eden, S0, S1中只有两个区一致有数据
* 老年代 Old Generation
    * 特点：对象存活过一定GC周期后，被移动到老年代。老年代默认都是存活对象。


## 1. 串行 GC
* 通过 JVM 参数 `"-XX:+UseSerialGC"` 来配置
* GC 算法 & 堆内存分区
    * 年轻代：mark-copy
    * 老年代：mark-sweep-compact
* 适用场景：堆内存较小的JVM，且是单核CPU时


## 2. 并行 GC
* 通过 JVM 参数 `"-XX:+UseParallelGC", "-XX:+UseParallelOldGC", "-XX:+UseParallelGC -XX:+UseParallelOldGC"` 来配置
* GC 算法 & 堆内存分区
    * 年轻代：mark-copy
    * 老年代：mark-sweep-compact
* 特点：线程数可指定
* 适用场景：需要增加吞吐量的系统，且是多核CPU时


## 3. CMS GC
* 通过 JVM 参数 `"-XX:+UseConcMarkSweepGC"` 来配置
* GC 算法 & 堆内存分区
    * 年轻代：mark-copy（可通过参数"-XX:+UserParNewGC"对年轻代进行并行GC）
    * 老年代：mark-sweep
* 特点：大部分业务线程和GC线程可以并发执行（业务线程的连续性）


## 4. G1 GC
* 配置参数

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

* GC 算法 & 堆内存不分区
    * Region：每个region的作用随使用需求而灵活改变
* 特点：吞吐量和延迟之间的平衡
* 适用场景：需要降低单次GC时长的系统
* 注意：某些情况下，G1 GC 触发 Full GC，退化为串行GC，导致单次GC整体延时上升。


## 5. ZGC / Shenandoah GC
* 通过 JVM 参数 `“-XX:+UnlockExperimentalVMOptions -XX:+UseZGC”` 来配置
* GC 算法 & 堆内存分区
    * 无论是年轻代还是老年代，绝大多数GC线程都可以和业务线程并发执行。
* 适用场景：要求系统低延迟；可以支持灵活大范围的堆内存（小空间和超大堆内存都可以）