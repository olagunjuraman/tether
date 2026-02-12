# Non-interactive CMake config for MLC-LLM (Vulkan + CPU).
# Used by Docker build and CI. See cmake/gen_cmake_config.py for options.
set(TVM_SOURCE_DIR "3rdparty/tvm")
set(CMAKE_BUILD_TYPE "RelWithDebInfo")
set(USE_CUDA OFF)
set(USE_CUTLASS OFF)
set(USE_CUBLAS OFF)
set(USE_ROCm OFF)
set(USE_VULKAN ON)
set(USE_METAL OFF)
set(USE_OPENCL OFF)
set(USE_OPENCL_ENABLE_HOST_PTR OFF)
