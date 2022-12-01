# C++编码规范(实用增强细节版)
[toc]
<!-- toc -->

基于google开源项目风格指南的实用增强细节版

包含C++风格建议：**使用基于小写下划线的蛇形风格**

#### 背景
- C++非常强大灵活并且包含大量高级特性, 但这种强大不可避免的导致它走向复杂, 使代码更容易产生 bug, 难以阅读和维护.

- 本规范通过限制甚至禁止使用某些特性. 保持代码清爽及良好的代码习惯,来避免这些特性可能导致的各种问题来驾驭其复杂性. 这些规则在保证代码易于管理的同时, 也能高效使用 C++ 的语言特性.

- 规范包含**通用性习惯**, **编程注意事项**, **编程模式倾向**以及**代码风格**(文本格式化、可读性)

- 使代码易于管理的方法之一是**加强代码一致性**. 创建通用, 必需的习惯用语和模式可以使代码更容易理解.

#### 现象
- Google的C++开源规范问题很多, 没法拿来就用, 需要精简取其精华, 并且切合项目实际, 使得规范简单容易遵循.

- 从代码风格来讲, google表观的代码风格是一种紧凑型风格, 原则**保证必要格式化下, 一页尽可能显示更多的内容**, 但是会牺牲一定的可读性.

- Google规范内容很多, 主要面向开源, 有些规则有点过时了, 并且有自身的路径依赖, 没有考虑到编译器与编辑器的作用, 所以这个规范在google本身的项目的覆盖率都不高, 比如tensorflow大概60%的样子, gtest大概70% `e.g.:tensorflow/graph.h   googletest/gtest.cc` , 这引申出来一个规范制定要点, **规范及代码风格要求应该简单好执行**

- C++标准特性近年有向类python风格发展的趋势, 比如auto,结构化绑定及解包, 列表初始化, foreach等等, 本质上是向简化及高效化发展的, 但是google规范中有些限制就有点因噎废食了, 比如限制重载运算符, 比如一方面限制流的使用然后另外一方面增加复杂的保证64位下的可移植性的规则, 实际上没有意义. **不要因噎废食, 或者多此一举**

- google规范有些规则限制不当, 比如大部分教科书推荐使用无符号类型表示非负数.但是它不建议使用无符号类型, 理由是有的人会很愚蠢地写出下面的代码：
    ```cpp
    // 此循环永远不会退出
    for (unsigned int i = foo.Length()-1; i >= 0; --i) ...
    ```
    实际上, 这种行为是在**试图兼容不正确的用法, 是没有必要也没有意义的**, 无符号的正确用法如下,
    ```cpp
    // 正确用法
    for (unsigned int i = foo.Length()-1; i != 0; --i) ...
    ```

- 没有更完整考虑编译器行为
    - 一个事实是, 同样的代码java生成的程序比原生C生成的程序要快. 因为java编译为字节码的过程中默认是开启优化的, 如果C程序不开优化实际上效率还不如java, 所以**所有release版本的C程序都需要开O3优化**(自动内联).

    - 我们知道只有当函数小于 10 行才适合将其定义为内联函数, 如果有考虑编译器行为, 实际上完全不需要人为考虑给编译器建议内联, 完全交给编译器就完事了, 而且有的时候你即使声明为内联的也不一定会被编译器内联. 关于内联有2个点, 类内都是隐式内联的, inline声明非成员函数. 内联可以解决重定义的问题, 编译器在链接的时候会将他们链接到第一个找到的定义上.

    - 规范中认为启用异常会增加二进制文件数据, 延长编译时间, 但是在现代编译器下, 开优化后这种影响已经非常小了. 对使用 C++ 异常处理应具有怎样的态度？按需正常使用即可.

