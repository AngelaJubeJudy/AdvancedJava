# 配置明细
## 1. （`必做`）配置 redis 的主从复制，sentinel 高可用，Cluster 集群
### 主从复制
* 配置主从：
    ```redis-cli
    127.0.0.1 6380> SLAVEOF 127.0.0.1 6379
    127.0.0.1 6380> info
    # Replication
    role:slave
    127.0.0.1 6380> get port 
    6379
    127.0.0.1 6380> set port sss
    (error) READONLY You can't write against a read only replica.
    ```
* 配置文件 redis6379.conf
    ```conf
    # 端口
    port 6379
    # pid 文件
    pidfile "/var/run/redis_6379.pid"
    # 数据文件夹
    dir "/Users/xxx/logs/redis0"
    # IO 线程数（可配置）
    io-threads 4
    # AOF 模式
    appendfilename "appendonly.aof"
    # 数据日志的持久化方式
    appendonly no
    # 刷盘策略
    appendfsync always
    ```
* 配置文件 redis6380.conf
    ```conf
    # 端口
    port 6380
    # pid 文件
    pidfile "/var/run/redis_6380.pid"
    # 数据文件夹
    dir "/Users/xxx/logs/redis1"
    # IO 线程数（可配置）
    io-threads 4
    # AOF 模式
    appendfilename "appendonly.aof"
    # 数据日志的持久化方式
    appendonly no
    # 刷盘策略
    appendfsync always
    # 配置该节点从启动时就作为从库
    replicaof ::1 6379
    ```
* 启动 Redis Server
    ```bash
    redis-server redis6379.conf
    redis-server redis6380.conf
    ```


## sentinel 高可用
* 无需配置从节点：主从网络拓扑信息可以通过“info”命令获取
* 启动 redis servers
    ```bash
    redis-server redis6379.conf
    redis-server redis6380.conf
    ```
* 配置主从 
    ```redis-cli
    127.0.0.1 6380> SLAVEOF 127.0.0.1 6379
    ```
* 主库清空数据；检查
    ```redis-cli
    127.0.0.1 6379> flushall
    127.0.0.1 6379> info
    ```
* 修改配置文件 sentinel0.conf
    ```conf
    sentinel monitor mymaster 127.0.0.1 6379 2
    sentinel down-after-milliseconds mymaster 60000
    sentinel failover-timeout mymaster 1800000
    sentinel parallel-syncs mymaster 1
    port 26379
    ```
* 修改配置文件 sentinel1.conf
    ```conf
    sentinel monitor mymaster 127.0.0.1 6379 2
    sentinel down-after-milliseconds mymaster 60000
    sentinel failover-timeout mymaster 1800000
    sentinel parallel-syncs mymaster 1
    port 26380
    ```
* 启动 redis sentinel
    ```bash
    redis-sentinel sentinel0.conf
    redis-sentinel sentinel1.conf
    ```
* 宕机模拟：在 redis6379 使用 Ctrl+C 停止服务
    * 重启 redis6379，则发现 redis6379 已转换成 6380 的 slave（sentinel 负责完成主从间的角色转换）。


## Cluster 集群
### 方式一：手动
* 创建容器
    ```bash
    sudo docker run --name redis2 -v /redis2/redis.conf:/redis-5.0.8/redis.conf -d redis
    sudo docker exec –it <containerId> sh
    ```
* 创建节点
    ```bash
    mkdir 7000 7001 7002 7003 7004 7005
    echo /redis2/7000 /redis2/7001 /redis2/7002 /redis2/7003 /redis2/7004 /redis2/7005 | xargs -n 1 cp -v /root/redis-5.0.8/redis.conf
    ```
* 修改各节点配置文件 redis.conf（以7000为例）
    ```conf
    # 端口
    port 7000
    # pid 文件
    pidfile "/var/run/redis_7000.pid"
    # 数据文件夹
    dir "/redis2/7000"
    # AOF 模式
    appendfilename "appendonly.aof"
    # 数据日志的持久化方式
    appendonly no
    # 刷盘策略
    appendfsync always
    ```
