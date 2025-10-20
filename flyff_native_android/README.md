# Flyff Native Android

基于原生Android开发的Flyff游戏启动器，提供多标签页浏览器和自动点击功能。

## 功能特性

### 🌐 多标签页浏览器
- 支持多个标签页同时浏览
- 自动加载Flyff Universe游戏页面
- 标签页标题自动更新
- 支持标签页关闭和刷新
- 横屏模式优化

### 🎯 自动点击功能
- 基于Android无障碍服务实现
- 支持记录和保存点击点
- 支持自动点击序列
- 可配置点击间隔
- 支持单次点击和循环点击

### 📱 用户界面
- Material Design 3设计风格
- 响应式布局适配
- 直观的操作界面
- 悬浮按钮快速操作

## 技术架构

### 核心组件
- **MainActivity**: 主界面Activity，管理标签页和UI交互
- **BrowserViewModel**: 标签页状态管理
- **TabPagerAdapter**: ViewPager2适配器，管理WebView片段
- **WebViewFragment**: WebView容器片段
- **AutoClickAccessibilityService**: 无障碍服务，实现自动点击
- **ClickPointManager**: 点击点管理器，处理点击点存储和执行

### 技术栈
- **语言**: Kotlin
- **UI框架**: Android View System + Material Design 3
- **架构模式**: MVVM (Model-View-ViewModel)
- **异步处理**: Kotlin Coroutines
- **数据存储**: SharedPreferences + JSON
- **WebView**: Android WebView with JavaScript支持

## 安装要求

- Android 7.0 (API 24) 或更高版本
- 支持无障碍服务的设备
- 网络连接

## 使用说明

### 1. 基本浏览
1. 启动应用后会自动创建第一个标签页
2. 点击右下角的"+"按钮添加新标签页
3. 使用顶部标签栏切换不同标签页
4. 使用工具栏的刷新和关闭按钮管理标签页

### 2. 自动点击设置
1. 点击绿色的自动点击按钮
2. 根据提示开启无障碍服务权限
3. 在设置中找到"Flyff自动点击服务"并开启
4. 返回应用即可使用自动点击功能

### 3. 权限说明
- **网络权限**: 用于加载网页内容
- **无障碍服务权限**: 用于实现自动点击功能

## 项目结构

```
app/src/main/
├── java/com/c12dd/flyff_native/
│   ├── MainActivity.kt                 # 主Activity
│   ├── model/
│   │   └── BrowserTab.kt              # 标签页数据模型
│   ├── viewmodel/
│   │   └── BrowserViewModel.kt        # 标签页状态管理
│   ├── adapter/
│   │   └── TabPagerAdapter.kt         # ViewPager适配器
│   ├── fragment/
│   │   └── WebViewFragment.kt         # WebView片段
│   ├── accessibility/
│   │   └── AutoClickAccessibilityService.kt  # 无障碍服务
│   └── manager/
│       └── ClickPointManager.kt       # 点击点管理
├── res/
│   ├── layout/                        # 布局文件
│   ├── drawable/                      # 图标资源
│   ├── values/                        # 字符串、颜色、主题
│   ├── menu/                          # 菜单资源
│   └── xml/                           # 配置文件
└── AndroidManifest.xml                # 应用清单
```

## 开发环境

- Android Studio Hedgehog | 2023.1.1 或更高版本
- Kotlin 1.9.0
- Gradle 8.2.0
- compileSdk 34
- minSdk 24
- targetSdk 34

## 构建说明

1. 克隆项目到本地
2. 使用Android Studio打开项目
3. 等待Gradle同步完成
4. 连接Android设备或启动模拟器
5. 点击运行按钮构建并安装应用

## 注意事项

1. **无障碍服务权限**: 自动点击功能需要用户手动在系统设置中开启无障碍服务权限
2. **横屏模式**: 应用强制横屏显示，适配游戏场景
3. **WebView性能**: 针对多标签页场景进行了WebView性能优化
4. **数据持久化**: 点击点数据会自动保存到本地存储

## 许可证

本项目仅供学习和研究使用。