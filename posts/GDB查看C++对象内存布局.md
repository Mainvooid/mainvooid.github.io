# GDB查看C++对象内存布局

[toc]
<!---toc--->

## GDB常用命令

- `ctrl+d` quit
- `file <文件名>` 加载执行文件/符号
- `b <行号>` 打断点
- `i b` 查看断点
- `d <断点号>` 删除断点
- `start|run|r` 执行文件 缩写r
- `next|n <行数>` 单步跳过 默认1行 缩写n
- `step|s <行数>` 单步调试 进入函数 缩写s
- `until|u <行号>` 单步跳过(快速执行循环体) 缩写u
    - 不带参数的`until`命令, 当执行至循环体尾部(最后一行代码)时可以使 GDB调试器快速运行完当前的循环体, 并运行至循环体外停止. 反之,`until`命令和`next`命令的功能一样, 只是单步执行程序.

```bash
(gdb) help info
info address -- Describe where symbol SYM is stored
info all-registers -- List of all registers and their contents
info args -- All argument variables of current stack frame or those matching REGEXPs
info auto-load -- Print current status of auto-loaded files
info auxv -- Display the inferiors auxiliary vector
info bookmarks -- Status of user-settable bookmarks
info breakpoints -- Status of specified breakpoints (all user-settable breakpoints if no argument)
info classes -- All Objective-C classes
info common -- Print out the values contained in a Fortran COMMON block
info copying -- Conditions for redistributing copies of GDB
info dcache -- Print information on the dcache performance
info display -- Expressions to display when program stops
info exceptions -- List all Ada exception names
info extensions -- All filename extensions associated with a source language
info files -- Names of targets and files being debugged
info float -- Print the status of the floating point unit
info frame -- All about the selected stack frame
info frame-filter -- List all registered Python frame-filters
info functions -- All function names or those matching REGEXPs
info guile -- Prefix command for Guile info displays
info handle -- What debugger does when program gets various signals
info inferiors -- Print a list of inferiors being managed
info line -- Core addresses of the code for a source line
info locals -- All local variables of current stack frame or those matching REGEXPs
info macro -- Show the definition of MACRO
info macros -- Show the definitions of all macros at LINESPEC
info mem -- Memory region attributes
info os -- Show OS data ARG
info pretty-printer -- GDB command to list all registered pretty-printers
info probes -- Show available static probes
info proc -- Show additional information about a process
info program -- Execution status of the program
info record -- Info record options
info registers -- List of integer registers and their contents
info scope -- List the variables local to a scope
info selectors -- All Objective-C selectors
info set -- Show all GDB settings
info sharedlibrary -- Status of loaded shared object libraries
info signals -- What debugger does when program gets various signals
info skip -- Display the status of skips
info source -- Information about the current source file
info sources -- Source files in the program
info stack -- Backtrace of the stack
info static-tracepoint-markers -- List target static tracepoints markers
info symbol -- Describe what symbol is at location ADDR
info target -- Names of targets and files being debugged
info tasks -- Provide information about all known Ada tasks
info terminal -- Print inferiors saved terminal status
info threads -- Display currently known threads
info tracepoints -- Status of specified tracepoints (all tracepoints if no argument)
info tvariables -- Status of trace state variables and their values
info type-printers -- GDB command to list all registered type-printers
info types -- All type names
info unwinder -- GDB command to list unwinders
info variables -- All global and static variable names or those matching REGEXPs
info vector -- Print the status of the vector unit
info vtbl -- Show the virtual function table for a C++ object
info w32 -- Print information specific to Win32 debugging
info warranty -- Various kinds of warranty you do not have
info watchpoints -- Status of specified watchpoints (all watchpoints if no argument)
info win -- List of all displayed windows
info xmethod -- GDB command to list registered xmethod matchers
```

## 查看内存布局

