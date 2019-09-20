### **服务安装**

gitlab有点吃性能，官方推荐最低配置：2核8G(可以服务100个用户)，具体的硬件要求可以看：https://docs.gitlab.com/ee/install/requirements.html

centos下具体的安装步骤可以参考：https://about.gitlab.com/install/#centos-6

抛去前置环境的话，就两条命令：

```shell
# 安装源
$ curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash

# 企业版可以指定**EXTERNAL_URL**参数，社区版应该也行。EXTERNAL_URL就是gitlab的访问链接
$ yum install gitlab-ce 
```

### **管理维护**

**配置文件：**

```shell
/etc/gitlab/gitlab.rb 
```

**启动：**

```shell
# 刚安装上，可能要修改下配置等  修改完配置让其生效的命令是
$ gitlab-ctl reconfigure

# gitlab本质是个服务（类似MySQL、Nginx这些），所以他还有一种启动方式是
# 名字不确定是否有差异，反正这里可以找到： ls /lib/systemd/system/|grep gitlab 
$ systemctl start gitlab-runsvdir 

# 上面两种方式都会默认都会把 gitlab 下面那一堆服务都拉起来，非常耗资源。如果想暂停某个功能
# 【重要】这种方式关闭只是临时的，下次重启还是会全部拉起。好像还没办法永久关闭，虽然gitlab.rb里面有相关的配置，好像改完reconfigure之后继续全部开启
$ gitlab-ctl stop $serviceName

# gitlab-ctl 很强大，更多使用方法可以看他的help信息
```

**瘦身：**

gitlab默认开启了很多服务，并且配置还是按照 他们推荐硬件配置开启的，所以如果是在自己电脑上玩，那个配置很不合适，非常耗资源，必须瘦身一下。

```shell
# 默认开的服务有
alertmanager            # 可以不开启，看名字是通知告警有关，关闭后不影响主要功能
gitlab-monitor          # 可以不开启，看名字是监控上报有关，关闭后不影响主要功能
grafana                 # 可以不开启，不知道做啥的，好像是个插件，关闭不影响主要功能
logrotate               # 可以不开启，看名字是日志切割有关，关闭后不影响主要功能
node-exporter           # 可以不开启，估计是Node监控相关，关闭后不影响主要功能
postgres-exporter       # 可以不开启，估计是postgres监控相关，关闭后不影响主要功能
redis-exporter          # 可以不开启，估计是Redis监控相关，关闭后不影响主要功能

gitaly                  # 不知道做什么的，关了就会工作不太正常
gitlab-workhorse        # 不知道做什么的，关了就会工作不太正常
nginx                   # web服务器
postgresql              # 数据库
prometheus              # 据说是一套云上监控系统，更多的可以看看这个文档：https://yunlzheng.gitbook.io/prometheus-book/
redis                   # 缓存服务器
sidekiq                 # 不知道做什么的，好像runner跟他有些关系
unicorn                 # 不知道做什么的
```

将上面那一堆，非必须服务关闭后，可以省下不少资源。但如果必须要开启上面那些，那就只能改 gitlab.rb 文件

```shell
# 不知道什么进程数，官方推荐最高效配置是 CPU核数+1，可以调小
sidekiq['concurrency'] = 5
# 不知道什么进程数，可以调小一些
unicorn['worker_processes'] = 8
# 数据库缓存大小，可以调小一些
postgresql['shared_buffers'] = "256MB"
# 数据库最大并发数，可以调小
postgresql['max_worker_processes'] = 8
```

### **runner**

runner安装、注册也都是常规操作，按照官方文档一步步来肯定都不会有问题。下面的说明是以 docker 方式来运行gitlab-runner

```shell
# 安装runner
# docker安装工具永远都是那么简单，需要注意下里面的几个参数 
# --rm 关闭容器后删除容器副本，正式环境不会这么玩，一般是换成：--restart always
# -v 将本地磁盘，挂载到容器内，用于存放 register 后的配置文件，这个很有必要，要不容器挂了后配置就丢了
# 【重要】--add-host 这个参数会让容器跑起来后，自动往host文件（linux下在 /etc/hosts） 加上你指定的配置。像我这种用默认 gitlab.example.com 肯定是要加这个的，官方教程是不会告诉你这个的
$ sudo docker run --rm --name gitlab-runner -v /srv/gitlab-runner/config:/etc/gitlab-runner  -v /var/run/docker.sock:/var/run/docker.sock --add-host gitlab.example.com:192.168.222.129  gitlab/gitlab-runner  

# 注册runner
# 注册runner的本质其实就是往 runner 的配置文件（/srv/gitlab-runner/config/config.toml）中写配置，不过它会帮你检查你的某些值否正确，如果你更喜欢直接写配置文件，直接改那个文件也是可以的

# 官方教程给的是，再起一个 gitlab/gitlab-runner 临时容器，运行 gitlab-runner register
# 官方注册教程：https://docs.gitlab.com/runner/register/#docker
$ docker run --rm -t -i -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register

# 个人更喜欢直接进入容器，运行 gitlab-runner register 来注册runner
$ docker exec -it $containerID bash  # 物理机，进入容器的方式
$ gitlab-runner register             # 运行注册程序

# 顺便提下，通过docker方式运行runner，runner的日志都会直接输出到容器终端，所以通过  docker logs -f containerID 就可以直接查看实时日志了，还挺方便
```

一路下来，基本不会碰到什么问题。但万万没想到，你这时候去 gitlab 执行pipeline，还是会报错。错误如下：

![1567925722573](https://static.jiebianjia.com/typora/0d5c52fff08d87d4d842e650e2b528ad.png)

看出来了没 还在报： `Could not resolve host：gitlab.example.com` 

这时候你去看 runner 的日志，你会发现它正常的拉取（日志显示的是**received**，但这里本质是runner不断的的去轮询gitlab看似否有待处理的job）到了 gitlab的job，但就是就是不能正常执行完。

细想下runner工作的原理，不难发现 ：虽然runner容器你增加了host配置，但真正执行job的容器并不是runner所在的容器而是由runner收到job后拉起来的，runner 配置文件并没有执行拉起job容器时也需要添加host，所以问题还是出在配置文件中。需要手动编辑 `/srv/gitlab-runner/config/config.toml` 文件，加点料：

```shell
[[runners]]
  name = "runner_php"
  url = "http://gitlab.example.com/"
  token = "zW9Zc5xxxxxgp2gk"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.docker]
    tls_verify = false
    image = "php"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    # 说的就是它，必须手动加上，配置文件中是否这种方式为注释 不确定，最好复制的时候把这一行删掉
    extra_hosts = ["gitlab.example.com:192.168.222.129"]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

对于加深runner、pipeline的理解，推荐这个文章：https://scarletsky.github.io/2016/07/29/use-gitlab-ci-for-continuous-integration/

### 感悟总结

资料看再多，不如直接上手操作一遍。自己过一遍，很多之前理解不到位的东西自己跑一遍、实验一下就理解了。

