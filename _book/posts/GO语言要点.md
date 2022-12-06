# GO语言要点

- 基于消息并发模型(同步通信),Goroutine之间是共享内存的.
- GO调度器采用半抢占式的协作调度,只有在当前协程发生阻塞时才会导致调度.

- 标准库`sync.Once`的实现 原子操作配合互斥锁
    ```go
    import(
        "sync"
        "sync/atomic"
    )
    type Once struct{
        m Mutex
        done uint32
    }
    func (o *Once)Do(f func()){
        if atomic.LoadUint32(&o.done) == 1{
            return
        }
        o.m.Lock()
        defer o.m.Unlock()
        if o.done == 0{
            defer atomic.StoreUint32(&o.done,1)
        }
    }
    ```
- 基于`sync.Once`的单例模式
    ```go
    var(
        instance *singleton
        once sync.Once
    )
    func Instance() *singleton{
        once.Do(func(){
            instance = &singleton
        })
        return instance
    }
    ```
- 原子操作支持: `atomic.Value`提供了`Load()`和`Store()`方法用于加载保存,可用于任意类型
    ```go
    var config atomic.Value
    ```

- 顺序一致性 通过通道`chan`或者互斥量`sync.Mutex`来同步

- 初始化顺序
    - 包只会被导入一次
    - 先执行依赖包和本包的`init()`(init()不是普通函数,可以被定义多次,但不能被其他函数调用)
    - 最后执行`main.main()`

- 阻塞线程 正常退出可以调用`os.Exit(0)`
    - `select{}`
    - `for{}`
    - `<-make(chan int)`
- `Ctrl+C`退出
    ```go
    sig := make(chan os.Signal,1)
    signal.Notify(sig,syscall.SIGINT,syscall.SIGTERM)
    fmt.Printf("quit (%v)",<-sig>)
    ```
- 等到N个并发操作完成 使用`sync.waitGroup`
    ```go
    func main(){
        var wg sync.waitGroup
        for i:=0 ;i<10;i++{
            wg.Add(1)//添加一个等待事件
            go func(){
                fmt.Println("hello,world")
                wg.Done()//完成一个事件
            }()
        }
        wg.Wait()//等待所有事件完成
    }
    ```
- 常见并发模型
    - 生产者/消费者
        ```go
        func Producer(factor int,out chan<-int){
            for i:=0;;i++{
                out<-i*factor //生产factor的整数倍序列
            }
        }
        func Consumer(in <-chan int){
            for v:= range in{
                fmt.Println(v)
            }
        }
        func main(){
            ch := make(chan int,64)//成果队列
            go Producer(3,ch)
            go Producer(5,ch)
            go Consumer(ch)
            time.Sleep(5*time.Second)
        }
        ```
    - 发布/订阅
    - 控制并发数
        ```go
        import(
            "golang.org/x/tools/godoc/vfs"
            "golang.org/x/tools/godoc/vfs/gatefs"
        )
        int main(){
            //vfs.OS构造一个虚拟文件系统,gatefs.New构建一个并发受控的vfs
            //不仅可以控制并发数,还可以判断并发率
            fs:=gatefs.New(vfs.OS("/path"),make(chan bool,8))
            //...
        }
        ```
    - 赢者为王 多协程只获取最先返回的结果
    - 素数筛
    - 并发的安全退出
        - 超时判断
            ```go
            select{
                case v:=<-in:
                    fmt.Println(v) //正常工作
                case <-quit:
                    //退出
                case <-time.After(tine.Second)
                    return //超时
                default:
                    //没有数据
            }
            ```
        - 通过`close()`来关闭通道实现广播quit信号
        - 通过`sync.WaitGroup`来保证清理工作的完成
    - context包 简化协程间的超时,退出等操作
