# C++ 奇淫巧计

[toc]
<!-- toc -->

第一眼看上去比较新鲜的各种C++实践。

收录内容比较主观,有些是现代C++的新特性，有些可能蛮常见的,但是回想第一次看见时还挺新鲜的,所以会一并收录。

---

- 取数组大小
    ```cpp
    int arr[]={1,2,3,4,5};
    int size = sizeof(arr)/sizeof(arr[1]);//正常
    int size = *(&arr+1)-arr;             //不走寻常路
    ```

- 文件内扩栈(系统栈不够用的话)
    ```cpp
    #pragma comment(linker,"/STACK:102400000,102400000")

    //g++中使用这种方法
    int __size__ = 256 << 20; // 256mb
    char *__p__ = (char *)malloc(__size__) + __size__;
    __asm__("movl %0,%%esp\n" ::"r"(__p__));
    ```

- 文件内指定链接静态库
    ```cpp
    #pragma message("link opencv libs in opencv.hpp.")//链接库文件时可以编译提示
    #pragma comment(lib,"opencv_core410.lib")
    ```

- 代码中开O3优化
    ```cpp
    #define fastcall __attribute__((optimize("-O3")))
    ```

- 大括号别名
    ```cpp
    { } 等价于 <% %>
    ```

- 看起来像趋近于的`while(i-->0)`，实际上是:
    ```cpp
    int i = 10;
    while((i--) > 0)
    {//＞0 打印后自减
        cout<<i<<endl;//输出9 8 ... 0
    };
    ```

- 通过异或法原地交换整数a b
    ```cpp
    int a = 1, b = 2;
    a ^= b ^= a ^= b;//显然a,b不能是同一个对象的引用
    cout << a << " " << b << endl;//2 1
    ```

- 最简洁也是效率最高的单例模式的实现
    ```cpp
    single& single::get_instance()
    {
        static single instance;
        return instance;
    }
    ```

- 等价读取,产生合并的唯一ID
    ```cpp
    //给part成员赋值,以merge_id读取,只要保证内存匹配就可以互相转换
    union msg_id
    {
        int merge_id;// = major_id | minor_id << 16
        struct part
        {
            unsigned short major_id;
            unsigned short minor_id;
        }
    }
    ```

- 2次幂枚举量
    ```cpp
    enum Days
    {
        None = 0,
        Sunday = 1,
        Monday = 2,
        Tuesday = 4,
        Wednesday = 8,
        Thursday = 16,
        Friday = 32,
        Saturday = 64
    };

    Days flag = Days::Monday;

    //添加条件: |
    flag = Days(flag | Days::Wednesday);

    //删除条件: &~
    flag = Days(flag & ~ Wednesday);

    // "flag" 为 "Monday"
    if ((flag & Monday) == Monday)
    {cout << "Monday" << endl;}

    // "flag"  为"Monday 与 Wednesday"
    if ((flag & (Monday | Wednesday)) == (Monday | Wednesday))
    {cout << "Monday & Wednesday" << endl;}

    // "flag" 为 "Monday 或者 Wednesday"
    if ((flag & (Monday | Wednesday)) != 0)
    {cout << "Monday | Wednesday" << endl;}
    ```

- `delete this` 有点反直觉，我杀我自己
    - 确保对象是new出来的
    - 确保delete完后不能访问对象的任何部分
    - 确保delete完后this指针不会被访问

- 自定义字面量
    ```cpp
    // 通过重载双引号后缀运算符实现
    // 字符串字面量自定义必须设置如下的参数列表
    std::string operator"" _wow1(const char *wow1, size_t len) {
        return std::string(wow1)+"def";
    }
    // 整形设置如下的参数列表
    std::string operator"" _wow2 (unsigned long long i) {
        return std::to_string(i) + "23456";
    }
    auto str = "abc"_wow1;//abcdef
    auto num = 1_wow2;//123456
    ```
- 结构化绑定 C++17
    ```cpp
    std::tuple<int, double, std::string> f({1,2.0,"a"})
    auto [x, y, z] = f();
    ```

- 如何将lambda存在new出来的内存？
    ```cpp
    auto fn=new auto([]{});
    delete fn;
    ```

- 如何检测某个类有某个名字的成员？
    ```cpp
    bool flag=std::is_member_pointer<decltype(&Func::foo)>::value;
    ```

- main函数的类型名是什么?
    ```cpp
    #include <iostream>
    #include <typeinfo>
    using namespace std;
    int main(){
        cout<<typeid(main).name()<<endl;//FivE
        cout<<typeid(main).hash_code()<<endl;//1782139812
    }
    ```

---

## 泛型编程

泛型编程比较特殊,单独列出.模板的哲学在于将一切能够在编译期处理的问题丢到编译期进行处理，仅在运行时处理那些最核心的动态服务，进而大幅优化运行期的性能。因此模板也被很多人视作 C++ 的黑魔法之一。

- 自动推断数组大小(一般的非类型模板)
    ```cpp
    //(unsigned需要放在前面)
    template<unsigned n,typename T>
    void arr(const T (&m)[n]) {
        std::cout << "size:" << n;
    }
    ```
- 自动推导的非类型模板 C++17
    ```cpp
    enum e{a,b,c};
    template <auto value>
    void foo(){
        cout << value << endl;
    }
    int main(){
        foo<10>(); //10
        foo<e::a>(); //0
    }
    ```

