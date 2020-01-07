# 路由——路由配置

lumen中的路由是通过 `bootstrap/app.php` 中注册的路由配置来定义的，默认注册配置如下：

```php
// 通过这个配置可以知道两点：
// 1. 后续的 Controller 应该在 App\Http\Controllers 这个命名空间下寻找
// 2. 路由配置文件在：routes/web.php
$app->group(['namespace' => 'App\Http\Controllers'], function ($app) {
    require __DIR__.'/../routes/web.php';
});
```

进入 `routes/web.php` 文件，就是项目的所有路由配置了，路由大概可以分两大类：**简单路由**、**分组路由**

**简单路由**是指通过：`get/post/put/patch/delete/options` 中的方法来注册的路由；

**分组路由**是指通过：`group` 方法来注册的路由，比如 `bootstrap/app.php` 中的注册方式；

下面通过一些例子来解析下lumen的路由使用。

#### 简单路由

```php
// 不同lumen版本会有差异，下面都是已 5.3 做的演示
// get方法的原型：RoutesRequests::get(string $uri, mixed $action)
// 
// $uri 就是你设置的路由地址，支持带参数
// $action 接受 string、array、Closure 3种类型的参数，当为array时结构是：
// [
// 		'as'=>string,  //别名
//		'middleware'=>middlewareClass,  //路由中间件
//  	'uses'=> 'Controller@method', //controller类方法，结合group方法中设置的namespace生成
//		Closure, //匿名函数，如果跟uses同时存在匿名函数将不生效
// ]

// 【Closure】方式
// 直接执行匿名函数并将函数的返回值作为最终的输出结果
$app->get('/', function () use ($app) {
    return $app->version();
});

// 【string】方式，
// 将找到字符串对应的 controller 以及 里面定义的方法
// controller默认在 \App\Http\Controllers 目录下，具体位置是根据 bootstrap/app.php 配置来的
// {name} 相当于链接参数，如：http://www.lumen.com/user/thobian ，那 UserController::index($request, $name) 中，第二个 $name 参数的取值就是：thobian
// 注意 {name}，必须跟 方法中的参数变量名一致
$app->get('/user/{name}', 'UserController@index'); 

// 【array】方式
$app->get('/user/{name}', [
    'as'=>'userProfile',          //链接别名，后续可以通过它快速生成url链接
    'middleware'=>'middleware',   //路由中间件，这里是先通过 $app->routeMiddleware() 注册了路由中间件别名，如果没提前注册需要写完整的中间件类地址，可以同时使用多个中间件用 | 分隔(或者用数组方式)
    'uses'=>'UserController@index'//同【string】方式，当存在uses时 回调函数就不生效
]);
// as的使用：`route('userProfile', ['name'=>'thobian'])` 将返回：http://www.lumen.com/user/thobian
```

#### 分组路由

分组路由里面包含的是一堆 **简单路由**，所以主要说下分组的语法。

```php
// group方法的原型：RoutesRequests::group(array $attributes, Closure $callback)
// 
// $attributes 结构是：
// [
// 		'middleware'=>string,  //group下所有路由都将运用这些中间件，格式同简单路由中说明
//		'namespace'=>'App\Http\Controllers',  //命名空间，跟简单路由中的uses组成最终的controller地址
//  	'prefix'=> 'prefix', //路由前缀
//  	'as'=> 'alias', //路由别名，必须跟简单路由的别名一起使用才有效
//  	'suffix'=> 'suffix', //路由后缀
// ]

// 按照这个配置路由，访问 http://www.lumen.com/head/user/thobian-tail，将看到访问链接
$app->group([
    'prefix' => 'head', // 前缀会跟url直接自动加上 / 
    'as'     => 'test', 
    'suffix' => '-tail',// 后缀是不经处理直接和url拼接起来的
], function ($app) {
    $app->get('/user/{name}', ['as' => 'user', function () {
        echo route('test.user', ['name' => 'thobian']);
    }]);
});
```



#### 参考

【1】[lumen路由源码解析](https://bex.meishakeji.com/2019/04/22/lumen路由源码解析/)