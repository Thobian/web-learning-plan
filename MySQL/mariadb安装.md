# MariaDB集群安装

MariaDB 是基于MySQL社区版开发出来的关系型数据库管理系统，得到了越来越多人的认可。这次搭建MariaDB主要还是想了解下它的集群工作方式，平时只是停留在使用的上，并没有真正自己去搭建、了解集群原理。

### 环境说明

操作系统：Centos 7

硬件环境： 1核 1G（VMware虚拟机）

MariaDB版本：5.5.64-MariaDB

机器IP：192.168.222.128、192.168.222.129、192.168.222.130 

### 单机安装教程

单机环境下安装是最简单的，可以说一个 `yum` 命令就搞定了。

##### 第一步、确定安装的版本

目前MariaDB有众多版本，从最开始 `5.1` 到现在最新的 `10.5` ，各版本之间的差异需要自己去了解（嘿，问我也没用我也不知道）。

大概你也跟我一样会有点好奇为什么MariaDB的版本会这么奇怪，一开始就来了个 5.1？翻了下 他们官方的说明，大致是说： MariaDB 5.1是基于MySQL5.1开发的，并且每个月还会将MySQL5.1的代码合并进去一次。不过虽然MariaDB5.1是基于MySQL5.1开发的，但它却有着MySQL5.5一样的性能，并且也增加了一些新的特性。