test.cpp:
```cpp
#include <iostream>
using namespace std;

// 基类
class base{
public:
    base() {}
    virtual ~base() {}
    virtual void print() const { cout << "base::print()" << endl; }
    static int get() { return ms_tmp; };
protected:
    int m_base;
    static int ms_tmp;
};

// 单继承无覆盖
class simple : public base{
public:
    simple() {}
    virtual ~simple() {}
    virtual void simple_print() { cout << "simple::simple_print()" << endl; }
private:
    int m_simple;
};

// 单继承有覆盖
class override : public base{
public:
    override() {}
    virtual ~override() {}
    virtual void override_print() { cout << "override::override_print()" << endl; }
    virtual void print() const override { cout << "override::print()" << endl; };
private:
    int m_override;
};

// 多继承
class base_mult{
public:
    base_mult() {}
    virtual ~base_mult() {}
    virtual void print() const { cout << "base_mult::print()" << endl; }
protected:
    int m_base_mult;
};

class derived_mult : public base, public base_mult{
public:
    derived_mult() {}
    virtual ~derived_mult() {}
    virtual void derived_mult_print() { cout << "derived_mult::derived_mult_print()" << endl; }
private:
    int m_derived_mult;
};

// 虚继承有覆盖
class derived_v : virtual public base
{
public:
    derived_v() {}
    virtual ~derived_v() {}
    virtual void derived_v_print() { cout << "derived_v::derived_v_print()" << endl; }
    virtual void print() const override { cout << "derived_v::print()" << endl; };
private:
    int m_derived_v;
};

// 菱形继承
class derived_v1 : virtual public base
{
public:
    derived_v1() {}
    virtual ~derived_v1() {}
    virtual void derived_v1_print() { cout << "derived_v1::derived_v1_print()" << endl; }
private:
    int m_derived_v1;
};

class derived_v2 : virtual public base
{
public:
    derived_v2() {}
    virtual ~derived_v2() {}
    virtual void derived_v2_print() { cout << "derived_v2::derived_v2_print()" << endl; }
private:
    int m_derived_v2;
};

class derived_last : public derived_v1, public derived_v2
{
public:
    derived_last() {}
    virtual ~derived_last() {}
    virtual void derived_last_print() { cout << "derived_last::derived_last_print()" << endl; }
private:
    int m_derived_last;
};

int main(){
    base base_;
    simple simple_;
    override override_;
    derived_mult derived_mult_;
    derived_v derived_v_;
    derived_last derived_last_;
    return 0;
}
```

使用`-g`选项编译:
`g++ -g -std=c++17 d:\code\vscode-cpp\test.cpp -o test.exe`

gdp分析调试程序
`gdb test test.exe`