- 不定长参数列表
    - 标准但落后的递归法解包
    ```cpp
    // 用于结束递归的同名模板函数
    template<typename T>
    inline void delete_s(T& p){
        if (p != nullptr) { delete(p); p = nullptr; }
    }

    // 用于递归不定长参数的同名模板函数
    template<typename T, typename...Args>
    inline void delete_s(T& p, Args&... args){
        if (p != nullptr) { delete(p); p = nullptr; }
        delete_s(args...);
    }

    // 可以接受任意长参数
    int main(){
        auto* p1=new auto([]{});
        auto* p2=new auto([]{});
        auto* p3=new auto([]{});
        cout<<p1<<endl;
        cout<<p2<<endl;
        cout<<p3<<endl;
        delete_s(p1,p2,p3);
        cout<<p1<<endl;
        cout<<p2<<endl;
        cout<<p3<<endl;
    }
    ```
    - 条件编译递归解包 C++17
    ```cpp
    // 一个递归函数搞定
    template<typename T, typename... Args>
    void delete_s(T& p, Args&... args) {
        if (p != nullptr) { delete(p); p = nullptr; }
        if constexpr (sizeof...(args) > 0) delete_s(args...);
    }
    ```
    - lambda表达式+逗号表达式(黑魔法) 非递归原地解包
    ```cpp
    //(a, b)这个表达式的值就是b. 执行((lambda, value),...)
    //首先会执行前面的lambda,而后计算逗号表达式(值为0),接着继续展开
    template <typename T, typename... Args>
    auto delete_s(T& p, Args&... args){
        if (p != nullptr) { delete(p); p = nullptr; }
        (([&args]{
            if (args != nullptr) { delete(args); args = nullptr; }
        }(),0),...);
    }
    ```

- 折叠表达式
    ```cpp
    template<typename ... T>
    auto sum(T ... t) {
        return (t + ...);
    }
    int main() {
        cout << sum(1, 2, 3, 4, 5, 6, 7, 8, 9, 10) << endl;//55
    }
    ```

- 泛型Lambda C++14
    ```cpp
    // 正常模板写法
    template <typename T, typename U>
    auto add(T t, U u) {return t+u;}
    // 新特性
    auto add = [](auto x, auto y) {return x+y;};

    cout<<add(1,2)<<endl; //3
    cout<<add(string("1"),string("2"))<<endl; //12
    ```

- 函数缓存
    为了优化程序性能我们经常使用缓存,比如某个函数非常耗时,频繁调用的时候性能会很低,这时我们可以通过缓存来提高性能.
    ```cpp
    namespace detail {
        //函数入参及结果缓存,缓存入参和函数的执行结果,若入参存在则从缓存返回结果
        template <typename R, typename... Args>
        std::function<R(Args...)> cache_fn(R(*func)(Args...)){
            auto result_map = std::make_shared<std::map<std::tuple<Args...>, R>>();
            return ([=](Args... args) {//延迟执行
                std::tuple<Args...> _args(args...);
                if (result_map->find(_args) == result_map->end()) {
                    (*result_map)[_args] = func(args...);//未找到相同入参,执行函数刷新缓存
                }
                return (*result_map)[_args];//返回缓存的对应入参的结果
            });
        }
    }

    //函数对象缓存,若存在相同类型函数指针,则调用相应缓存函数获取缓存结果
    template <typename R, typename...  Args>
    std::function<R(Args...)> cache_fn(R(*func)(Args...), bool flush = false){
        using function_type = std::function<R(Args...)>;
        static std::unordered_map<decltype(func), function_type> functor_map;
        if (flush) {//明确要求刷新缓存
            return functor_map[func] = detail::cache_fn(func);
        }
        if (functor_map.find(func) == functor_map.end()) {
            functor_map[func] = detail::cache_fn(func);//未找到相同函数,执行函数刷新缓存
        }
        return functor_map[func];//返回对应函数的缓存的结果
    }

    //函数缓存可以提高类似重复计算类函数的性能
    //以计算斐波那契数列为例: O(N^2) --> O(N)
    size_t fibonacci_1(size_t n) {
        return (n < 2) ? n : fibonacci_1(n - 1) + fibonacci_1(n - 2);
    }
    size_t fibonacci_2(size_t n) {
        return (n < 2) ? n : cache_fn(fibonacci_2)(n - 1) + cache_fn(fibonacci_2)(n - 2);
    }

    auto t1 = getFnDuration(fibonacci_1)(35);//47ms (为45时,为5000ms)
    auto t2 = getFnDuration(fibonacci_2)(35);//0ms  (为1000时,为2ms)
    ```

- `std::shared_ptr`和`boost::shared_ptr`之间的转换. [[Refer]](https://stackoverflow.com/questions/12314967/cohabitation-of-boostshared-ptr-and-stdshared-ptr)
    ```cpp
    // 通过按值捕获将原始ptr(及其引用计数)保留在删除器lambda中
    // 可能有一定缺陷，例如无法来回转换
    template<typename T>
    std::shared_ptr<T> to_std(const boost::shared_ptr<T> &p) {
        return std::shared_ptr<T>(p.get(), [p](...) mutable { p.reset(); });
    }

    template<typename T>
    boost::shared_ptr<T> to_boost(const std::shared_ptr<T> &p) {
        return boost::shared_ptr<T>(p.get(), [p](...) mutable { p.reset(); });
    }
    ```

---

## 其他非语言特性的技巧
- abs移位运算
    ```cpp
    int abs(int x){
        int y = x >> 31;
        return (x ^ y) - y; // or: (x+y)^y
    }
    ```