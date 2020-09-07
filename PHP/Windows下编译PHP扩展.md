# Windows下编译PHP扩展

事情得从前阵子Windows本地PHP开发环境变得越来越慢说起，当时尝试了很多种方式去寻找一个更快的PHP开发环境，比如：docker、wsl等，但最后效果都不是很理想。

于是想从另一种方式入手：分析代码性能，找出具体什么地方慢，但不巧的是PHP常用的一个性能分析工具 [xhprof ](https://www.php.net/manual/zh/book.xhprof.php) 并没有我需要的扩展版本（7.0.27），就这样走上了编译PHP Windows扩展之路。

## 1. 编译工具

### 1.1 收集PHP信息

动手编译前，先了解自己PHP的一些基本信息，包括：**版本**、**编译器**（Compiler）、**架构**（Architecture）、**线程安全否** ，这些信息通过 [phpinfo](https://www.php.net/manual/zh/function.phpinfo.php) 很容易获得，比如我本地phpinfo截图如下：

![本地环境截图](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202009/07/195621-287859.jpeg)

### 1.2 安装编译环境Visual Studio（IDE）

有了上面收集的PHP信息，接着就是根据 上一步收集的 **编译器** ，下载支持对应编译器的VS版本，比如我本地的是：MSVC14 (Visual C++ 2015) ，那我需要下载的就是：Visual Studio 2015 。

指定版本的PHP，需要用哪个版本编译器编译，具体编译器的版本又被哪个Visual Studio版本支持，PHP官方有提供一个查询页面：[Supported compilers to build PHP on Windows](https://wiki.php.net/internals/windows/compiler)

![下载VS社区版](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202009/05/114523-636884.png)

另外安装时有个需要特别注意的地方，一定要勾选上 **Visual C++** 这个组件，这个里面才有我们需要的编译器。当然你担心自己弄错可以把它那一堆组件全勾选上，只不过浪费点空间而已。

![Visual Studio安装截图](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202009/07/200321-985592.png)

如果不出什么幺蛾子，安装好之后你的开始菜单下面应该可以看到这两个快捷方式： **VS2015 x64 Native Tools Command Prompt** 、**VS2015 x86 Native Tools Command Prompt** ，一个是编译32程序的，一个是编译64位程序的，后面需要用到他们。

### 1.3 安装php-sdk-binary-tools

php-sdk 里面有一堆编译时需要用到的工具，然而它跟PHP版本有很大差异：

PHP7.2以下版本，下载链接：[php-sdk](https://windows.php.net/downloads/php-sdk/) ，进去可以看到多个版本，下载最新的就好；

PHP7.2及以上版本，下载链接：[php-sdk](https://github.com/microsoft/php-sdk-binary-tools/releases) ，同样下载最新版本；

## 2. 编译环境

> 由于php-sdk存在PHP的版本差异，而我本地环境是7.0.27，这部分内容并不适用于PHP7.2及以上版本，不过PHP7.2及以上版本的编译也基本大同小异。PHP7.2及以上版本可以参考官方文档：https://wiki.php.net/internals/windows/stepbystepbuild_sdk_2

前面我们准备好了工具，但并没有完还需要继续准备。既然我们要编译源码，没有代码怎么行？所以，这次是准备一些必要的目录结构、项目代码等等。

### 2.1 准备php-sdk目录

比如我本地环境，就直接将下载好的 php-sdk-binary-tools 解压到了：`d:\source\php\php-sdk` 

### 2.2 构造编译目录树

进入到上一步创建好的目录 `d:\source\php\php-sdk`  ，并运行如下命令：

```bash
# Windows下切换盘符可以 直接属于`盘符+:`，如果要进入D盘：`d:` 回车就好
> cd d:\source\php\php-sdk  
# phpdev 是文件夹名，可以根据自己喜好取，建议就别换了
> bin\phpsdk_buildtree.bat phpdev  
```

### 2.3 手动添加文件夹

由于这个版本的 php-sdk ，不支持生成新版本Visual C++目录结构，需要手动创建：

- 如果编译的是VC11，将 `d:\source\php\php-sdk\phpdev\vc9` 复制一份到 `d:\source\php\php-sdk\phpdev\vc11`
- 如果编译的是VC14，将 `d:\source\php\php-sdk\phpdev\vc9` 复制一份到 `d:\source\php\php-sdk\phpdev\vc14` ，（通过第一步收集的**编译器信息**，我这里要创建的是`vc14`这个目录）

### 2.4 准备PHP源码

通过PHP官网，下载你本地PHP版本的源码，Windows PHP源码版本可以在这里找到：https://windows.php.net/downloads/releases/archives/ ，通过第一步收集的**版本信息**得知我需要下载的是：[php-7.0.27-src.zip](https://windows.php.net/downloads/releases/archives/php-7.0.27-src.zip)

下载好后，需要将PHP源码解压到 `d:\source\php\php-sdk\phpdev\vc##\x##` ，这里的`##`根据你实际情况进行替换：

- **vc##**  表示你使用的编译器版本，比如：`vc9`, `vc11` 或者 `vc14`
- **x##** 是指你PHP的架构（Architecture）：`x86` 或者 `x64`

通过第一步收集的 **编译器**（Compiler）、**架构**（Architecture）信息可以知道，我应该将PHP源码解压到：`d:\source\php\php-sdk\phpdev\vc14\x64` 。

### 2.5 准备官方扩展源码

我们知道PHP有一些自带的扩展功能，比如：`openssl`、 `socket` 、 `gd2` 等等，虽然这些扩展每次都会随着PHP版本发布而提供对应的dll文件，但我们现在是要自己编译源码，所以也需要准备好他们。

通过PHP官网，下载你本地PHP版本的扩展源码，扩展源码可以在这里找到：https://windows.php.net/downloads/php-sdk/archives/ ，由于我本地是 `64位的PHP7.0.27`，所以我需要下载的是：deps-7.0-vc14-x64.7z

细心的你大概发现，上面的那个归档页面只提供了 7.1及以下版本的扩展源码，这其实是由于php-sdk对PHP7.2及以上版本实现方式不一样导致的。PHP7.2及以上版本编译过程中不需要自己准备扩展源码，支持在线下载，方便很多。

### 2.6 准备第三方扩展源码

编译非官方扩展才是我们的目的，所以还需要准备好第三方PHP扩展。

我这里要编译的是 `xhprof`，通过 [pecl](https://pecl.php.net/package/xhprof) 或者 [github](https://github.com/phacility/xhprof) 下载都可以，我通过pecl下载了最新版`2.2.0` （注意扩展支持的最低PHP版本）。顺便提一下，你会发现xhprof最近更新还是2015年，目前也出现了比它更好的性能分析工具。

`xhprof` 跟其他扩展有点不一样，因为它是包括web页面的，所以压缩包里面还包括一个 `xhprof_html`，实际上`extension` 这个目录下才是我们编译dll文件需要用到的代码。

![image-20200906104249433](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202009/06/104325-74557.png)

将 `extension` 文件夹解压到PHP源码同级目录 `pecl`（文件夹不存在可以手动创建），比如我这里就解压到： `d:\source\php\php-sdk\phpdev\vc14\x64\pecl\`，并将 `extension` 重命名为 `xhprof-2.2.0` 。

### 小结

通过上面6步，最终的文件结构如下：

```shell
D:\source\php\php-sdk
├─bin                       # 编译PHP需要的一些工具，比如：phpsdk_buildtree.bat
├─phpdev                    # 自己创建的PHP编译目录
│  ├─vc14
│  │  ├─x64
│  │  │  ├─deps             # 官方扩展目录，deps-7.0-vc14-x64.7z解压到这个文件夹下
│  │  │  │  ├─bin           # 官方扩展目录跟非官方目录结构不一样下面包括以下目录：
│  │  │  │  └─xxx           # bin/include/lib/share/template
│  │  │  ├─pecl             # 非官方的扩展，我这里只编译xhprof
│  │  │  │  └─xhprof-2.2.0  # xhprof扩展源代码
│  │  │  └─php-7.0.27-src   # PHP源码目录
│  │  │     ├─appveyor
│  │  │     ├─build
│  │  │     ├─.....
│  │  │     ├─win32
│  │  │     ├─x64           # 编译成功后创建的文件件，存放编译结果(64的是这个目录)
│  │  │     │  └─Release    # 编译成功后我们需要的 php_xhprof.dll 文件就在这个文件夹下
│  │  │     └─Zend
│  │  └─x86
│  ├─vc6
│  ├─vc8
│  └─vc9
├─script
└─share
```

再次提醒：本节内容仅适合编译7.2以下PHP版本的扩展，如果你需要编译的是PHP7.2及以上请查看官方文档：https://wiki.php.net/internals/windows/stepbystepbuild_sdk_2。

## 3. 编译扩展

终于进入编译阶段，这部分如果环境没啥问题那就是几个命令的事情，如果环境有问题就头大。

我自己在编译的时候就出现过：找不到头文件、库文件等等错误，总的来说只要前面的Visual Studio安装没什么问题，那基本都是系统环境变量不完整导致的，这时候你只需要将编译过程中提示找不到的头文件、库文件目录找出来加到 `INCLUDE` 、 `LIBPAHT` 这两环境变量下再重新编译基本就能过了。

更多关于编译过程中 `INCLUDE` 、 `LIBPAHT` 两个环境变量的说明可以查看这篇文章：[命令列編譯C++（Linux下、Windows下）](https://www.itread01.com/content/1547560475.html)。废话不多说，下面进入正题。

### 3.1 启动编译终端

在 **1.2小节** 中我们说过，安装完VS后开始菜单会有两个快捷方式： `VS2015 x64 Native Tools Command Prompt` 、`VS2015 x86 Native Tools Command Prompt` 。我这里是编译64位的PHP，那自然就是启动  `VS2015 x64 Native Tools Command Prompt` 。

### 3.2 设置环境变量

我们进入 php-sdk 所在目录，并设置好编译过程需要用到的一些环境变量。

```shell
# 进入 php-sdk 目录
> cd d:\source\php\php-sdk\
# 设置编译所需的环境变量
> bin\phpsdk_setvars.bat
```

### 3.3 生成 configure 文件

`configure` 文件，对于在Linux下编译安装过PHP的童鞋肯定不陌生，`make` 之前就是要先运行 `./configure xxxx` ，不过Windows下需要自己运行 `buildconf` 手动生成它。

```shell
# 进入 php 源码目录
> cd d:\source\php\php-sdk\phpdev\vc14\x64\php-7.0.27-src\
# 运行 buildconf 生成 configure
> buildconf
```

### 3.4 运行 configure

这一步相当于对编译做自定义，可以指定你要编译哪些扩展等等。

```shell
# 真正运行 configure 前，可以先看下他的帮助信息。
# 这里要编译 xhprof，不出意外查看帮助信息可以看到里面有一行是：--enable-xhprof 
> configure --help

# 运行 configure，并指定需要编译的扩展
# --disable-all 禁用所有扩展
# --disable-zts 不启用线程安全，一般线程安全模式只有PHP不是以fastcgi方式运行时启用
# --enable-cli  启用cli，好处就是编译完成后就可以执行在命令行运行php命令，查看编译结果
# --enable-xhprof=shared 表示要以共享库的方式编译xhprof，不指定shared，就不会生成我们熟悉的dll文件，请特别注意
> configure --disable-all --disable-zts --enable-cli --enable-xhprof=shared
# 以下都是 configure 输出，后面很多nmake的错误都可以结合这里的信息进行分析
Saving configure options to config.nice.bat
Checking for cl.exe ...  <in default path>
  Detected compiler MSVC14 (Visual C++ 2015)      # 编译器信息
  Detected 64-bit compiler
Checking for link.exe ...  C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\BIN\x86_amd64                             # link.exe 位置
Checking for nmake.exe ...  <in default path>
Checking for lib.exe ...  <in default path>
Checking for bison.exe ...  <in default path>
Checking for sed.exe ...  <not found>
Checking for re2c.exe ...  <in default path>
  Detected re2c version 0.13.5
Checking for zip.exe ...  <in default path>
Checking for lemon.exe ...  <not found>
Checking for mc.exe ...  C:\Program Files (x86)\Windows Kits\10\bin\x86
Checking for mt.exe ...  C:\Program Files (x86)\Windows Kits\10\bin\x86
Enabling multi process build
# 待目录
Build dir: D:\source\php\php-sdk\phpdev\vc14\x64\php-7.0.27-src\x64\Release
PHP Core:  php7.dll and php7.lib

Checking for wspiapi.h ...  <in default path>
Enabling IPv6 support
Enabling SAPI sapi\cli
Enabling extension ext\date
Enabling extension ext\pcre
Enabling extension ext\reflection
Enabling extension ext\spl
Checking for timelib_config.h ...  ext/date/lib
Enabling extension ext\standard
Enabling extension ..\pecl\xhprof-2.2.0 [shared]
AC_DEFINE[HAVE_PCRE]=1: is already defined to 1

Creating build dirs...
Generating files...
Generating Makefile
Generating main/internal_functions.c
        [content unchanged; skipping]
Generating main/config.w32.h
Generating phpize
Done.

Enabled extensions:
-----------------------
| Extension  | Mode   |
-----------------------
| date       | static |
| pcre       | static |
| reflection | static |
| spl        | static |
| standard   | static |
| xhprof     | shared |     # mode=shared，这种方式才会生成 php_xhprof.dll 文件
-----------------------

Enabled SAPI:
-------------
| Sapi Name |
-------------
| cli       |
-------------

----------------------------------------------
|                 |                          |
----------------------------------------------
| Build type      | Release                  |
| Thread Safety   | No                       |
| Compiler        | MSVC14 (Visual C++ 2015) |
| Architecture    | x64                      |
| Optimization    | PGO disabled             |
| Static analyzer | disabled                 |
----------------------------------------------

Type 'nmake' to build PHP
```

### 3.5 编译

```shell
# 没啥好说，经过上面那么多的准备 终于进入最关键的一步
# 不出意外 你将看到：SAPI sapi\cli build complete
# 同时在这一行输出的上面会告诉你这次编译的输出文件在哪，其实就两处：Release_TS / Release
> nmake
```

![编译成功](https://raw.githubusercontent.com/Thobian/typora-image/master/demo/202009/07/210652-149755.png)

我这里是编译非线程安全版本，所以在编译结果在 `Release` 文件夹下，同时在这个目录下会看到 `php_xhprof.dll` 文件，就是我需要的扩展文件，把丢回本地PHP扩展目录配置下就可以愉快的运行起来了。

## 总结

最终通过xhprof得出本地PHP运行慢主要还是：网络请求耗时长，代码本身、磁盘并不是影响运行的主要原因，再结合自己观察浏览器的表现终于解决了本地PHP运行慢的问题。

为了解决运行慢的问题，编译xhprof前后大概花了好几天时间，再加上后续的观察分析，整个过程跨度2周，但还是很值得的，过程中接触了不少新的东西算是很有收获。