- 没有考虑编辑器行为
    - 比如google规范中成员变量后置下划线, 实际上应该前置下划线, 理由有2点：
        1. 统一语义：成员变量与私有函数全部前置下划线, 下划线一般代表私有/成员的意思和python的习惯也能统一

        2. 智能感知：编辑器中输入_, 大部分编辑器都有智能感知, 可以立马列出所有私有成员, 会很方便.

    - google的紧凑型规范没有一个好的机制去格式化, 全手动控制, 特别容易失控且浪费精力. 我原先也比较喜欢紧凑型风格, 但是vscode的默认格式化行为是教材上的C++标准风格, CTRL+SHIFT+I就完事了, 所以google定义了大量缩进哪哪空格哪哪括号的规则直接没有实现的意义. 而且缩进规则在紧凑型风格指导下也很另类, 大部分编辑器包括飞书的都是默认缩进4空格的,但是它的缩进是1, 2, 4混搭. [*不方便使用的东西没有市场*]
        ```cpp
        public cls{
        public:        // 缩进1空格
            cls()        // 缺省缩进2空格
                :a_(0){} // 形参等缩进4空格
            void func(){};
        private:
            int a_ = 0;
        }

        public cls{
        public:
            cls():a(0){}// 缺省缩进4空格
            void func(){};
        private:
            int a = 0;
        }
        ```

-  **代码风格一致性很难控制**, 因为只要引入了不同体系的第三方库就会受影响, 比如返回值体系依赖了使用异常的库比如opencv, 那么至少就需要对依赖库的异常进行处理转换. 所以一致性一般都会打折扣, 比如tf中很多文件已经是驼峰式下划线式大小写混杂的了, 从命名规范来说已经失去了控制, 但其实对可读性的影响也不是特别大.

#### 观点
1. **规范迁移**, 代码规范应该吸取google规范的精华, 同时结合自身情况补充项目内部的规范要求.

2. **所有的规范都有例外**,除了特殊情况, 很少完全强制或者百分百禁用.

3. **代码一致性包含全局一致性与局部一致性**, 风格指南的重点在于提供一个通用的编程规范, 这样大家可以把精力集中在实现内容而不是表现形式上. 我们展示的是一个总体的风格规范, 但局部风格也很重要, 如果你在一个文件中新加的代码和原有代码风格相去甚远, 这就破坏了文件本身的整体美观, 也打乱读者在阅读代码时的节奏, 所以要尽量避免.

4. **规范需要靠自觉遵循**, 因为没有实现标准化质量控制机制, 简单的规则可以让大家容易遵循但实践中可能会难以控制.

5. **一致性要求需要进行体系控制**, 一旦使用了某一个体系就不方便再引入另外一个体系, 但是实践上, 大部分时候会混用在一起, 变成主要地位与次要地位的局面：原生指针与智能指针, 异常体系与返回值体系, 引用体系与移动体系, 模板与非模板体系.

6. 相较于紧凑型规范, 本规范倾向为简单且易于实施的标准型规范.

#### 规范
<!--TODO:进一步抽象结构化-->
1. **最重要的**：
    - **代码尽可能使用简单的特性, 避免复杂的特性及操作**.
    - **尽可能一目了然, 段落分明**.
    - **尽可能采用标准库及通用化实施方式**.
    - **尽可能引入编译器检查及自动内存管理**.
    - **模式语义尽可能统一, 避免歧义**.
    - **尽可能进行文档化注释**.

2. **尽可能编写简短, 凝练的函数**. 无论是否是脚本语言, 代码应尽可能进行函数式编程, 有利于代码解耦复用.

3. 代码风格 **同一文件内应该保持统一风格**, 新项目采用新规范, 旧项目保持旧风格.

4. 本规范主次关系应该为(前主后次)：**智能指针**>原生指针, **异常体系**>返回值体系, **引用体系**>移动体系, **非模板体系**>模板体系.
    - 尽可能以智能指针为主, 但智能指针不能完全代替原生指针,只能作为自动内存管理的补充
    - 异常体系是缺省的更好的选择
    - 引用体系较为简单, 移动体系及移动操作注意事项更多
    - 非模板体系可读性可维护性更友好,除非是开源项目

