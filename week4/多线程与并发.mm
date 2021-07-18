<map version="1.0.1"><node CREATED="1626626183162" ID="ID_root" MODIFIED="1626626183162" TEXT="多线程"><node CREATED="1626626183162" ID="ID_cbfe083a0045" POSITION="right" MODIFIED="1626626183162" TEXT="线程状态"><node CREATED="1626626183162" ID="ID_575eadff15b6" MODIFIED="1626626183162" TEXT="状态"><node CREATED="1626626183162" ID="ID_782dfe4f8a5f" MODIFIED="1626626183162" TEXT="BLOCKED"></node><node CREATED="1626626183162" ID="ID_089d7b12daac" MODIFIED="1626626183162" TEXT="TERMINATED"></node><node CREATED="1626626183162" ID="ID_866180c0a986" MODIFIED="1626626183162" TEXT="NON-RUNNABLE"></node><node CREATED="1626626183162" ID="ID_ff724f0f2df0" MODIFIED="1626626183162" TEXT="RUNNING"></node><node CREATED="1626626183162" ID="ID_0800713d2c7f" MODIFIED="1626626183162" TEXT="RUNNABLE"></node><node CREATED="1626626183162" ID="ID_d6291d3974f6" MODIFIED="1626626183162" TEXT="READY"></node><node CREATED="1626626183162" ID="ID_a6c296da7b45" MODIFIED="1626626183162" TEXT="（无参数）等待&amp;nbsp;WAITING，（有参数）超时等待&amp;nbsp;TIMED_WAITING"></node><node CREATED="1626626183162" ID="ID_a103df996985" MODIFIED="1626626183162" TEXT="核心状态：RWB&amp;nbsp;(READY,&amp;nbsp;RUNNING,&amp;nbsp;WAITING&amp;nbsp;/&amp;nbsp;TIMED_WAITING,&amp;nbsp;BLOCKED)"></node></node><node CREATED="1626626183162" ID="ID_8b07c5338770" MODIFIED="1626626183162" TEXT="状态流转"><node CREATED="1626626183162" ID="ID_cf139c8860b4" MODIFIED="1626626183162" TEXT="从&amp;nbsp;Running&amp;nbsp;到&amp;nbsp;Runnable：执行&amp;nbsp;yield()&amp;nbsp;方法，重新被&amp;nbsp;CPU&amp;nbsp;调度。"></node><node CREATED="1626626183162" ID="ID_fb684e0f844a" MODIFIED="1626626183162" TEXT="从&amp;nbsp;Running&amp;nbsp;到&amp;nbsp;Non-Runnable：执行&amp;nbsp;wait()&amp;nbsp;方法，或&amp;nbsp;sleep()&amp;nbsp;方法。"></node><node CREATED="1626626183162" ID="ID_feabf71a6aa6" MODIFIED="1626626183162" TEXT="从&amp;nbsp;Running&amp;nbsp;到&amp;nbsp;Terminated：执行&amp;nbsp;exit()&amp;nbsp;方法。"></node><node CREATED="1626626183162" ID="ID_a4a70d8f22de" MODIFIED="1626626183162" TEXT="从&amp;nbsp;Non-Runnable&amp;nbsp;到&amp;nbsp;Runnable：执行&amp;nbsp;notify()&amp;nbsp;方法。"></node></node></node><node CREATED="1626626183162" ID="ID_ac13cb88f1c5" POSITION="right" MODIFIED="1626626183162" TEXT="并发"><node CREATED="1626626183162" ID="ID_6f9121539041" MODIFIED="1626626183162" TEXT="Java&amp;nbsp;并发包：JUC&amp;nbsp;(java.util.concurrency)"></node><node CREATED="1626626183162" ID="ID_a6d3d7b39288" MODIFIED="1626626183162" TEXT="核心功能"><node CREATED="1626626183162" ID="ID_7528f77c3955" MODIFIED="1626626183162" TEXT="锁"><node CREATED="1626626183162" ID="ID_f983a8d1457b" MODIFIED="1626626183162" TEXT="基础接口"><node CREATED="1626626183162" ID="ID_b2188dcd7c2d" MODIFIED="1626626183162" TEXT="interface&amp;nbsp;Lock"><node CREATED="1626626183162" ID="ID_3bb809fd7ff6" MODIFIED="1626626183162" TEXT="基础实现类"><node CREATED="1626626183162" ID="ID_994893547ebc" MODIFIED="1626626183162" TEXT="ReentrantLock&amp;nbsp;可重入锁"></node><node CREATED="1626626183162" ID="ID_ad04ffbc9e68" MODIFIED="1626626183162" TEXT="公平锁（排队靠前的优先）"></node><node CREATED="1626626183162" ID="ID_87f4dc2878c1" MODIFIED="1626626183162" TEXT="非公平锁（机会等同）"></node></node></node><node CREATED="1626626183162" ID="ID_052335f8630c" MODIFIED="1626626183162" TEXT="interface&amp;nbsp;Condition"></node></node><node CREATED="1626626183162" ID="ID_ffc4d0702ae9" MODIFIED="1626626183162" TEXT="ReadWriteLock&amp;nbsp;读写锁"><node CREATED="1626626183162" ID="ID_c69ac906a3ff" MODIFIED="1626626183162" TEXT="可重入读写锁&amp;nbsp;ReentrantReadWriteLock"><node CREATED="1626626183162" ID="ID_4c20075b7773" MODIFIED="1626626183162" TEXT="适用场景：并发读，并发写，读多写少。"></node></node></node><node CREATED="1626626183162" ID="ID_3dc9780bd109" MODIFIED="1626626183162" TEXT="锁工具包：java.util.concurrent.locks"></node><node CREATED="1626626183162" ID="ID_230ebc184e9f" MODIFIED="1626626183162" TEXT="LockSupport 静态方法"></node><node CREATED="1626626183162" ID="ID_5a60e2f2d7ab" MODIFIED="1626626183162" TEXT="最佳实践"><node CREATED="1626626183162" ID="ID_efe8c247d961" MODIFIED="1626626183162" TEXT="最小使用锁范围"><node CREATED="1626626183162" ID="ID_9aff36106dbb" MODIFIED="1626626183162" TEXT="降低锁范围：降低锁定代码的作用域（提升整体的运行效率）"></node><node CREATED="1626626183162" ID="ID_c4d4a4c6e153" MODIFIED="1626626183162" TEXT="细分锁粒度：一个大锁拆分成多个小锁（提升并发能力）"></node></node></node></node><node CREATED="1626626183162" ID="ID_a13f5f9196ec" MODIFIED="1626626183162" TEXT="原子类"><node CREATED="1626626183162" ID="ID_4c49738a9b10" MODIFIED="1626626183162" TEXT="工具包：java.util.concurrent.atomic"></node><node CREATED="1626626183162" ID="ID_28e126e75f1c" MODIFIED="1626626183162" TEXT="底层实现原理"><node CREATED="1626626183162" ID="ID_43d0ba26cf04" MODIFIED="1626626183162" TEXT="调用了一系列的&amp;nbsp;Unsafe&amp;nbsp;API:&amp;nbsp;CompareAndSwap前缀，`CAS&amp;nbsp;机制`"></node><node CREATED="1626626183162" ID="ID_a1ef235817a9" MODIFIED="1626626183162" TEXT="需要&amp;nbsp;CPU&amp;nbsp;硬件指令支持：CAS&amp;nbsp;指令（相当于“乐观锁”，通过自旋重试保证写入）"></node><node CREATED="1626626183162" ID="ID_c0ce8cc6b7c2" MODIFIED="1626626183162" TEXT="value&amp;nbsp;的可见性：volatile&amp;nbsp;关键字，保证读写操作都可见（不保证原子性）"></node></node><node CREATED="1626626183162" ID="ID_01d2a3f933a9" MODIFIED="1626626183162" TEXT="比&amp;nbsp;CAS&amp;nbsp;在多线程下表现更好的计数方式"><node CREATED="1626626183162" ID="ID_d0f5d7216ebe" MODIFIED="1626626183162" TEXT="分段思想：从&amp;nbsp;AtomicLong&amp;nbsp;到&amp;nbsp;LongAdder"></node></node></node><node CREATED="1626626183162" ID="ID_e0c986573a94" MODIFIED="1626626183162" TEXT="线程池"></node><node CREATED="1626626183162" ID="ID_37d2b58bed68" MODIFIED="1626626183162" TEXT="工具类"><node CREATED="1626626183162" ID="ID_1b7ab74a9ab0" MODIFIED="1626626183162" TEXT="面向更复杂的场景（可以定量）"><node CREATED="1626626183162" ID="ID_fa73967bc504" MODIFIED="1626626183162" TEXT="需要控制并发访问资源的并发数量"></node><node CREATED="1626626183162" ID="ID_6d88cd96c77e" MODIFIED="1626626183162" TEXT="需要多个线程在某个时间同时开始运行"></node><node CREATED="1626626183162" ID="ID_b6435dcc7136" MODIFIED="1626626183162" TEXT="需要指定数量线程到达某状态再继续处理（设置聚合点）"></node></node><node CREATED="1626626183162" ID="ID_6145f21d1b92" MODIFIED="1626626183162" TEXT="AQS&amp;nbsp;(AbstractQueuedSynchronizer)&amp;nbsp;队列同步器"><node CREATED="1626626183162" ID="ID_cba685b09d66" MODIFIED="1626626183162" TEXT="Semaphore&amp;nbsp;信号量"></node><node CREATED="1626626183162" ID="ID_f42e6cd825f5" MODIFIED="1626626183162" TEXT="CountDownLatch"><node CREATED="1626626183162" ID="ID_9f6063a333ac" MODIFIED="1626626183162" TEXT="主线程&amp;nbsp;await，然后再聚合"></node><node CREATED="1626626183162" ID="ID_04f4568907ac" MODIFIED="1626626183162" TEXT="N&amp;nbsp;个子线程&amp;nbsp;countDown()，主线程继续"></node><node CREATED="1626626183162" ID="ID_9e8ae3d48526" MODIFIED="1626626183162" TEXT="达到聚合点后不可复用"></node><node CREATED="1626626183162" ID="ID_10f7738589ac" MODIFIED="1626626183162" TEXT="基于&amp;nbsp;AQS&amp;nbsp;实现（state&amp;nbsp;为&amp;nbsp;count）"></node></node></node><node CREATED="1626626183162" ID="ID_b731f737bf53" MODIFIED="1626626183162" TEXT="CyclicBarrier"><node CREATED="1626626183162" ID="ID_27dbce377898" MODIFIED="1626626183162" TEXT="子线程&amp;nbsp;await，各个子线程继续执行，条件在子线程里"></node><node CREATED="1626626183162" ID="ID_9cb5c6bdd375" MODIFIED="1626626183162" TEXT="N&amp;nbsp;个子线程&amp;nbsp;await()，子线程继续"></node><node CREATED="1626626183162" ID="ID_44df06ea7c05" MODIFIED="1626626183162" TEXT="达到聚合点后可以&amp;nbsp;reset()，循环使用屏障"></node><node CREATED="1626626183162" ID="ID_c6db6e8764a1" MODIFIED="1626626183162" TEXT="基于可重入锁&amp;nbsp;condition.await&amp;nbsp;/&amp;nbsp;signAll&amp;nbsp;实现"></node></node></node><node CREATED="1626626183162" ID="ID_a2ac955809ef" MODIFIED="1626626183162" TEXT="集合类"><node CREATED="1626626183162" ID="ID_a67798cfc2e8" MODIFIED="1626626183162" TEXT="使用副本机制改进"><node CREATED="1626626183162" ID="ID_a1a890769b9e" MODIFIED="1626626183162" TEXT="ArrayList"></node><node CREATED="1626626183162" ID="ID_a83ccbaf6346" MODIFIED="1626626183162" TEXT="LinkedList"></node></node><node CREATED="1626626183162" ID="ID_342140d8cb0f" MODIFIED="1626626183162" TEXT="使用分段锁或CAS"><node CREATED="1626626183162" ID="ID_1a834356f432" MODIFIED="1626626183162" TEXT="HashMap"></node><node CREATED="1626626183162" ID="ID_ae1d2c30597f" MODIFIED="1626626183162" TEXT="LinkedHashMap"></node></node></node></node><node CREATED="1626626183162" ID="ID_9ebd5988b799" MODIFIED="1626626183162" TEXT="接口及相关实现"><node CREATED="1626626183162" ID="ID_c1cf5502c778" MODIFIED="1626626183162" TEXT="锁机制类&amp;nbsp;Locks"><node CREATED="1626626183162" ID="ID_37208de5b18c" MODIFIED="1626626183162" TEXT="Lock&amp;nbsp;锁,&amp;nbsp;Condition&amp;nbsp;条件,&amp;nbsp;ReentrantLock&amp;nbsp;可重入锁,&amp;nbsp;ReadWriteLock&amp;nbsp;读写锁,&amp;nbsp;LockSupport&amp;nbsp;封装了很多静态锁的方法"></node></node><node CREATED="1626626183162" ID="ID_6ae954bee156" MODIFIED="1626626183162" TEXT="原子操作类&amp;nbsp;Atomic"><node CREATED="1626626183162" ID="ID_bae73b78f88c" MODIFIED="1626626183162" TEXT="AtomicInteger,&amp;nbsp;AtomicLong,&amp;nbsp;LongAdder&amp;nbsp;改进版的对long类型原子计数的类"></node></node><node CREATED="1626626183162" ID="ID_24e6c86b04bd" MODIFIED="1626626183162" TEXT="线程池相关类&amp;nbsp;Executor"><node CREATED="1626626183162" ID="ID_09310c724e5e" MODIFIED="1626626183162" TEXT="Future,&amp;nbsp;Callable,&amp;nbsp;Executor,&amp;nbsp;ExecutorService"></node></node><node CREATED="1626626183162" ID="ID_20ab5672b775" MODIFIED="1626626183162" TEXT="信号量工具类"><node CREATED="1626626183162" ID="ID_aacdc8d8aff0" MODIFIED="1626626183162" TEXT="CountDownLatch,&amp;nbsp;CyclicBarrier,&amp;nbsp;Semaphore"></node></node><node CREATED="1626626183162" ID="ID_c5214a4bfda0" MODIFIED="1626626183162" TEXT="并发集合类&amp;nbsp;Collections"><node CREATED="1626626183162" ID="ID_4fda29d12596" MODIFIED="1626626183162" TEXT="CopyOnWriteArrayList,&amp;nbsp;ConcurrentMap（包括&amp;nbsp;ConcurrentHashMap,&amp;nbsp;ConcurrentLinkedHashMap&amp;nbsp;等）"></node></node></node></node><node CREATED="1626626183162" ID="ID_0bad66ae8682" POSITION="right" MODIFIED="1626626183162" TEXT="新建线程（JAVA层面）"><node CREATED="1626626183162" ID="ID_22132ae2743f" MODIFIED="1626626183162" TEXT="Runnable接口"><node CREATED="1626626183162" ID="ID_b0a8ee78b662" MODIFIED="1626626183162" TEXT="run()：定义了当前线程里的一个任务"></node><node CREATED="1626626183162" ID="ID_6a7104d08258" MODIFIED="1626626183162" TEXT="start()：开启一个新的线程"></node></node><node CREATED="1626626183162" ID="ID_e1b6b6cc3be7" MODIFIED="1626626183162" TEXT="Thread类"><node CREATED="1626626183162" ID="ID_cd7ff86f84f4" MODIFIED="1626626183162" TEXT="继承了&amp;nbsp;Runnabele&amp;nbsp;接口"></node><node CREATED="1626626183162" ID="ID_e13c1bf59d2c" MODIFIED="1626626183162" TEXT="run()"></node><node CREATED="1626626183162" ID="ID_1661a18d811d" MODIFIED="1626626183162" TEXT="start()"></node><node CREATED="1626626183162" ID="ID_27eae4bbe6c9" MODIFIED="1626626183162" TEXT="join()"></node><node CREATED="1626626183162" ID="ID_b3fddffe1d46" MODIFIED="1626626183162" TEXT="sleep()"></node><node CREATED="1626626183162" ID="ID_e370c747bb7b" MODIFIED="1626626183162" TEXT="wait(),&amp;nbsp;wait(long&amp;nbsp;timeout),&amp;nbsp;wait(long&amp;nbsp;timeout,&amp;nbsp;int&amp;nbsp;nanos)"></node><node CREATED="1626626183162" ID="ID_a5469eff0164" MODIFIED="1626626183162" TEXT="notify(), notifyAll()"></node></node></node><node CREATED="1626626183162" ID="ID_05a3b6e3479f" POSITION="right" MODIFIED="1626626183162" TEXT="线程安全"><node CREATED="1626626183162" ID="ID_d67aa37d3a9b" MODIFIED="1626626183162" TEXT="中断"><node CREATED="1626626183162" ID="ID_0a8ba30916e3" MODIFIED="1626626183162" TEXT="interrupt()方法抛出InterruptedException异常"></node><node CREATED="1626626183162" ID="ID_5bccabec78a1" MODIFIED="1626626183162" TEXT="设置一个外部的全局状态"></node></node><node CREATED="1626626183162" ID="ID_376e4ce1c7af" MODIFIED="1626626183162" TEXT="并发性质"><node CREATED="1626626183162" ID="ID_9fa3ba0c1bba" MODIFIED="1626626183162" TEXT="原子性"></node><node CREATED="1626626183162" ID="ID_9932119ae642" MODIFIED="1626626183162" TEXT="可见性"><node CREATED="1626626183162" ID="ID_7fcf0bfbbf06" MODIFIED="1626626183162" TEXT="关键字：volatile"></node><node CREATED="1626626183162" ID="ID_74ae5e7a973d" MODIFIED="1626626183162" TEXT="多个线程分别持有同一变量的副本，默认的及时修改都同步在副本上，然后再同步到主内存。"></node></node><node CREATED="1626626183162" ID="ID_37cb080527c8" MODIFIED="1626626183162" TEXT="有序性"><node CREATED="1626626183162" ID="ID_571471d2f6a7" MODIFIED="1626626183162" TEXT="单个线程内，重排不影响执行顺序；但&amp;nbsp;JVM&amp;nbsp;不保证多个线程操作同一数据时是否会产生不一致的结果。"></node><node CREATED="1626626183163" ID="ID_577aac5e9ffa" MODIFIED="1626626183163" TEXT="happens-before&amp;nbsp;原则（先行发生原则）"></node></node></node><node CREATED="1626626183163" ID="ID_e1a8d4872520" MODIFIED="1626626183163" TEXT="实现"><node CREATED="1626626183163" ID="ID_6f3f2dd3fd61" MODIFIED="1626626183163" TEXT="synchronized&amp;nbsp;同步块"><node CREATED="1626626183163" ID="ID_fe5eeddfb3c2" MODIFIED="1626626183163" TEXT="不同执行粒度：对象，方法，某一块代码"></node><node CREATED="1626626183163" ID="ID_b5f250f6e19d" MODIFIED="1626626183163" TEXT="分类：偏向锁，轻量级锁，重量级锁"></node><node CREATED="1626626183163" ID="ID_9a79215f97c7" MODIFIED="1626626183163" TEXT="有线程安全问题的代码块放入同步块：多个线程来排队，按顺序执行“读-&amp;gt;写-&amp;gt;刷入主内存”，相当于串行化，避免并发干扰。"></node><node CREATED="1626626183163" ID="ID_72ca1e16c0ec" MODIFIED="1626626183163" TEXT="副作用：效率低。"></node><node CREATED="1626626183163" ID="ID_7b6f16b9fdb5" MODIFIED="1626626183163" TEXT="操作的结果对其他线程可见；更新刷入主内存"></node></node><node CREATED="1626626183163" ID="ID_a43d507da25f" MODIFIED="1626626183163" TEXT="volatile"><node CREATED="1626626183163" ID="ID_d9eaeeab848a" MODIFIED="1626626183163" TEXT="场景：单个线程写，多个线程读"></node><node CREATED="1626626183163" ID="ID_dc584c1d99fe" MODIFIED="1626626183163" TEXT="建议少用：因为不能使用变量副本，需要去主内存刷新"></node></node><node CREATED="1626626183163" ID="ID_03f11cf3f36f" MODIFIED="1626626183163" TEXT="final"><node CREATED="1626626183163" ID="ID_5b5bd1a142f1" MODIFIED="1626626183163" TEXT="关键字的位置：类，方法，局部变量，实例属性，静态属性"></node><node CREATED="1626626183163" ID="ID_480e37073787" MODIFIED="1626626183163" TEXT="表示不允许被修改。仅可读，跨线程安全。"></node></node></node><node CREATED="1626626183163" ID="ID_ffb1ca3ef2b2" MODIFIED="1626626183163" TEXT="线程池"><node CREATED="1626626183163" ID="ID_60ba1be40e16" MODIFIED="1626626183163" TEXT="Executor&amp;nbsp;执行者"><node CREATED="1626626183163" ID="ID_4ce358cb43e4" MODIFIED="1626626183163" TEXT="最顶层"></node><node CREATED="1626626183163" ID="ID_2821bb7ac9f5" MODIFIED="1626626183163" TEXT="interface&amp;nbsp;Executor&amp;nbsp;仅一个方法：execute(Runnable&amp;nbsp;cmd)，无返回值"></node></node><node CREATED="1626626183163" ID="ID_d22ce9df1d18" MODIFIED="1626626183163" TEXT="ExecutorService 接口"><node CREATED="1626626183163" ID="ID_298a90d1b072" MODIFIED="1626626183163" TEXT="interface&amp;nbsp;ExecutorService&amp;nbsp;继承了&amp;nbsp;interface&amp;nbsp;Executor"></node><node CREATED="1626626183163" ID="ID_592bd9bcd394" MODIFIED="1626626183163" TEXT="submit(Runnable&amp;nbsp;task),&amp;nbsp;submit(Runnable&amp;nbsp;task,&amp;nbsp;T&amp;nbsp;result),&amp;nbsp;submit(Callable&amp;lt;T&amp;gt;&amp;nbsp;task)：调用过程中，把另一个线程的返回值&amp;amp;异常都捕获了。"></node><node CREATED="1626626183163" ID="ID_daae1402a80a" MODIFIED="1626626183163" TEXT="优雅停机的实现：先调用&amp;nbsp;shutdown()，再调用&amp;nbsp;awaitTermination(timeOut,&amp;nbsp;unit)；awaitTermination&amp;nbsp;返回&amp;nbsp;true，正常退出；返回&amp;nbsp;false，再调用&amp;nbsp;shutdownNow()，强制关闭已超时的线程。"></node></node><node CREATED="1626626183163" ID="ID_f1bae8c7115b" MODIFIED="1626626183163" TEXT="ThreadPoolExecutor"><node CREATED="1626626183163" ID="ID_05f20b95a59c" MODIFIED="1626626183163" TEXT="首先判断正在执行的线程数量是否已达到池的核心线程数。"></node><node CREATED="1626626183163" ID="ID_2ee41b5aa1c2" MODIFIED="1626626183163" TEXT="缓冲队列满时，判断是否达到最大线程数。"></node><node CREATED="1626626183163" ID="ID_35303056f0b4" MODIFIED="1626626183163" TEXT="上一步达到：执行拒绝策略（是否拒绝过多的任务）。"></node></node><node CREATED="1626626183163" ID="ID_cd80179f44bf" MODIFIED="1626626183163" TEXT="ThreadFactory"><node CREATED="1626626183163" ID="ID_45d357e3101c" MODIFIED="1626626183163" TEXT="好处：线程池中具有相同配置、特定属性的一组线程，批量地由线程工厂创建。"></node></node><node CREATED="1626626183163" ID="ID_2ce6d49453c7" MODIFIED="1626626183163" TEXT="Executors&amp;nbsp;工具类"><node CREATED="1626626183163" ID="ID_2c4b6f2de0df" MODIFIED="1626626183163" TEXT="更方便"></node><node CREATED="1626626183163" ID="ID_69702ac7fd1d" MODIFIED="1626626183163" TEXT="线程池最大线程数的设置考量（假设&amp;nbsp;corePoolSize&amp;nbsp;=&amp;nbsp;N）"><node CREATED="1626626183163" ID="ID_0d51530700e7" MODIFIED="1626626183163" TEXT="CPU&amp;nbsp;密集型：maximumPoolSize&amp;nbsp;=&amp;nbsp;N&amp;nbsp;或&amp;nbsp;N+1"></node><node CREATED="1626626183163" ID="ID_d161a86dda76" MODIFIED="1626626183163" TEXT="IO&amp;nbsp;密集型：maximumPoolSize&amp;nbsp;=&amp;nbsp;2N&amp;nbsp;或&amp;nbsp;2(N+1)"></node></node></node></node><node CREATED="1626626183163" ID="ID_d7c82d8e5bd8" MODIFIED="1626626183163" TEXT="基础接口"><node CREATED="1626626183163" ID="ID_c7f7662e7960" MODIFIED="1626626183163" TEXT="interface&amp;nbsp;Callable"><node CREATED="1626626183163" ID="ID_702a082cc1cf" MODIFIED="1626626183163" TEXT="仅一个&amp;nbsp;call()&amp;nbsp;方法，有泛型的返回值"></node></node><node CREATED="1626626183163" ID="ID_e88e925bbdca" MODIFIED="1626626183163" TEXT="interface&amp;nbsp;Future"><node CREATED="1626626183163" ID="ID_1322325410c2" MODIFIED="1626626183163" TEXT="作用：对应异步执行的一个任务，最终需要拿到其返回值"></node><node CREATED="1626626183163" ID="ID_85328d7e8fb9" MODIFIED="1626626183163" TEXT="重要方法：get()，有2个重载方法"><node CREATED="1626626183163" ID="ID_4fb9331f85cf" MODIFIED="1626626183163" TEXT="预期异步线程很快执行完：get()&amp;nbsp;throws&amp;nbsp;InterruptedException,&amp;nbsp;ExecutionException"></node><node CREATED="1626626183163" ID="ID_f883e093b39a" MODIFIED="1626626183163" TEXT="异步线程的执行时间不确定：get(long&amp;nbsp;timeout,&amp;nbsp;TimeUnit&amp;nbsp;unit)&amp;nbsp;throws&amp;nbsp;InterruptedException,&amp;nbsp;ExecutionException,&amp;nbsp;TimeoutException"></node></node></node></node></node></node></map>