# RibbonBuild

`RibbonBuild`是一个使用cmake和kconfig实现的轻量级的Linux应用编译框架。

## 背景
C/C++的工程化开发过程中，重复造轮子的现象很普遍。一个重要原因是编译体系缺失，无法快速移植已有代码，导致工程师往往选择重新造轮子。

缺少模块化的缺点：
- 代码的可维护性和可移植性较差。
- 新造轮子代码缺少验证，代码质量难以保证。
- 重复造轮子，造成人力资源浪费。

**目标**
1. `RibbonBuild`将cmake的编译进行抽象和简化，通过组件的概念，快速实现代码的组合编译。
2. 通过kconfig和cmake结合，使组件具有可配置性，提高模块的可扩展性、可复用性。

## 重要概念
1. 组件
   - 组件为同一逻辑代码的集合。
   - 组件包含头文件目录include、源码目录src、CMakeLists.txt和Kconfig文件等。
   - CMakeLists.txt中的配置要素包括头文件目录、源码目录、依赖库、编译链接配置等。
   - 组件可区分为应用组件和库组件。
2. 工程
   - 工程是实现特定功能的应用集合。
   - 工程目录是组件的上级目录，存放CMakeLists.txt入口，编译生成的build目录、config目录、install目录等

## 快速上手
1. 下载源码：
    ```
    git clone https://github.com/RibbonDFTeam/RibbonBuild.git
    ```
2. 工程编译：
    ```
    cd demo
    mkdir build
    cd build
    cmake ..
    make install
    ```
    即可完成编译

## 工程移植
   - 拷贝demo工程中的CMakeLists.txt到自己的工程路径中。
   - 修改CMakeLists.txt中的`RibbonBuildPath`和`RibbonComponentsPath`变量。`RibbonBuildPath`指向`RibbonBuild`的路径，`RibbonComponentsPath`指向希望存放组件目录路径，可以是多个。
   ### 组件适配：
   - 复制demo_app中的CMakeLists.txt、Kconfig到组件目录，组件目录名即为组件名。
   - 修改Kconfig中配置项MODULE_${UPPER_CASE_COMPONENT_NAME}_ENABLE，也可增加其他配置
   - 修改CMakeLists.txt中配置项，包括头文件目录、源码目录、依赖库、编译链接配置等。

## 成果物说明
    - build目录：编译生成的目录，包含编译生成的目标文件、库文件等。
    - config目录：存放组件的Kconfig配置项，可通过修改Kconfig文件重新生成配置。
    - install目录：编译生成的库文件、头文件等安装目录。