5. `#define`保护 (C++20模块还未普及之前)
    -  **所有头文件都应该使用 #define 来防止头文件被多重包含**
    -  为保证唯一性, 头文件的命名应该基于所在项目源代码树的全路径/命名空间中的全路径
    -  `#pragma once`是依赖MSVC编译器的, 不必使用

6. 从保持良好开发习惯的角度, 应该**进行防御性编码**,例如使用`assert`对入参进行校验.

7. 编码应尽可能**采用跨平台实现, 优先使用标准库提供的方法**,比如文件读取使用`std::ifstream`替换`fread fopen`, 使用`std::thread`替换一般的`Thread`等等

8. 目前C++20还不成熟, 语言标准指定到C++17即可, 需要注意有的嵌入式设备平台编译器只能支持到C++14.

9. 除非必要, **尽量不要使用模板编程**,模板编程有时候能够实现更简洁更易用的接口,但是容易引起维护灾难, 可读性容易崩塌.

10. 相比单纯为了封装若干不共享任何静态数据的静态成员函数而创建类, 不如使用命名空间.**类的静态方法应当和类的实例或静态数据紧密相关**
    ```cpp
    //应当使用
    namespace myproject {
    namespace foo_bar {
    void Function1();
    void Function2();
    }  // namespace foo_bar
    }  // namespace myproject
    //而非
    namespace myproject {
    class FooBar {
    public:
      static void Function1();
      static void Function2();
    };
    }// namespace myproject
    ```

11. **使用#include包含需要的头文件即可**,尽量避免前置声明那些定义在其他项目中的实体,因为前置声明隐藏了依赖关系, 编辑器也不好直接定位到定义.

12. **函数内必要的水平留白可以增加可读性**

13. **回调在内部尽可能用std::function实现及接收**, 如果是原始函数指针, 将难以接受其他函数类型对象．例如lambda,仿函数等等.

14. **提交git前需要进行标准格式化**, 使用vscode默认自动格式化方法即可(`ctrl+shift+i`全文件,`ctrl+k+f`格式化选中部分, `ctrl+k+x`去除尾随空格), android studio有Ctrl+Alt+L全文件等

15. `#include` 的路径及顺序
    - 使用标准的头文件包含顺序可增强可读性, 避免隐藏依赖, 构建会更快终止
    - 路径尽可能采用全路径
    - **头文件包含顺序应从最特殊到一般**,如：
        ```cpp
        #include "通用头文件"
        #include "源文件同名头文件"
        #include "本模块其他头文件"
        #include "自定义工具头文件"
        #include "第三方头文件"
        #include "平台相关头文件"
        #include "C++库头文件"
        #include "C库头文件"
        ```

16. 命名空间
    - 在命名空间的最后注释出命名空间的名字,宏也需要
    ```cpp
    namespace mynamespace {
    } // namespace mynamespace
    ```
    - 尽量不要使用内联命名空间`inline namespace`(违背唯一定义原则)
    ```cpp
    // 这样可以通过a::c来调用,不建议
    namespace a {
        inline namespace b {
            int c=0;
        }// namespace b
    } // namespace a
    ```
    - **头文件内不要使用using 引入整个命名空间的标识符号**,会污染命名空间, 源文件内可放松,
    ```cpp
    // 头文件内不要这么使用
    using namespace foo;
    // 头文件内应该完整引用命名空间
    std::string str;
    ```

17. 鼓励在 .cpp 文件内使用匿名命名空间或 static 声明,[*作用域按需扩大*], 对于不需要在其他地方引用的标识符使用内部链接性声明, 但是不要在 .h 中使用.

18. 将函数变量尽可能置于[*最小作用域*]内, 离第一次使用越近越好, 并在变量声明时进行初始化.