更多关于MariaDB的发布版本，以及版本特性可以查看 [官方介绍文档](https://mariadb.com/kb/en/mariadb-server/)

本文就以安装 **MariaDB 10.2** 为例进行讲解演示。这个数据库安装在：`192.168.222.128` 机器上

##### 第二步、添加yum源

centos默认yum源下面是找不到MariaDB的需要手动添加，我们先在 `/etc/yum.repos.d/` 新建一个repo文件

```shell
# 新建 mariadb.repo 文件，用于设置MariaDB yum源
$ vi /etc/yum.repos.d/mariadb.repo
```

根据需要安装的版本，将MariaDB的源写入到 `mariadb.repo`：

```shell
# MariaDB 10.2 CentOS repository list - created 2020-01-11 13:29 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

这个源怎么来的，当然是通过官方网站获取最稳妥，在线根据自己环境生成repo配置：https://downloads.mariadb.org/mariadb/repositories/

##### 第三步、安装

现在已经万事俱备，就待我们运行安装命令：

```shell
# 同时安装服务端和客户端（客户端就是我们经常使用的mysql命令）
$ yum install MariaDB-server MariaDB-client
```

##### 第四步、收尾

其实安装过程到第三步就已经结束了，不过刚安装好当然要登录进去看下并且给root账号设置个登录密码等等。

```shell
# 启动服务端
$ systemctl start mariadb

# 登录MariaDB，新安装的root账号没有密码，登录进去给他设置一个
$ mysql -uroot

# 给root加上密码绝对这是个好习惯，哪怕是自己学习用的环境，另外还有其他host的root账号建议删掉
$ MariaDB [(none)]> SET PASSWORD FOR root@'127.0.0.1' = password('xxx');

# 新安装，默认还会有匿名账号建议也删掉
```

如果只是单机安装的话，那整个过程就结束了，但我们目的是搭建一个 MariaDB 的集群，所以让我们继续



### 集群搭建教程

官方对“集群”有个统称是 `High Availability` ，分两种方式：MariaDB Replication （主备副本方式）
）、MariaDB Galera Cluster（galera集群方式）

我们先从 MariaDB Replication 说起，它的搭建相对简单

#### MariaDB Replication

`MariaDB Replication` 也是我们经常听到的主从方式，主库可以读写，从库从主库同步数据只能读。这种方式官方比较推荐的场景是：Scalability（读多写少的情况下）、Data analysis、Distribution of data

更多关于 replication 方式的介绍，可以自己去查看官方文档：[Replication Overview](https://mariadb.com/kb/en/replication-overview/)

下面开始介绍如何搭建一个最简单（1主1从）的 Replication MariaDB集群。

**注意**：集群搭建时，操作顺序比较重要，特别是从机安装好后，除了设置账号密码之外请都安装文档操作！！！

**注意**：集群搭建时，操作顺序比较重要，特别是从机安装好后，除了设置账号密码之外请都安装文档操作！！！

**注意**：集群搭建时，操作顺序比较重要，特别是从机安装好后，除了设置账号密码之外请都安装文档操作！！！

##### 第一步、增加一台从库

由于在 **单机安装教程** 中，已经在 `192.168.222.128` 上面安装了第一台MariaDB服务器。

我们复用下资源，就将它作为我们 Replication 模式的主库，所以只需要按照单机教程在 `192.168.222.129` 上从库也先安装起来。

具体安装步骤参考单机安装教程就好，再次强调服务安装好后尽量不要对它有操作，先不启动它是最好的。

##### 第二步、设置主库

replication方式是依赖 binlog 来进行，所以第一步需要先打开MariaDB的binlog设置，打开MariaDB服务配置文件：`/etc/my.cnf.d/server.cnf`（不同版本可能位置不一样）

```shell
# log-bin 表示开启 binlog
# server_id 设置集群ID，只能是数字最大支持 2^32 ，统一集群中的MariaDB服务不能重复
# log-basename binlog文件的前缀，比如下面的配置之后binlog日志文件名大概长这样：master1-bin.xxxxx
# 改了cnf配置，自然不能忘了重新加载配置 systemctl reload mariadb
[mariadb]
log-bin
server_id=1
log-basename=master1
```

主库配置就完了，因为从库要同步数据肯定是需要通过账号密码登录主库的，所以我们还需要在主库创建一个账号

```shell
# 新增一个 replication_user 用户，密码为：123，
$ MariaDB [(none)]> CREATE USER 'replication_user'@'%' IDENTIFIED BY '123';
$ MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
$ MariaDB [(none)]> flush privileges;
```

主库的配置到这里就结束了，但为了我们后面从库知道从主库的什么位置开始同步数据，需要先知道主库当前binlog的位置（如果有历史数据，情况会比较复杂 这里不展开）

```shell
# 主要是记下 Position 的值，后续从库设置需要用到它
$ MariaDB [test]> show master status;                           
+-----------------------+----------+--------------+------------------+
| File                  | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+-----------------------+----------+--------------+------------------+
| master1-bin.000003    |     1533 |              |                  |
+-----------------------+----------+--------------+------------------+

# 如果上面的 Position 不是你要开始同步的起点，可以通过下面的命令查询到详细的binlog日志，找到你希望开始同步的起点
$ MariaDB [test]> show binlog events in 'master1-bin.000003';
+--------------------+------+------------+-----------+-------------+-------------------+
| Log_name           | Pos  | Event_type | Server_id | End_log_pos | Info              |
+--------------------+------+------------+-----------+-------------+-------------------+
| master1-bin.000003 | 1347 | Gtid       |         1 |        1389 | BEGIN GTID 0      |
| master1-bin.000003 | 1389 | Query      |         1 |        1502 | use `test`; ....  |
| master1-bin.000003 | 1502 | Xid        |         1 |        1533 | COMMIT /* xi */   |
+--------------------+------+------------+-----------+-------------+-------------------+
```

这里我们就记住这个 **1533**，做为从库同步日志的起点。

##### 第三步、设置从库

同样从库也需要设置一个`server_id`，打开 `/etc/my.cnf.d/server.cnf` ：

```shell
# 注意从库不要开启binlog
# server_id 设置集群ID，只能是数字最大支持 2^32 ，统一集群中的MariaDB服务不能重复
# 改了cnf配置，自然不能忘了重新加载配置 systemctl reload mariadb
[mariadb]
server_id=2
```

使用 `CHANGE MASTER TO` 配置主库连接信息

```shell
# 主库IP、同步账号、密码、端口、binlog日志文件、开始同步位置
# 上面的这些参数肯定都需要跟进你的实际情况进行调整，照抄肯定是要出错滴
$ MariaDB [test]>CHANGE MASTER TO
  MASTER_HOST='192.168.222.128',
  MASTER_USER='replication_user',
  MASTER_PASSWORD='123',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='master-128-bin.000003',
  MASTER_LOG_POS=1533,
  MASTER_CONNECT_RETRY=10;
```

连接信息已准备好，但MariaDB并不会自动给我们开始从同步，还需要手动去启动同步功能：

```shell
# 启动slave同步
$ MariaDB [none]> start slave;

# 确认下启动成功，比如由于防火墙拦截等可能出现命令运行成功，但同步仍然不正常情况的，所以我们确认下
# 看到 Slave_IO_Running、Slave_SQL_Running 都变成 Yes 那就说明成功了
$ MariaDB [none]> show slave status\G;
*************************** 1. row ***************************
                      (省略更多信息...)
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
                      (省略更多信息...)
```

OK，到这里可以说 Replication 1主1从的搭建就完成了。让我们做更多点，验证下这个主从同步是否正常。

##### 第四步、验证主从同步

其实验证过程很简单

1. 登录 **主库**，新建一个数据库、在新建的数据库下添加个表，然后在对表进行一些日常的增删改查；
2. 登录 **从库**，看下刚刚新建的数据库、表、记录是否都完全一致。不出意外是完全一致，验证也就结束了

但等等，如果我们在 **从库** 往对应的表里面新增记录会发送什么？实验告诉你，新增成功！！！ 

是不是感觉哪里不对，如果哪天一个不小心去从库写了一堆记录，并且主键跟主库后面新产生的记录冲突，那必定会导致 我们主从架构出问题，让我们来解决它。

MariaDB非常贴心的准备了一个叫：`read_only` 的配置开关，默认是关闭的也就是我们不仅可以读数据库的内容，也能往里面写入数据。打开这个开关后除拥有 super 权限的用户外（比如root账户），其他普通用户都不能对数据库进行**增删改**这些动作（当然建表、建库就更不被允许了）。

所以通过 `read_only `这个开关就能非常完美的解决，我们上面的那问题。那问题又来了，如何设置这个开关，有两种方式：

1. 登录root账号，设置全局变量：`set global read_only=1;` 。这个方式有个缺点 重启后又变回默认值；
2. 修改配置文件，找到MariaDB配置文件（`/etc/my.cnf.d/server.cnf` ），在 `[server]` 配置组下面增加一个配置：`read_only=1`。这样就决定了方法1中的缺点；

到这里，整个搭建 MariaDB Replication 1主1从的教程就真的完全结束了，下面让我们进入更高级的 MariaDB Galera Cluster搭建。

#### MariaDB Galera Cluster





```shell
# 错误
Error: Package: galera-25.3.25-1.rhel6.el6.x86_64 (mariadb)
           Requires: libboost_program_options.so.5()(64bit)
 You could try using --skip-broken to work around the problem
 You could try running: rpm -Va --nofiles --nodigest
 
 yum clean all
 
 yum install MariaDB-server(注意大小写)
(1/7): MariaDB-common-10.2.27-1.el7.centos.x86_64.rpm   # 一些
(2/7): MariaDB-compat-10.2.27-1.el7.centos.x86_64.rpm  
(3/7): MariaDB-client-10.2.27-1.el7.centos.x86_64.rpm
(4/7): lsof-4.87-6.el7.x86_64.rpm
(5/7): rsync-3.1.2-6.el7_6.1.x86_64.rpm
(6/7): galera-25.3.27-1.rhel7.el7.centos.x86_64.rpm
(7/7): MariaDB-server-10.2.27-1.el7.centos.x86_64.rpm
```

MariaDB 10.2 集群安装



# Getting Started with MariaDB Galera Cluster：https://mariadb.com/kb/en/library/getting-started-with-mariadb-galera-cluster/



跟你你系统的情况生成在线安装repository地址： https://downloads.mariadb.org/mariadb/repositories/

MariaDB官方提供的yum源巨慢无比，只能靠清华来拯救你了：https://mirrors.ustc.edu.cn/help/mariadb.html



https://mariadb.com/kb/en/library/getting-started-with-mariadb-galera-cluster/#configuring-mariadb-galera-cluster



包括两种安装方式：主从、多主

https://blog.csdn.net/rzlongg/article/details/90345708

https://www.cnblogs.com/zhou2019/p/10594628.html



配置文件的一些说明，特别对于 **配置组** 的说明，比较详细：

https://mariadb.com/kb/en/library/configuring-mariadb-with-option-files/



高可用相关文档：（关于集群的文章都在里面）

https://mariadb.com/kb/en/library/replication-cluster-multi-master/

主从架构时，需要用到的一些命令：

https://mariadb.com/kb/en/library/replication-commands/

怎么开启MySQL副本（replication）功能：

https://mariadb.com/kb/en/setting-up-replication/#replicating-from-mysql-master-to-mariadb-slave