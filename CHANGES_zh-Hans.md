## 变更日志

### [0.6.2] - 2019-09-10
### 变量
- Android 端移除 preoreo 目标
- Android 端添加 android.permission.FOREGROUND_SERVICE 权限

### [0.6.1] - 2019-08-29
### 变更
- 移除过时的 isLocationEnabled 方法
- Android 端用 react-native headless js 替换 jsevaluator

### [0.6.0] - 2019-08-27
### 修复
- 修复 Android 端提供者(provider)冲突 (fixes #344)

### 变更
- 支持 RN 0.60 的自动链接(autolinking)

### [0.5.6] - 2019-08-27
### 修复
- Android API >= 26 允许从后台开启服务 (fixes #356)

### [0.5.5] - 2019-08-13
### 修复
- Android 修复 ToneGenerator 闪退问题
- Android 从 manifest 里删除 minSdk (fixes #357) - @maleriepace
- Android 为 applicationId 添加选项检查 (PR #36 common repo) - @mysport12
- Android 不会在 manifest 里声明 minSdk 版本了 @wesleycoder 和 @maleriepace
- Android 改变 react-native link command 仓库地址 (PR #374) - @mantaroh
- 更新 CHANGES_zh-Hans.md 翻译文档 - @Kennytian
- 修正 README 里的错别字 - @diegogurpegui
- 感谢所有的贡献者

### [0.5.2] - 2019-03-28
### 修复
- Android 修复程序无法启动 APP VisibilityChange 事件缺陷
- Android 忽略失败的 instrumentation 测试项

### [0.5.1] - 2019-03-25
### 修复
- Android 修复 #360 - 当应用因其他原因崩溃时，系统会启动该服务

### [0.5.0] - 2019-01-31

### 新增
- 用 startMonitoringSignificantLocationChanges 实现 iOS config.stopOnTerminate 功能

Commit: [5149178c65322d04f4e9e47bd278b17cf0e4bd9a](https://github.com/mauron85/background-geolocation-ios/commit/5149178c65322d04f4e9e47bd278b17cf0e4bd9a)
Origin-PR: [#7](https://github.com/mauron85/background-geolocation-ios/pull/7)
Contributed-By: [@StanislavMayorov](https://github.com/StanislavMayorov)

### 修复
- Android - 无法找到 Assert.assertNotNull 标识

Commit: [ec334ba6a8612c399d608bbfc4aacfad68fc2105](https://github.com/mauron85/background-geolocation-android/commit/ec334ba6a8612c399d608bbfc4aacfad68fc2105)
Origin-PR: [#25](https://github.com/mauron85/background-geolocation-android/pull/25)
Origin-Issue: [#340](https://github.com/mauron85/react-native-background-geolocation/issues/340)
Contributed-By: [@scurtoni](https://github.com/scurtoni)

### [0.5.0-alpha.XY] - 未发布

此版本提供了抽象代码以复用 React Native Cordova 插件之间变量，从而加快开发速度修复共享代码库的错误。

### 新增
- 通过 `postTemplate` 配置属性来提交/同步
- iOS ACTIVITY_PROVIDER（实验性）
- 允许部分插件复用配置
- 在 'activity' 上改变事件
- Android 使用 gradle 选择权限 由 @jsdario（PR＃136）
- iOS 配置持久化

从 alpha.8 开始：
- Android 自动 link react-native 配置
- iOS checkStatus 返回位置服务的状态（locationServicesEnabled）
- iOS RAW_LOCATION_PROVIDER 持续在应用终止时运行

从 alpha.10 开始：
- Android checkStatus 返回位置服务的状态（locationServicesEnabled）

从 alpha.15 开始：
- Android 位置参数 isFromMockProvider，mockLocationsEnabled，radius，provider
- Android 无头任务

自 alpha.16 开始：
- iOS 在 postlink 上添加后台模式和权限
- 添加跨平台预发布脚本执行 由 @dobrynia 提供（PR＃165）

从 alpha.17 开始：
- Android 允许使用 ext 声明覆盖库的版本

自alpha.19 开始：
- Android Oreo 实验支持

自 alpha.20 开始：
- 按日期级别获取日志并按日志级别过滤的选项
- 记录未捕获的异常

从 alpha.22 开始：
- 方法 forceSync

从 alpha.26 开始：
- Android 添加 httpHeaders 验证

从 alpha.28 开始：
- 实现 getCurrentLocation
- iOS 实现 getStationaryLocation

从 alpha.31 开始：
- Android Gradle 3 支持（实验性）

从 alpha.37 开始：
- 在原生代码中转换/过滤位置（由[@danielgindi](https://github.com/danielgindi/)）
更多信息：https://github.com/mauron85/background-geolocation-android/pull/8

从 alpha.40 开始：
- notificationsEnabled 配置选项（由[@danielgindi](https://github.com/danielgindi/)）
更多信息：https://github.com/mauron85/react-native-background-geolocation/pull/269
-允许在停止状态「285 Updates Not Required」更新位置（由[@danielgindi](https://github.com/danielgindi/)）
更多信息：https://github.com/mauron85/react-native-background-geolocation/pull/271

### 变更

从 alpha.6 开始：
- iOS saveBatteryOnBackground 默认为 false

从 alpha.8 开始：
- 与 Cordova 共享代码库

从 alpha.11 开始：
- Android 从 applicationId 派生同步权限和提供者
- Android 删除 android.permission.GET_ACCOUNTS

自 alpha.19 开始：
- 在 settings.gradle 中的 Android postlink 注册项目，而不是文件复制（**重大变更** - 阅读 android-setup 部分）

自 alpha.20 开始：
- iOS使用Android日志格式（**重大变更**）

自 alpha.22 开始：
- 满足条件时 Android 删除同步延迟
- Android 认为 HTTP 201 是成功的请求
- Android 服从系统同步设置

从 alpha.26 开始：
- Android 仅在后台显示服务通知
- Android 删除配置选项 startForeground（与上面相关）
- Android 从两个 Android 提供商处删除唤醒锁（由 @grassick 提供）
- Android 仅对 postTemplate 字符串值删除限制

从 alpha.28 开始：
- Android 带回了 startForeground 配置选项（**重大变更**！）

startForeground 的含义略有不同。

如果为 false（默认），则服务将创建通知并进行提升
当客户端从服务解除绑定时，它本身就是前台服务。
这通常发生在应用程序移至后台时。
如果应用程序正在移回前台（对用户可见）
服务会销毁通知并停止前台服务。

如果真正的服务将创建通知并始终保持在前台。

从 alpha.30 开始：
- Android 内部更改（权限处理）
- Android gradle 构建更改

从 alpha.38 开始：
- Android 禁用 Oreo 的通知声音和振动
（PR：[＃9](https://github.com/mauron85/background-geolocation-android/pull/9)
由 [@danielgindi](https://github.com/danielgindi/)，关闭＃260）

### 修复

从 alpha.4 开始：
- @asafron 可在 iOS 10 及更高版本（PR＃158）上的打开 iOS 位置设置

从 alpha.8 开始：
- checkStatus 授权
- 修复 Android 找不到符号的编译错误

自 alpha.9 开始：
- Android 修复 ＃118 - NullPointerException LocationService.onTaskRemoved
- Android 权限 - 在运行时检查和请求权限

从 alpha.13 开始：
- Android 修复 allowBackup 属性冲突

从alpha.14开始：
- Android 修复＃166 - 错误：含有  'com.google.android.gms.license' 多个库

从 alpha.15 开始：
- Android 仅传递有效的位置参数
- 停止时 iOS 重置连接状态
- iOS 修复 App Store 拒绝问题 - Prefs 非公共 URL Scheme

从 alpha.17 开始：
- Android 修复服务意外用默认配置或存储配置启动

从 alpha.21 开始：
- Android 在 postunlink 上卸载 Android 的常用模块
- Android 防止注册多个 common 项目
- Android 修复一些空指针异常 92649c70e0ce0072464f47f1d096bef40047b8a6
- iOS 只更新了 info.plist

从 alpha.22 开始：
- Android 为防止一些逆向工程添加混淆
- Android 处理配置为 null 的情况

从 alpha.25 开始：
- Android 问题 ＃185 - 处理无效配置

从 alpha.27 开始：
- iOS 修复强制同步参数
- 修复 #183 - 添加 'activity' 事件侦听器时出错

从 alpha.28 开始：
- iOS 在 iOS >= 10 的前台显示调试通知
- iOS 修复错误消息格式
- iOS 行动提供者静止不动(原文iOS activity provider stationary event)

从 alpha.35 开始：
- Android getCurrentLocation 在后台线程上运行 (PR #219 by [@djereg](https://github.com/djereg/))
- iOS 修复删除所有位置时崩溃的问题 ([7392e39](https://github.com/mauron85/background-geolocation-ios/commit/7392e391c3de3ff0d6f5ef2ef19c34aba612bf9b) by [@acerbetti](https://github.com/acerbetti/))

从 alpha.36 开始：
- Android Defer 启动并配置，直到服务准备就绪
(PR: [#7](https://github.com/mauron85/background-geolocation-android/pull/7)
Commit: [00e1314](https://github.com/mauron85/background-geolocation-android/commit/00e131478ad4e37576eb85581bb663b65302a4e0) by [@danielgindi](https://github.com/danielgindi/),
修复 #201, #181, #172)

从 alpha.38 开始：
- iOS 避免控制 UNUserNotificationCenter
(PR: [#268](https://github.com/mauron85/react-native-background-geolocation/pull/268)
by [@danielgindi](https://github.com/danielgindi/),
修复 #206, #256)

### [0.4.1] - 2017-12-19
#### 变更
- react native 版本必须大于 0.49.0

### [0.4.0] - 2017-12-13
发布 0.4.0

### [0.4.0-rc.3] - 2017-11-23
### 新增
- iOS 在后台同步时发送 http headers

### [0.4.0-rc.2] - 2017-11-13

### 修复
- Android ConfigMapper mapToConfig 缺少配置属性（修复＃122）

### 新增
- Android 为 getLocations 方法返回 location id

### [0.4.0-rc.1] - 2017-11-10

### 修复
- 修复 iOS 在配置之前调用 getConfig 方法

#### 新增
- checkStatus 判断服务是否正在运行
- 事件 [start, stop, authorization, background, foreground]
- 实现两个平台的所有方法
- RAW_LOCATION_PROVIDER 模式

#### 变更
- start 和 stop 方法不接受回调（改为使用事件监听器）
- syncUrl 为后台同步的必填项
- Android 上的 DISTANCE_FILTER_PROVIDER 现在接受任意值（之前只能 10, 100, 1000 之前选择）
- 所有插件常量都直接在 BackgroundGeolocation 命名空间中。（查看 index.js）
- 可以在不执行 configure 的情况下启动插件（使用存储的设置或默认值）
- location 属性 locationId 重命名为 id
- iOS pauseLocationUpdates 现在默认为 false（因为 iOS 文档现在声明如果将其设置为true，则需要手动重启）
- iOS finish 方法替换为 startTask 和 endTask

### [0.3.3] - 2017-11-01
#### 修复
- 状态码是 201 时 Android 也应该同步位置 (PR #71)

### [0.3.2] - 2017-11-01
#### 修复
- 为 iOS 实现 isLocationEnabled 属性(PR #92)

### [0.3.1] - 2017-10-04
#### 修复
- (tpisto) React Native 0.48.x 中的 iOS 编译错误（修复＃108）

### [0.3.0-alpha.1] - 2017-08-15
#### 修复
- 兼容 iOS RN 0.47 版 (修复 #95)

### [0.2.0-alpha.7] - 2017-03-21
#### 修复
- 修复 iOS 问题 #44

### [0.2.0-alpha.6] - 2017-02-18
#### 修复
- 兼容 iOS RN 0.40 版

### [0.2.0-alpha.5] - 2016-09-15
#### 修复
- 修复 Android 问题 #10

### [0.2.0-alpha.4] - 2016-09-10
#### 修复
- 修复了 Android 在未配置插件时销毁的崩溃问题

### [0.2.0-alpha.3] - 2016-09-07
#### 修复
- 修复 Android 问题 #10 - 刷新时崩溃

#### 新增
- Android onStationary 方法
- Android getLogEntries 方法

#### 删除
- Android 位置过滤

#### 变更
- Android 项目目录结构
(请阅读更新安装说明)
- 用 Android 数据库代替文件来记录日志

### [0.2.0-alpha.2] - 2016-08-31
#### 修复
- 修复 config 参数无法保持的问题
- 临时修复 Android 时间长到 int 型转换

#### 新增
- Android isLocationEnabled 属性
- Android showAppSettings 方法
- Android showLocationSettings 方法
- Android getLocations 方法
- Android getConfig 方法

### [0.2.0-alpha.1] - 2016-08-17
#### 变更
- 为适配 cordova 2.2.0-alpha.6 升级插件

### [0.1.1] - 2016-06-08
#### 修复
- 修复 iOS 停止时崩溃问题

### [0.1.0] - 2016-06-07
#### 新增
- 初始 iOS 实现

### [0.0.1] - 2016-06-04
- 初始 Android 实现