- 错误处理
    - GO库的实现习惯:即使在包内部使用了panic,在导出函数时也会被转化为明确的错误值
    - 用`recover()`将异常转为内部错误处理/防御性捕获(recover不应该被包装或嵌套调用)
        ```go
        defer func(){
            if p:= recover();p!=nil{
                err=fmt.Errorf("error %v",p)
            }
        }()
        ```
    - 注意使用`defer`以防文件不能被正确关闭
    - 获取错误的上下文
        - 定义辅助函数记录原始的错误信息
- CGO编程
    - 调用C函数,或者导出GO函数给C调用
    - 需要安装GCC/MinGW,并且环境变量`CGO_ENABLED`置1
    - 不同GO包引入的虚拟C包中的类型是不同的,不能兼容(哪怕是同一个函数)
    - 启用CGO特性,go build会在编译链接阶段启动GCC编译器
        ```go
        import "C"
        ```
    - 调用C接口函数
        ```go
        package main
        /*
        #include <stdio.h>
        void SayHello(const char* s){
            puts(s);
        }
        */
        import "C"
        func main(){
            C.SayHello(C.CString("Hello,world\n"))
        }
        ```
    - 放在独立的C文件中(当前目录下,以.c结尾,或者通过动态库链接),在CGO部分声明C函数
        ```go
        package main

        //void SayHello(const char* s);
        
        import "C"
        func main(){
            C.SayHello(C.CString("Hello,world\n"))
        }
        ```
    - 将接口函数声明放在.h文件中,实现语言可以是C或C++或汇编或GO语言
        ```go
        //SayHello.go
        //...
        //export SayHello
        func SayHello(s *C.char){
            fmt.Print(C.GoString(s))
        }
        ```
    - 进一步提炼CGO (`_GoString_`是预定义的C语言类型,表示GO语言字符串)
        ```go
        package main
        // void SayHello(_GoString_ s);
        import "fmt"
        func main(){
            C.SayHello("hellow,world\n")
        }
        //export SayHello
        func SayHello(s string){
            fmt.Print(s)
        }
        ```
    - `#cgo`语句,在`import "C"`之前用于设置编译链接参数
    - `build`标志 条件编译
        ```go
        源文件设置:
        // +build debug
        构建:
        go build -tags="debug"
        ```
    - C调用GO 生成静态库/动态库和头文件
        ```bash
        go build -buildmode=c-archive -o sum.a sum.go
        go build -buildmode=c-shared -o sum.so sum.go
        ```
- GO汇编
    - 优势
        - 跨操作系统
        - 不同CPU用法很相似
        - 支持C语言预处理器
        - 支持模块
- RPC和Protobuf
    - `net/rpc`包(进一步包装更安全高效)
    - RPC规则:方法必须公开,只能有2个可序列化的参数,第二个参数是指针类型,且返回error类型,
    - `rpc.RegisterName()`注册对象类型(服务)下所有符合RPC规则的方法
        ```go
        type HelloService struct{}
        func (p *HelloService)Hello(request string,reply *string)error{
            *reply = "hello:"+request
            return nil
        }
        //服务端
        rpc.RegisterName("HelloService",new(HelloService))
        listener,err:=net.Listen("tcp",":1234")
        conn,err:=listener.Accept()
        rpc.ServeConn(conn)
        //客户端
        client,err:=rpc.Dial("tcp","localhost:1234")
        var reply string
        err = client.Call("HelloService.Hello","hello",&reply)
        ```
    - RPC接口规范
        - 服务名字
        - 服务提供的方法列表
        - 注册该类型服务的函数
    - 跨语言的RPC
        - 基于JSON重新实现RPC服务
        - 用`rpc.ServeCodec()`替代`rpc.ServeConn()`
    - HTTP上的RPC
        - 创建HTTP服务 中转jsonrpc服务
    - Protobuf
        - `go get github.com/golang/protobuf/protoc-gen-go`
        - `protoc --go_out=. hello.proto`
        - `protoc --go_out=plugins=grpc:. hello.proto`使用内置插件生成gRPC代码
        - 可以通过构建模板自动生成完整的RPC代码(PB插件)
    - 证书认证