19. 构造与析构函数
    构造函数只负责简单的初始化工作, 不在构造函数中做太多逻辑相关的初始化, 更多操作放在init()方法中,析构同理, 主要操作放到release()方法中,**复杂初始化操作需要进行二段构造**

20. 隐式类型转换
    对于转换运算符和单参数构造函数, 使用`explicit`关键字,以避免可能的歧义.
    ```cpp
    class clsstr  // 使用关键字explicit的类声明, 显示转换
    {
    public:
        char *_pstr;
        int _size;
        explicit clsstr(int size)
        {
            _size = size;
        }
        clsstr(const char *p)
        {
            _pstr = p;
        }
    };
    // 下面是调用:
    clsstr string1(24);     // 这样是OK的
    clsstr string4("aaaa"); // 这样是OK的
    clsstr string5 = "bbb"; // 这样也是OK的, 调用的是clsstr(const char *p)
    clsstr string2 = 10;    // 这样是不行的, 因为explicit关键字取消了隐式转换
    clsstr string3;         // 这样是不行的, 因为没有默认构造函数
    clsstr string6 = 'c';   // 这样是不行的, 其实调用的是clsstr(int size), 且size等于'c'的ascii码, 但explicit关键字取消了隐式转换
    string1 = 2;              // 这样也是不行的, 因为取消了隐式转换
    ```

21. 结构体和类
    **所有结构体和类尽可能提供默认构造函数**,特别的, 如果定义了有参构造, 就需要手动提供默认构造并提供初始化方法, 否则引用声明初始化时会带来各种不便. [*代码健壮性更好*]

22. 组合和继承
    - 使用组合常常比使用继承更合理. 如果使用继承的话, 定义为 public 继承.
    - **is关系时继承, has关系时组合**
    - **如果基类有虚函数, 则析构函数也应为虚函数**, 因为引入了虚函数表机制, 子类向上转型到父类, 调用析构如果父类的析构声明不是虚函数, 将析构不到子类本身.
    - 对于子类重载的虚函数或虚析构函数, 使用 override, 或 (较不常用的) final 关键字显式地进行标记[*引入编译器检查*]

23. 运算符重载
    如果你定义了一个运算符, 请将其相关且有意义的运算符都进行定义, 并且保证这些定义的语义是一致的. 例如, 如果你重载了 <, 那么请将所有的比较运算符都进行重载, 并且保证对于同一组参数, < 和 > 不会同时返回 true.**重载同类运算符代码健壮性更好**

24. 存取控制
  - 所有 数据成员声明为 private, [*按需扩大作用域*]
  - 通过set/get方法访问(可以直接定义在头文件中)[*单例模式, 读写访问控制*]

25. 声明顺序
    - 在各个部分中, 建议将类似的声明放在一起, 并且建议以如下的顺序: 类型 (包括 typedef, using 和嵌套的结构体与类), 常量, 工厂函数, 构造函数, 析构函数,重载运算符,set/get方法, 其它函数, 数据成员.
    - 类定义可以采用多修饰符public: 将类似的声明分段, [*有利于增强可读性*]