* 各节点实例启动文件 /etc/init.d/redis_7000（以7000为例）
    * 修改
    ```bash
    REDISPORT=7000
    EXEC=/root/redis-5.0.8/src/redis-server
    CLIEXEC=/root/redis-5.0.8/src/redis-cli
    PIDFILE=/var/run/redis_${REDISPORT}.pid
    CONF="/redis2/${REDISPORT}/redis.conf"
    ```
    * 启动各节点
    ```bash
    sudo /etc/init.d/redis_7000 start
    ```
* 启动集群
    ```bash
    redis-cli --cluster create 120.0.0.1:7000 120.0.0.1:7001 120.0.0.1:7002 120.0.0.1:7003 120.0.0.1:7004 120.0.0.1:7005 --cluster-replicas 1
    ```
    * 可能遇到的问题：3个Master节点未完全分配slots，导致集群构建失败。
        * 解决：[1](https://github.com/AngelaJubeJudy/AdvancedJava/blob/main/week12/111.png)，[2](https://github.com/AngelaJubeJudy/AdvancedJava/blob/main/week12/112.png)，[3](https://github.com/AngelaJubeJudy/AdvancedJava/blob/main/week12/113.png)
    * 可能遇到的问题：docker pause一个redis container，查询CLUSTER INFO发现整个集群都fail了，slave node没有自动升级为master node.
        * 解决：在redis-cli中使用CLUSTER FAILOVER FORCE命令（在此之前请在各节点redis.conf文件中配置masterauth一项）。[4](https://github.com/AngelaJubeJudy/AdvancedJava/blob/main/week12/114.png)    
* 检查
    ```redis-cli
    127.0.0.1 7000> CLUSTER INFO
    127.0.0.1 7000> CLUSTER NODES
    ```

### 方式二：脚本自动化
* 节点配置脚本
    ```bash
    # ./addNodesConf：通过脚本创建6个redis配置
    for port in $(seq 1 6); \
    do \
    mkdir -p /root/redis/node-${port}/conf
    touch /root/redis/node-${port}/conf/redis.conf
    cat << EOF >/root/redis/node-${port}/conf/redis.conf
    port ${port}
    bind 0.0.0.0
    cluster-enabled yes
    cluster-config-file /root/redis/node-${port}/conf/nodes.conf
    cluster-node-timeout 5000
    appendonly yes
    daemonize yes
    EOF
    done
    ```
* 分配槽位脚本
    ```bash
    #!/bin/bash
    # node1 10.200.207.121   172.8.0.7
    for ((i=0;i<=5461;i++))
    do
    /home/redis/redis-5.0.8/src/redis-cli -h 10.200.207.121 -p 7000 CLUSTER ADDSLOTS $i
    done

    # node2 10.200.207.121    172.17.0.4
    for ((i=5462;i<=10922;i++))
    do
    /home/redis/redis-5.0.8/src/redis-cli -h 10.200.207.121 -p 7001 CLUSTER ADDSLOTS $i
    done

    # node3 10.200.207.121    172.17.0.3
    for ((i=10923;i<=16383;i++))
    do
    /home/redis/redis-5.0.8/src/redis-cli -h 10.200.207.121 -p 7002 CLUSTER ADDSLOTS $i
    done
    ```
* 启动集群
    ```bash
    redis-cli --cluster add-node 10.200.207.121:7001 10.200.207.121:7002 10.200.207.121:7003 10.200.207.121:7004 10.200.207.121:7005 --cluster-slave --cluster-master-id 7955a10c8bbb496526c59ff21bed711f16c1c81b
    ```
* 检查
    ```redis-cli
    10.200.207.121 7001> CLUSTER INFO
    10.200.207.121 7001> CLUSTER NODES
    ```

### 方式三：命令启动
* 启动
    ```redis-cli
    cluster-enabled yes
    ```
* 检查
    ```redis-cli
    127.0.0.1 6380> CLUSTER INFO
    127.0.0.1 6380> CLUSTER NODES
    ```
