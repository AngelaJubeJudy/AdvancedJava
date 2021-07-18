import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 本周作业：（必做）思考有多少种方式，在main函数启动一个新线程或线程池，
 * 异步运行一个方法，拿到这个方法的返回值后，退出主线程.
 *
 *
 */
public class Homework04 {

//    private final ThreadGroup group;
//    private final AtomicInteger threadNumber = new AtomicInteger(1);
//    private final boolean daemon;
    
    public static void main(String[] args) throws InterruptedException {
        System.out.println("---------------------Main thread started. ---------------------");
        long start=System.currentTimeMillis();

        // 创建一个线程或线程池，异步执行斐波那契数列
        CountDownLatch countDownLatch = new CountDownLatch(5);
        for(int i = 0; i < 5; i++){
            Thread thread = new Thread(new getSum(i, countDownLatch));
            thread.start();
        }

        Runner1 runner1 = new Runner1();
        Thread thread1 = new Thread(runner1);
        thread1.start();
        int asc_result = sum(6);
        thread1.interrupt();
        
        // 输出结果
        int result = sum(6);
        System.out.println("Synchronous Result: " + result);

        System.out.println("Asynchronous Result: " + asc_result);

        System.out.println("Duration: "+ (System.currentTimeMillis()-start) + " ms");
        Thread.sleep(10L);

        System.out.println("---------------------Main thread terminated. ---------------------");
    }

    static class getSum implements Runnable{
        private int id;
        private CountDownLatch latch;

        public getSum(int id, CountDownLatch latch){
            this.id = id;
            this.latch = latch;
        }

        @Override
        public void run() {
            synchronized (this){
                System.out.println("id: "+id+","+Thread.currentThread().getName());
                System.out.println("Task No."+id+" Finished: result = "+sum(6)+", others continue...");
                latch.countDown();
            }
        }
    }

    static class Runner1 implements Runnable {
        @Override
        public void run() {
            for (int i = 0; i < 10; i++) {
                System.out.println("Runner1 runnable counting down ...... " + i);
            }
        }
    }

//    @Override
//    public Thread newThread(Runnable r) {
//        Thread t = new Thread(group, r, "-thread-" + threadNumber.getAndIncrement(), 0);
//        t.setDaemon(daemon);
//        return t;
//    }
    
    private static int sum(int input) {
        return fibo(input);
    }
    
    private static int fibo(int a) {
        if ( a < 2) 
            return 1;
        return fibo(a-1) + fibo(a-2);
    }
}