进入GDB环境
```bash
# 开启打印选项
(gdb) set print object on
(gdb) set print vtbl on
(gdb) set print pretty on
# 打断点
(gdb) b 101
Breakpoint 1 at 0x4015fa: file d:\code\vscode-cpp\test.cpp, line 101.
# 执行程序
(gdb) r
Starting program: D:\code\vscode-cpp\test.exe 
[New Thread 98208.0x31b20]
[New Thread 98208.0x16d7c]
[New Thread 98208.0x4aeac]

Thread 1 hit Breakpoint 1, main () at d:\code\vscode-cpp\test.cpp:101
warning: Source file is more recent than executable.
101         simple simple_;

(gdb) n 5
[New Thread 151628.0x1fb18]
106         return 0;

# 测试基类
(gdb) p base_
$1 = {_vptr.base = 0x4045ec <vtable for base+8>, m_base = 0, 
  static ms_tmp = <optimized out>}
## 对象由vptr和数据成员组成

(gdb) p sizeof(base_)
$2 = 8

## 以16进制(x),打印8个字节(b)
(gdb) x/8xb &base_       
0x266fe28:      0xec    0x45    0x40    0x00    0x00    0x00    0x000x00
## 可以看到,实例化对象在内存中是小端序

(gdb) info vtbl base_
vtable for 'base' @ 0x4045ec (subobject @ 0x266fe28):
[0]: 0x402bc8 <base::~base()>
[1]: 0x402ba0 <base::~base()>
[2]: 0x402e5c <base::print() const>
## 为什么会有两个虚析构函数?
## g++里虚析构函数在虚表里是一对;一个叫complete object destructor, 另一个叫deleting destructor
## 区别在于前者只执行析构函数不执行delete(), 后者在析构之后执行deleting操作. 
## 应该是g++想把non-detele的析构函数轮一遍后, 然后用delete直接就清理掉整个内存.

(gdb) info symbol 0x4045ec
vtable for base + 8 in section .rdata of D:\code\vscode-cpp\test.exe
## C++虚函数表保存在.rdata只读数据段

# 单继承无覆盖
(gdb) p simple_ 
$3 = {<base> = {_vptr.base = 0x404600 <vtable for simple+8>, 
    m_base = 4200208, static ms_tmp = <optimized out>}, 
  m_simple = 4199233}
## 对象由基类的vptr, 成员数据和派生类自身成员数据顺序构成

(gdb) p sizeof(simple_)
$4 = 12

(gdb) info vtbl simple_
vtable for 'simple' @ 0x404600 (subobject @ 0x266fe1c):
[0]: 0x402c74 <simple::~simple()>
[1]: 0x402c4c <simple::~simple()>
[2]: 0x402e5c <base::print() const>
[3]: 0x402bf8 <simple::simple_print()>
## 派生类的虚函数放入到基类的虚函数表中.

# 单继承有覆盖
(gdb) p override_
$5 = {<base> = {_vptr.base = 0x404618 <vtable for override+8>, 
    m_base = 129595956, static ms_tmp = <optimized out>}, 
  m_override = 40304328}

(gdb) info vtbl override_
vtable for 'override' @ 0x404618 (subobject @ 0x266fe10):
[0]: 0x402d10 <override::~override()>
[1]: 0x402ce8 <override::~override()>
[2]: 0x402e90 <override::print() const>
[3]: 0x402c94 <override::override_print()>
## 派生类的虚函数放入/覆盖到基类的虚函数表中.

# 多继承
(gdb) p derived_mult_
$6 = {<base> = {
    _vptr.base = 0x4045c0 <vtable for derived_mult+8>, 
    m_base = 4200208,
    static ms_tmp = <optimized out>}, <base_mult> = {
    _vptr.base_mult = 0x4045d8 <vtable for derived_mult+32>,
    m_base_mult = 0}, m_derived_mult = 2}

(gdb) info vtbl derived_mult_
vtable for 'derived_mult' @ 0x4045c0 (subobject @ 0x266fdfc):
[0]: 0x402b38 <derived_mult::~derived_mult()>
[1]: 0x402b10 <derived_mult::~derived_mult()>
[2]: 0x402e5c <base::print() const>
[3]: 0x402aa4 <derived_mult::derived_mult_print()>

vtable for 'base_mult' @ 0x4045d8 (subobject @ 0x266fe04):
[0]: 0x402f44 <non-virtual thunk to derived_mult::~derived_mult()>   
[1]: 0x402f3c <non-virtual thunk to derived_mult::~derived_mult()>
[2]: 0x402ec4 <base_mult::print() const>
## 基类拥有各自的虚函数表, 派生类的虚函数放入到第一个基类的虚函数表中.

# 虚继承有覆盖
(gdb) p derived_v_
$7 = {<base> = {_vptr.base = 0x404668 <vtable for derived_v+44>, 
    m_base = 40304328, static ms_tmp = <optimized out>}, 
  _vptr.derived_v = 0x404648 <vtable for derived_v+12>, 
  m_derived_v = 1383044177}
## 对象由自身vptr及数据成员+基类对象顺序组成

(gdb) info vtbl derived_v_   
vtable for 'derived_v' @ 0x404648 (subobject @ 0x266fdec):
[0]: 0x402e2c <derived_v::~derived_v()>
[1]: 0x402e04 <derived_v::~derived_v()>
[2]: 0x402da0 <derived_v::derived_v_print()>
[3]: 0x402ef8 <derived_v::print() const>

vtable for 'base' @ 0x404668 (subobject @ 0x266fdf4):
[0]: 0x402f70 <virtual thunk to derived_v::~derived_v()>
[1]: 0x402f64 <virtual thunk to derived_v::~derived_v()>
[2]: 0x402f7c <virtual thunk to derived_v::print() const>
## 基类和派生类拥有各自的虚函数表.

# 菱形继承
(gdb) p derived_last_
$8 = {<derived_v1> = {<base> = {
      _vptr.base = 0x4045ac <vtable for derived_last+68>,
      m_base = 40304376, static ms_tmp = <optimized out>}, 
    _vptr.derived_v1 = 0x404574 <vtable for derived_last+12>, 
    m_derived_v1 = 28}, <derived_v2> = {
    _vptr.derived_v2 = 0x404590 <vtable for derived_last+40>,        
    m_derived_v2 = 4200208}, m_derived_last = 40304076}
## 对象由中间类的vptr, 数据成员和虚基类的vptr, 数据成员顺序构成,仅第一个中间类包含虚基类对象.

(gdb) info vtbl derived_last_
vtable for 'derived_last' @ 0x404574 (subobject @ 0x266fdd0):
[0]: 0x402a3c <derived_last::~derived_last()>
[1]: 0x402a14 <derived_last::~derived_last()>
[2]: 0x402840 <derived_v1::derived_v1_print()>
[3]: 0x402978 <derived_last::derived_last_print()>

vtable for 'derived_v2' @ 0x404590 (subobject @ 0x266fdd8):
[0]: 0x402f34 <non-virtual thunk to derived_last::~derived_last()>   
[1]: 0x402f2c <non-virtual thunk to derived_last::~derived_last()>
[2]: 0x4028dc <derived_v2::derived_v2_print()>

vtable for 'base' @ 0x4045ac (subobject @ 0x266fde4):
[0]: 0x402f58 <virtual thunk to derived_last::~derived_last()>
[1]: 0x402f4c <virtual thunk to derived_last::~derived_last()>       
[2]: 0x402e5c <base::print() const>
## 虚基类和中间类拥有虚函数表，派生类的虚函数表放在第一个中间类的虚函数表中.
```

## 基于g++编译器的结论
- 类对象实例化就是初始化vptr和数据成员的内存空间
- 实例化类对象在内存中是小端编码: 高位存放于低地址
- C++虚函数表保存在`.rdata`只读数据段
- g++会创建2个虚析构函数以优化内存回收效率
- 优先将派生类的虚函数放入/覆盖到第一个父类的虚函数表中.
- 在内存中,优先存放派生类再中间类再基类
- g++不存在虚基表概念(VS编译器中vbptr放在vptr之后)
