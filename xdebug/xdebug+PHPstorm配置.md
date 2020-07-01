# xdebug+PHPstorm配置

[TOC]

之前整理了一张[xdebug工作原理图]([https://github.com/Thobian/web-learning-plan/blob/master/xdebug/xdebug%E5%90%84%E7%A7%8D%E5%9C%BA%E6%99%AF%E4%B8%8B%E7%9A%84%E5%B7%A5%E4%BD%9C%E6%A8%A1%E5%BC%8F.jpg](https://github.com/Thobian/web-learning-plan/blob/master/xdebug/xdebug各种场景下的工作模式.jpg))，但由于偷懒没有写教程如何在IDE（PHPstorm）中使用xdebug配置进行开发调试，最近由于更换新开发机器需要重新配置环境，故将配置过程也整理了一下以做归纳总结。

## xdebug原理

先对之前整理的原理图做一点点解释，算是对文字版的xdebug工作原理图。这里只会讲最简单的单机本地开发调试模式，其他模式有了单机本地的基础也比较好理解。

![xdebug单机本地开发调试模式原理图](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202007/01/131827-719786.png)

1. 用户在浏览器访问待联调的地址（当然也可以是终端控制台里面）；

2. 请求到达PHP解析器，如果有开启xdebug调试功能（也就是 `xdebug.remote_enable=1`）就向`xdebug.remote_host:xdebug.remote_port` 发起断点调试请求。

   本地联调 `remote_host`  自然就是 127.0.0.1， `remote_port` 就是你IDE当前监听的联调接口。PHPstorm默认监听的是 9000（配置在：`Settings->Languages&Frameworks->PHP->Debug->xdebug` 下）；

3. IDE收到调试请求后看是否存在断点，存在就进入断点调试，并等待下一条指令（step into/step out这些），否则进入下一行代码。

在这个过程中 xdebug（PHP扩展）相当于客户端，PHPstorm相当于服务器（默认监听9000端口），他们之间的网络通信使用的是一种叫做 [DBGp](https://xdebug.org/docs/dbgp) 的协议。

## xdebug+PHPstorm使用

理解xdebug工作原理后，我们进入实操部分，三步就能搞定。

### 第一步、安装xdebug扩展

这部分不介绍，网上有不少文章写PHP如何安装扩展的。

### 第二步、xdebug配置

这里仅仅列出了常用配置，更多配置项可以通过 `phpinfo()` 查看，每个配置项的解释要弄清楚需要自己去啃官方文档，反正我是很多不知道啥含义的。（修改完配置后记得重启fpm）

```ini
[XDebug]
zend_extension="xdebug.so"       # 没啥好说，扩展文件
xdebug.remote_enable = 1         # 开启远程调试，设置为0相当于关闭了xdebug功能
xdebug.remote_host = "127.0.0.1" # 你IDE所处的机器IP，本地开发联调自然就是127.0.0.1
xdebug.remote_port = 9000        # 你IDE上xdebug服务监听的端口，PHPstorm默认9000
xdebug.remote_autostart = 1      # 收到请求就进入调试模式，如果配置为0需要请求带有XDEBUG_SESSION_START参数（不启用DBGp Proxy参数值可以任意），为什么这么配置因为主要是方便命令行调试

# 下面的配置都只是介绍，删除下面配置也不影响单机开发调试xdebug的工作
xdebug.remote_handler = "dbgp"   # 这个就是默认值，不要改
xdebug.idekey="PHPSTORM"         # 这个配置项大部分情况下可删除不配置，仅通过DBGp Proxy调试时才需要
xdebug.remote_connect_back=0     # 多机开发但在同一台测试机上测试时使用，这时remote_host将不再有效
```

### 第三步、PHPstorm设置

**一、**设置PHPstorm监听的端口，必须跟 php.ini 中 `xdebug.remote_port` 的值保持一样。

![PHPstorm debug port](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202007/01/131834-331167.png)

**二、**打开PHPstorm xdebug监听模式。

![打开监听模式](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202007/01/131848-15378.png)

**三、**配置到这一步，你就可以在浏览器去访问你的站点了。这时你的PHPstorm将弹出类似如下提示框，让你确认是否要接收这个调试请求 **Accept** 就好。然后就可以对你的项目愉快的进行断点调试了。

![确认接受调试](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202007/01/131846-708770.png)

## 更多说明

通过上面简单的3步，一个本地开发联调所有配置就好了。不过很多同学喜欢将自己代码运行在虚拟机或者docker中，这时候又应该怎么配置了？

其实也很简单，简单的调整两个配置就好了：

1.  `xdebug.remote_host` 不能再是 127.0.0.1 了，而应该改成**物理机IP地址**;

2. 由于虚拟机的目录结构，跟本地文件系统目录结构大概不一样，需要在PHPstorm做一个目录映射。

   ![目录映射](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202007/01/131840-72560.png)