26. 参数及其顺序
  - **入参在前, 出参在后**
  - 如果入参/出参参数很多, **多参数传递应该构造为结构体传入**, 因为可以解耦, 未来扩展不需要一层层改API, 并且更方便按需和相关服务句柄绑定,[*代码健壮性更好*]
  - 指针指向的对象如果含有结构应该进行结构化处理[*一目了然*]
  - **所有按引用传递的参数必须加上const,缺省输出参数为指针**,输出应该要允许传递nullptr, 表示不接收某个输出参数, 除非要求出参必须不能为nullptr(比如单个出参的情况）可以考虑使用非const引用

27. 所有权与智能指针
    动态分配出的对象最好有单一且固定的管理对象, 并通过智能指针传递所有权. 局部作用域中要求临时对象优先采用智能内存管理方式. [*代码健壮性更好*]
    ```cpp
    // 可以移动, 不能复制
    std::unique_ptr<cls> ptr(new cls());
    // 可以自定义析构方法
    std::unique_ptr<cls,std::function<void(cls*)>> ptr(new cls(), [](cls* p){delete p;});

    // 优先使用自动字符数组而不是原始指针
    std::vector<char> buffer(10);
    std::unique_ptr<char[]> buffer(new char[10]);
    ```

28. 运行时类型识别
    - 普通项目除非必要,禁止使用RTTI. **不要使用较复杂的特性, 不利于协作** (开源项目随意)
    - 在运行时判断类型通常意味着设计问题. 如果你需要在运行期间确定一个对象的类型, 这通常说明你需要考虑重新设计你的类.

29. 尽可能使用STL的类型转换, 如`dynamic_cast<>()`等 [*引入编译器检查*]

30. const及constexpr [*引入编译器检查*]
    - 强烈建议在任何可能的情况下都要**使用const修饰函数变量**. 此外有时改用 C++11 推出的 constexpr 更好.
    - const 变量, 数据成员, 函数和参数为编译时类型检测增加了一层保障; 便于尽早发现错误.
    - const 的位置: 实际上`int const *foo`形式语义更标准, 但是也有很多人习惯`const int* foo`
    - 编译时可以确定的常量用constexpr修饰

31. 指针初始化 使用更安全不会引起歧义的nullptr而不是NULL [*兼容性更好*]

32. 列表初始化 类型及对象的初始化尽可能使用{}进行初始化 [*代码一致性更好且引入编译器检查*]
    ```cpp
    //列表初始化不允许整型类型的四舍五入, 这可以用来避免一些类型上的编程失误.
    int pi(3.14);  // ok , pi == 3.
    int pi{3.14};  // 编译错误: 缩窄转换.
    ```

33. 预处理宏 [*尽可能缩小作用域*]
    - 使用宏时要非常谨慎,除非必要,尽量以内联函数, 枚举和常量代替之.
    - 不要在 .h 文件中定义宏.因为宏作用于全局作用域
    - 在马上要使用时才进行 #define, 使用后要立即 #undef.

34. auto 可以绕过烦琐的类型名, 增强可读性, 但是别用在局部变量之外的地方. [*可读性更好*]

35. Lambda 表达式
    - 适当使用 lambda 表达式. 建议所有捕获都显式写出来, 并且显式指定返回类型. [*一目了然*]
    ```cpp
    std::sort(v.begin(), v.end(), [](int x, int y) -> bool {
        return Weight(x) < Weight(y);
    });
    ```
   - `std::functions`和`std::bind`可以搭配成通用回调机制[*兼容性更好*]

36. 如果一些参数本身就是略复杂的表达式, 且降低了可读性, 那么可以直接创建临时变量描述该表达式, 并传递给函数 [*可读性优化*]：
    ```cpp
    // 表达式拆开, 中间过程用具有意义的变量标识或者直接添加注释
    int my_heuristic = scores[x] * y + bases[x];
    bool retval = DoSomething(my_heuristic, x, y, z);
    ```

37. 规范动态内存的管理, 统一为`new delete`组合 [*代码一致性*]

38. **命名约定**
    根据上文所述, google命名规则较为复杂, 不合理且不利于实施,
    故而总结**使用基于小写下划线的蛇形风格**,相较于驼峰式, 视觉一致性更佳,并且此风格与标准库以及扁平化的风格趋势和谐统一.
    - **简易型命名约定**
        - 命名全小写下划线
        - 成员变量用前缀/后缀下划线.
        - 宏命名 大写下划线

    - **增强型命名约定**, 建议用在库内部的编码
    虽然现代编译器都能悬停显示对象类型, 但是变量名如果能多一些类型描述符, 就不必经常悬停, 一目了然可读性更高一些, 所以可以这么处理：
        - 使用后缀标识来标识类类型
        - 使用前缀+下划线标识私有**变量**
        - 使用下划线+后缀标识文件名, 命名空间, 结构体, 类, 枚举等**类型**
        - 使用下划线+方法标识私有方法(正常`x_{}`用于表变量，`_{}`表方法就有不可达的意思)
        - 使用后置下划线标识临时变量(正常`{}_x`用于表类型，`{}_`表变量就有用完即弃的意思)
        - 全小写下划线, 通过前后缀补充描述
        - 各类文件的**缩进全部缺省4空格**
        - 结构体的公开成员不使用前置下划线
        - 宏命名 大写下划线
        - 数组及指针相关需要明确类型

|类型|前后缀| |
|---|---|---|
|接口|`{}_i`|interface|
|实现|`{}_impl`|implementation|
|枚举|`{}_e`|enumeration|
|结构体/类|`{}_t`|class/struct/union|
|回调|`{}_cb`|callback|
|组件|`{}_cp`|component|
|组件实现/操作|`{}_op`|opperation|
|函数对象|`{}_fn`|function|
|命名空间|`{}_ns`|namespace|
|临时变量|`{}_`|local|
|私有变量/方法|`_{}`|private|
|成员|`m_{}`|member|
|指针|`p_{}`|pointer|

39. 注释及代码文档化
    - 代码70%的时间是用来阅读的, 所以必要的文档化很有必要(对于非开源项目, 完整文档化需要做更多事情, 做到必要文档化即可)
    - 我们推崇**代码既文档+代码文档化**, 代码既文档依然需要去细看代码, 而文档化之后, 其他人接手可以不必细看代码, 直接看注释辅助代码, 阅读速度可以提升几倍.
    - 头文件都需要进行必要的文档化
    - 文档化采用`doxygen`风格(支持主流语言), 参考[doxygen文档](https://www.doxygen.nl/manual/index.html)
    - 文档注释主要在头文件进行, 不要描述显而易见的现象
    - 注释对齐有更好的可读性, 建议在行尾空两格进行注释
    - 每个类的定义都要附带一份注释, 描述类的功能和用法, 除非它的功能相当明显.
    - 函数声明处的注释描述函数功能; 定义处的注释描述函数实现.通常, 注释不会描述函数如何工作. 那是函数定义部分的事情.
    - 每个类数据成员（也叫实例变量或成员变量) 都应该用必要注释说明用途

40. 特殊注释
    - 标记一些未完成的或完成的不尽如人意的地方 使用TODO注释.
    - 有问题的代码用FIXME注释
    - 问题大或急的话直接提缺陷, 不急的先注释标记在代码里面,在vscode中会被高亮:
    ```cpp
    // TODO(ipanda-2020.08.26) 更好的解决方案是
    // FIXME(ipanda-2020.08.26) 有个什么bug
    ```

41. 弃用注释
    - 声明时未被弃用的名字可被重声明为`deprecated`,而声明为`deprecated`的名字不能通过重声明变为未弃用.
    - 使用了标注为弃用的方法, 会有编译警告,
    - 下列名字或实体的声明中允许使用这个属性:
        ```cpp
        class/struct/union：
        struct [[deprecated("Replaced by bar")]] S{};

        typedef/using：
        [[deprecated]] typedef S PS;
        using PS [[deprecated]] = S;

        变量,包括静态数据成员：[[deprecated]] int x;
        非静态数据成员：union U { [[deprecated]] int n; };
        函数：[[deprecated]] void f();
        命名空间：namespace [[deprecated]] NS { int x; }
        枚举：enum [[deprecated]] E {};
        枚举项：enum { A [[deprecated]], B [[deprecated]] = 42 };
        模板特化：template<typename T> struct [[deprecated]] X{};
        ```

---

#### 扩展

- 自动化检查
    可以借鉴Cpplint, 使用 `cpplint.py` 检查风格错误.但是目前它是不完善的, google本身很多规范都检查不了.
    在行尾加 // NOLINT, 或在上一行加 // NOLINTNEXTLINE, 可以忽略报错.
    ```bash
    python cpplint.py motion_detector.h

    motion_detector.h:0:  No copyright message found.  You should have a line: "Copyright [year] <Copyright Owner>"  [legal/copyright] [5]
    motion_detector.h:1:  #ifndef header guard has wrong style, please use: CPP_LIB_ALGO_SRC_MOTION_DETECTOR_H_  [build/header_guard] [5]
    motion_detector.h:160:  #endif line should be "#endif  // CPP_LIB_ALGO_SRC_MOTION_DETECTOR_H_"  [build/header_guard] [5]
    motion_detector.h:4:  <chrono> is an unapproved C++11 header.  [build/c++11] [5]
    motion_detector.h:5:  Found C system header after C++ system header. Should be: motion_detector.h, c system, c++ system, other.  [build/include_order] [4]
    motion_detector.h:72:  At least two spaces is best between code and comments  [whitespace/comments] [2]
    motion_detector.h:75:  Lines should be <= 80 characters long  [whitespace/line_length] [2]
    motion_detector.h:78:  { should almost always be at the end of the previous line  [whitespace/braces] [4]
    motion_detector.h:81:  Lines should be <= 80 characters long  [whitespace/line_length] [2]
    motion_detector.h:85:  public: should be indented +1 space inside class fast_motion_detector_impl  [whitespace/indent] [3]
    motion_detector.h:86:  You don't need a ; after a }  [readability/braces] [4]
    motion_detector.h:87:  Lines should be <= 80 characters long  [whitespace/line_length] [2]
    motion_detector.h:160:  At least two spaces is best between code and comments  [whitespace/comments] [2]
    motion_detector.h:127:  Add #include <vector> for vector<>  [build/include_what_you_use] [4]
    Done processing motion_detector.h
    ```

- [Doxygen文档](http://www.doxygen.nl/manual/index.html)
    ```cpp
    /**
    *  多行注释
    */

    /**单行注释*/ 或 /// 或 //! (Doxygen认为注释是修饰接下来的程序代码的)

    /**<同行注释 */ 或 ///<

    //文件信息
    @file      文件名
    @author    作者名
    @version   版本号
    @todo      待办事项
    @date      日期时间
    @section   章节标题 e.g. [@section LICENSE 版权许可] [@section DESCRIPTION 描述]

    //模块信息
    @defgroup   定义模块 格式：模块名(英文) 显示名 @{ 类/函数/变量/宏/... @}
    @ingroup    作为指定名的模块的子模块 格式：模块名(英文) [显示名]
    @addtogroup 作为指定名的模块的成员 格式：模块名(英文) [显示名]
    @name       按用途分,以便理解全局变量/宏的用途 格式：显示名(中文) @{ 变量/宏 @}

    //函数信息
    @brief     摘要
    @overload  重载标识
    @param     参数说明
    @param[in]      输入参数
    @param[out]     输出参数
    @param[in,out]  输入输出参数
    @return    返回值说明
    @retval    特定返回值说明 [eg:@retval NULL 空字符串][@retval !NULL 非空字符串]
    @exception 可能产生的异常描述
    @enum      引用了某个枚举,Doxygen会在引用处生成链接
    @var       引用了某个变量
    @class     引用某个类 [eg: @class CTest "inc/class.h"]
    @see       参考链接,函数重载的情况下,要带上参数列表以及返回值
    @todo      todo注解
    @pre       前置条件说明
    @par       [段落标题] 开创新段落,一般与示例代码联用
    @code      示例代码开始 e.g. [code{.cpp}]
    @endcode  示例代码结束

    //提醒信息
    @note      注解
    @attention 注意
    @warning   警告
    @bug       问题
    ```
