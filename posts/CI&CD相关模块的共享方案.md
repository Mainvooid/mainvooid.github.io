# CI&CD相关模块的共享方案
[toc]
<!--toc-->
#### 需求：
满足不同成员与不同项目对公共配置/构建文件等的代码复用


#### 情景1
**统一各类配置库管理**

情景：
1. 用于不同项目的build.py的公共逻辑/函数方法,及一系列用于构建的其他python辅助方法
2. 用于*.cmake的公共函数function macro
3. 未来兼容其他配置，统一管理的扩展性

- 作为构建代码也需要版本管理
- 为便于管理应该组织在一个库中
- 此库包含一般通用方法，也包含项目内部可能特有的公共方法
- 这些公共辅助方法应该能较方便按文件/目录拉取到项目目录下
- 为了避免对依赖方的影响，接口/函数命名同样需要前向兼容保持稳定

此情景下有以下方式：

1. 基于git的sparse clone
    在项目中配置此库需要拉取的文件，本地使用，而不加入项目的版本管理.
    实现方案：
    - 初始化
    ```bash
    # 创建用于本地仓库的文件夹
    mkdir localdir
    # 进入文件夹
    cd localdir
    # 在本地指定文件夹内执行此命令设置为git仓库
    git init
    ```
    - 拉取remote all objects信息
    ```bash
    # 添加远程仓库地址，实现拉取remote的all objects信息
    git remote add -f origin https://.../<project_name>.git
    ```
    - 开启sparse clone
    ```bash
    # 用于控制是否允许设置pull指定文件/夹，适用于Git1.7.0以后版本，本质是开启sparse
    git config core.sparsecheckout true

    # 本地目录的.git文件夹下，如果没有sparse-checkout文件则创建，在其中添加指定的文件/夹fileName，就是需要拉取的那个特定文件/夹。*表示所有，！表示匹配相反
    echo "build.py" >> .git/info/sparse-checkout
    # 查看
    cat .git/info/sparse-chechout
    ```
    - 拉取指定目录/文件
    ```bash
    # 拉取命令是一样的，只是已经通过配置文件sparse-chechout指定了目标文件/夹
    git pull origin master
    ```
    这样就只拉取了"build.py"下来,这样拉取下来会保留有原来的目录结构.

    优点：
    可以支持仅拉取需要的文件/目录
    缺点：
    每个项目都得本地配置一遍上述流程

2.通过git的submodule

优点：
- 直接的子模块依赖，子模块的版本控制与当前项目是分离的
- 与项目直接依赖，在git初始化时自动拉取该依赖
- 子模块更新时拉取更新也很方便

缺点：
- 会拉取子项目所有文件

#### 情景2
仅python情景,通过Python脚本控制全流程配置

- 希望依赖的时候基于package版本，而不是源码（事实上保证接口前向兼容，完全可以基于最新源码）

- 通过pypi
    ```python
    源代码仓库结构：
    /src
    README.md
    requirement.txt
    setup.py

    其中setup.py:
    from setuptools import find_packages, setup
    setup(
        name='build_utils',
        version='1.0.0',
        description='utils for build',
        author='xxx',
        author_email='XXX@xxx',
        url='https://github.com/build_utils/',
        #packages=find_packages(),
        packages=['src'],
        #install_requires=['requests'],
    )
    ```
    自定义pypi源
    用户目录`$HOME/.pypirc` 下添加 :
    ```
    [distutils]
    index-servers = <pypi_name>
    [<pypi_name>]
    repository: <pypi_url/script>
    username: <user_name>
    password: <password>
    ```

    MacOS / Linux
    在 `$HOME/.pip/pip.conf` 文件添加以下配置。
    ```
    [global]
    index-url = https://<pypi_url>/script/simple
    ```
    ```bash
    #推送
    twine upload -r <pypi_name> dist/*
    #拉取
    pip3 install <package_name> -i <pypi_name>
    ```
- pypi.org源
    ```
    [distutils]
    index-servers=pypi

    [pypi]
    repository = https://upload.pypi.org/legacy/
    username: 注册的pypi账号
    password: 注册的pypi密码
    ```

    上传仓库到github上
    执行
    ```python
    python setup.py sdist
    #setup.py 同级目录生成一个dist文件夹,里面是 sdk1.0.tar.gz
    ```

    解压安装:
    ```python
    python setup.py install
    # 注:使用 setup.py没有卸载功能,如果需要卸载则要手动删除
    # 也可使用: -- record 记录安装文件的目录
    python setup.py install --record file.txt
    # 卸载时可以使用脚本去实现自动安装和卸载
    ```
    ```bash
    #推送
    twine upload dist/*

    #拉取
    pip3 install <package_name>
    ```
