# Android-NDK-Camera双摄接入方案
- 官方文档: [Camera](https://developer.android.com/ndk/reference/group/camera)

- 官方NDK 相机示例：[ndk-samples](https://github.com/android/ndk-samples/camera)


官方示例里面有俩个module可以参考，主要为单摄，包含preview与snapshot：
basic
suface 表面对象为`ANativeWindow`

使用了`android_app_glue`, 在android_main中循环调用DrawFrame绘制从camera2取到的image

- CameraEngine 类
  处理android_app，相机对象与UI交互
  ```cpp
  //主要API
  ANativeWindow_setBuffersGeometry

  //DrawFrame
  ANativeWindow_acquire // window surface
  ANativeWindow_Buffer
  ANativeWindow_lock
  //Aimage对象数据处理后输出到buf
  ANativeWindow_unlockAndPost
  ANativeWindow_release
  ```

- NDKCamera类
  相机管理
  ```cpp
  //主要API
  ACameraManager //相机管理
  ACaptureRequest //请求对象
  ACameraCaptureSession //请求的会话
  ACaptureSessionOutputContainer

  ACameraManager_create // 创建ACameraManager
  ACameraManager_getCameraIdList//获逻辑相机ID列表
  ACameraManager_getCameraCharacteristics//由ACameraMetadata接收属性
  ACameraMetadata_getAllTags//获取相机标签
  ACameraMetadata_getConstEntry//解析属性 获知前摄还是背摄，旋转状态等等
  ACameraManager_openCamera //打开一个相机
  ACameraManager_registerAvailabilityCallback //注册相机状态回调
  CameraDevice_createCaptureSession //创建会话
  ACameraCaptureSession_setRepeatingRequest//设置会话请求，会被循环处理
  ACameraCaptureSession_stopRepeating//暂停会话请求
  ACameraCaptureSession_capture//截屏
  ACaptureRequest_setEntry_...//设置相机参数 通过请求传递

  //从ANativeWindow创建会话输出容器与目标
  ANativeWindow_acquire
  ACaptureSessionOutputContainer_create
  ACaptureSessionOutputContainer_add
  ACameraOutputTarget_create
  ACameraDevice_createCaptureRequest
  ACaptureRequest_addTarget
  ```

- ImageReader类
  控制转码，旋转，获取底层数据帧，获取显示到ANativeWindow
  ```cpp
  //主要API
  AImageReader
  AImage
  AImageCropRect
  AImageReader_new //创建
  AImageReader_setImageListener //设置监听器
  AImageReader_getFormat //获取图片格式
  AImageReader_getWindow //get ANativeWindow
  AImageReader_acquireNextImage //获取下一帧 没有帧会被跳过
  AImageReader_acquireLatestImage //获取最新帧 获取后删除 更实时一些
  AImage_getNumberOfPlanes //yuv格式获取plane数
  AImage_getPlaneRowStride //用于解析YUV格式
  AImage_getPlanePixelStride //用于解析YUV格式
  AImage_getPlaneData // 获取plane数据 转码 写文件需要
  AImage_getWidth
  AImage_getHeight
  AImage_getCropRect
  ```

- 对象基本都要手动调用相应方法析构/解注册
  ```cpp
  // 析构/解注册方法
  ACaptureRequest_free
  ACameraOutputTarget_free
  ACaptureSessionOutput_free
  ACaptureSessionOutputContainer_free
  ACameraMetadata_free
  ACameraManager_deleteCameraIdList
  ANativeWindow_release
  ACameraManager_unregisterAvailabilityCallback
  ACameraManager_delete
  ACameraCaptureSession_close
  ```

- 包装了请求结构体
  ```cpp
  struct CaptureRequestInfo {
    ANativeWindow* outputNativeWindow_;//示例项目的输出窗口对象
    ACaptureSessionOutput* sessionOutput_;
    ACameraOutputTarget* target_;
    ACaptureRequest* request_;
    ACameraDevice_request_template template_;//请求flag
    int sessionSequenceId_;
  };
  ```

- 包装了相机结构体
  ```cpp
  // helper classes to hold enumerated camera
  class CameraId {
  public:
    ACameraDevice* device_;
    std::string id_;
    acamera_metadata_enum_android_lens_facing_t facing_;
    bool available_;  // free to use ( no other apps are using
    bool owner_;      // we are the owner of the camera
    explicit CameraId(const char* id)
        : device_(nullptr),
          facing_(ACAMERA_LENS_FACING_FRONT),
          available_(false),
          owner_(false) {
      id_ = id;
    }

    explicit CameraId(void) { CameraId(""); }
  };
  ```
- 其他
  - 有2个`ImageReader`，分别处理yuv(preview)和jpg(capture)数据,在初始化时需要分别获取各自的`ANativeWindow`并各自在创建会话时绑定到会话的输出容器与目标中

  - texture-view 结构类似basic
    ```
    //主要API
    ANativeWindow_fromSurface //从Surface获取ANativeWindow
    ```

#### 总结：

- 主要流程:
  - 添加权限
  - 指定draw与buffer对象
  preview应用于`ANativeWindow`
  可以从`Surface`或者`ANativeWindow_Buffer`获取buffer对象
  - 获取相机ID列表
  - 初始化并打开指定相机
  - 初始化会话并开启请求
  - 取下层图像帧输出到buf显示

- 帧率：
  下层`BufferQueueProducer`显示的帧率为30FPS左右，
  应用层循环取数据draw，频率大概50FPS
  `AImageReader_acquireLatestImage`//实时
  `AImageReader_acquireNextImage`//低端机上会导致preview的fps低
  上层消费者取buf的速度比生产者快，所以帧率是同步的

- 格式：
  - 当前preview格式为`AIMAGE_FORMAT_YUV_420_888`
    snapshot格式为`AIMAGE_FORMAT_JPEG`
    应该能支持其他格式，这边以示例为准并未进一步测试
  - preview保存的YUV数据以NV21方式可以解
    YUV2RGB之后才会输出到buf里面再显示，具体YUV2RGB转换可以参考
    `ImageReader::PresentImage`

- 分辨率：
  ```cpp
  // 参考
  CameraEngine::CreateCamera
  NDKCamera::MatchCaptureSizeRequest

  struct ImageFormat {
    int32_t width;
    int32_t height;

    int32_t format;  // Through out this demo, the format is fixed to
                    // YUV_420 format
  };
  ImageFormat view{0, 0, 0}, capture{0, 0, 0};
  //传输给函数处理进行初始值判断设置
  //获取相机支持的分辨率
  ACameraMetadata_getConstEntry(metadata, ACAMERA_SCALER_AVAILABLE_STREAM_CONFIGURATIONS, &entry));

  //手动设置分辨率 e.g.
  view.width=3584;
  view.height=2240;
  //同步设置接收窗口大小
  ANativeWindow_setBuffersGeometry

  //ImageFormat初始化后传递给ImageReader构造
  AImageReader_new //创建相应分辨率的reader，也可以在此手动指定分辨率但要符合相机支持
  ```

- 双摄目测流程:
  - 分别准备好buffer对象
  - 分别打开相机并初始化
  - 2个ImageReader分别处理相机数据流
  - 创建一个会话并一系列初始化后开启请求

- 注意事项：
  `ACameraCaptureSession`
  这个对象似乎只能创建一个，新建的会close掉前面的


- 测试结果
  晋兴微
  (1280,800) queueBuffer 显示fps=20左右
  (3584,2240) queueBuffer 显示fps=9.75左右
  也就是说由于此设备硬件性能原因，分辨率大，内存CPU等跟不上，HAL生产数据帧的帧率就会降低

- java api 和C++ api性能
  前端窗口显示的大小也会影响实际性能，测试需要控制变量，目前C++ api测试程序前端窗口是满屏的，JAVA api测试程序窗口略小一些。
  总体上来看 关于java和C++ api 的性能——并没有显著区别

- 扩展
    - 关于Camera2有人总结的比较好
    [Android NDK Camera2小结](https://blog.csdn.net/daihuimaozideren/article/details/101235393/)

    - google基于Camera2封装了一层更友好的相机接口CameraX
    [CameraX 官方文档](https://developer.android.google.cn/training/camerax/)

    - 对理解框架有帮助
    [Android Camera2 HAL3 学习文档](https://www.cnblogs.com/ymjun/p/13201363.html)

%accordion% 设备存在问题：消费者消费速度跟不上生产者 %accordion%

(3584,2240) 分辨率下 JAVA api queueBuffer显示帧率20FPS 而应用层显示只有10FPS左右
- 初步怀疑:
  1. 系统性能瓶颈，对高分辨率图像处理不过来，2边API应用层调用的都是`acquireLatestImage`，实时性是比较好的，如果还有性能瓶颈，主要原因是设备性能太差。
  2. 应用层回调while循环做的事情较多,导致循环/回调的FPS小于下层生产者的速度，成为应用层FPS制约的瓶颈之一.

考虑数据出HAL层到应用层之间有没有可能在晋兴微的设备的中间层被衰减处理了，但是小分辨率图测试下，queueBuffer和应用层显示的FPS是同步的，所以，基本可以排除这种情况。

那么更有可能是应用层消费者吃饭速度太慢，太慢的原因可能是上述说的在大分辨率图的情况下回调的FPS跟不上生产者，处理太耗时之类的，或者系统性能瓶颈导致确实处理不过来,后者的可能性更大一些。但是前者需要进行测试排除或优化，检查处理大分辨率图时的耗时情况，或者另起线程处理，回调中不做耗时操作。

queueBufferProducer作为安卓底层,它发出的log,数据是可信的,它生产速度是多少就是多少.
关于为什么queueBufferProducer显示的FPS和应用层实际不一致的情况，很显然原因是因为应用层处理过慢.至于过慢的原因，上面也已经做了说明.

目前cpp api测试正常性能的设备，只要消费者速度能跟上生产者，大分辨率下应用层和底层的preview帧率也是同步的。

综上所述，主要晋兴微的设备自身的性能问题导致FPS上不去

%/accordion%
