# CUDA基础与实践

[toc]
<!--toc-->

准备进行GPU开发，需要阅读相关书籍，熟悉官方文档，相关加速库内容等等
故而对学习过程中的相关知识/信息点进行摘要。

## 简述最新CUDA 12.0


- 支持改进后的CUDA动态并行API
- CUDA图形API增强
- 通过`nvJitLink`正式支持即时链接优化(JIT LTO)
- 支持GCC 12主机编译器
- 不完全支持C++20
    - 暂不支持module
    - 协程仅在主机代码中受支持
    - 三向比较运算符`<=>`需要显示调用
    - 支持C++20的主机编译器：GCC 10+，Clang 11+, MSVC 2022
- CUDA堆栈默认不开启延迟加载，可以通过环境变量开启`CUDA_MODULE_LOADING=LAZY`
- 

参考：[CUDA12.0版本介绍](https://developer.nvidia.com/blog/cuda-toolkit-12-0-released-for-general-availability/)

## GPU加速库
- **cuBLAS** :基本线性代数库
- **cuBLASLt** :轻量级cuBLAS
- **cuFFT** :快速傅里叶变换库
- **cuFFTMp** :multi-process版cuFFT
- **cuRAND** :随机数生成器
- **MathDx** :标准数学函数库 `#include math.h`
- **cuSOLVER** :密集和稀疏直接求解器
- **cuSOLVERMp** :multi-process版cuSOLVER
- **cuSPARSE** :用于稀疏矩阵的BLAS
- **cuSPARSELt**  :轻量级cuSPARSE
- **cuTENSOR** :张量线性代数库
- **cuTENSORMg** :multi-gpu版cuTENSOR
- **NPP** :图像，视频和信号处理函数库
- **nvJPEG** :JPEG编解码器
- **nvJPEG2000** :JPEG2000编解码器
- **nvTIFF** :TIFF编解码器
- **AmgX** :用于模拟和隐式非结构化方法的线性求解器
- **Thrust** :并行算法库
- **Video Codec** :视频编解码器
- **Optival Flow** :光流计算
- **nvSHMEM** :内存管理器 多GPU统一全局内存
- **cuDNN** :DNN加速原语库
- **TensorRT** :用于生产部署的高性能深度学习推理优化器和运行时
- **Riva** :AI语音SDK
- **DeepStream** :AI视频理解和多传感器处理的实时流分析工具包
- **DALI** :用于解码和增强图像和视频以加速AI模型训练
- ...

参考： 
[https://docs.nvidia.com/](https://docs.nvidia.com/)
[CUDA库文档](https://docs.nvidia.com/cuda-libraries/)
