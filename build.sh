#!/bin/bash
set -e
source env.sh

#Adapted from https://github.com/xuhuisheng/rocm-build/tree/master

COMMAND=-1
if [ $# == 1 ] ; then
    COMMAND=$1
fi

case $COMMAND in
"setup" | -1)
    mkdir -p ${ROCM_INSTALL_DIR}
    ;&
"core" | 0)
    mkdir -p $ROCM_BUILD_DIR/rocm-core
    pushd $ROCM_BUILD_DIR/rocm-core
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DPROJECT_VERSION_MAJOR=${ROCM_MAJOR_VERSION} -DPROJECT_VERSION_MINOR=${ROCM_MINOR_VERSION} -DPROJECT_VERSION_PATCH=${ROCM_PATCH_VERSION} -DROCM_PATCH_VERSION=${ROCM_LIBPATCH_VERSION} \
        -DROCM_VERSION=${ROCM_VERSION} \
        ${ROCM_GIT_DIR}/rocm-core
    cmake --build .
    cmake --install .
    popd
    ;&
"llvm-bootstrap" | 1)
    mkdir -p $ROCM_BUILD_DIR/llvm-project-bootstrap
    pushd $ROCM_BUILD_DIR/llvm-project-bootstrap
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/llvm/ -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_ASSERTIONS=1 \
        -DLLVM_TARGETS_TO_BUILD="AMDGPU;X86" -DLLVM_ENABLE_PROJECTS="lld;clang;flang" \
        -DPROJECT_VERSION_MAJOR=${ROCM_MAJOR_VERSION} -DPROJECT_VERSION_MINOR=${ROCM_MINOR_VERSION} -DPROJECT_VERSION_PATCH=${ROCM_PATCH_VERSION} \
        -G Ninja \
        ${ROCM_GIT_DIR}/llvm-project/llvm
    #-DLIBOMP_HAVE_QUAD_PRECISION=False
    cmake --build .
    cmake --install .
    popd
    ;&
"roct-thunk" | 2)
    mkdir -p $ROCM_BUILD_DIR/ROCT-Thunk-Interface
    pushd $ROCM_BUILD_DIR/ROCT-Thunk-Interface
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/ROCT-Thunk-Interface
    cmake --build .
    cmake --install .
    popd
    ;&
"rocm-cmake" | 3)
    mkdir -p $ROCM_BUILD_DIR/rocm-cmake
    pushd $ROCM_BUILD_DIR/rocm-cmake
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocm-cmake
    cmake --build .
    cmake --install .
    popd
    ;&
"rocm-device-libs" | 4)
    mkdir -p $ROCM_BUILD_DIR/ROCm-Device-Libs
    pushd $ROCM_BUILD_DIR/ROCm-Device-Libs
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/ROCm-Device-Libs
    cmake --build .
    cmake --install .
    popd
    ;&
"rocr-runtime" | 5)
    mkdir -p $ROCM_BUILD_DIR/ROCR-Runtime
    pushd $ROCM_BUILD_DIR/ROCR-Runtime
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/ROCR-Runtime/src
    cmake --build .
    cmake --install .
    popd
    ;&
"rocminfo" | 6)
    mkdir -p $ROCM_BUILD_DIR/rocminfo
    pushd $ROCM_BUILD_DIR/rocminfo
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocminfo
    cmake --build .
    cmake --install .
    popd
    ;&
"compiler-support" | 7)
    mkdir -p $ROCM_BUILD_DIR/compiler-support
    pushd $ROCM_BUILD_DIR/compiler-support
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/ROCm-CompilerSupport/lib/comgr
    cmake --build .
    cmake --install .
    popd
    ;&
"llvm" | 8)
    # The cmake files apparently are not quite right and so look in the wrong places for the device libs when compiling openmp
    sed -i "s/{DEVICELIBS_ROOT/{LIBOMP_DEVICELIBS_ROOT/g" $ROCM_GIT_DIR/llvm-project/openmp/libomptarget/hostrpc/CMakeLists.txt
    sed -i "s/ DEVICELIBS_ROOT/ LIBOMP_DEVICELIBS_ROOT/g" $ROCM_GIT_DIR/llvm-project/openmp/libomptarget/hostrpc/CMakeLists.txt
    # Also openmp apparently pulls in gfx1010 but some lower lib doesn't have support for it
    sed -i "s/gfx90c gfx940 gfx1010 gfx1030 gfx1031/gfx90c gfx940 gfx1030 gfx1031/g" $ROCM_GIT_DIR/llvm-project/openmp/libomptarget/DeviceRTL/CMakeLists.txt

    mkdir -p $ROCM_BUILD_DIR/llvm-project
    pushd $ROCM_BUILD_DIR/llvm-project
    FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/llvm/ -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_ASSERTIONS=1 \
        -DLLVM_TARGETS_TO_BUILD="AMDGPU;X86" -DLLVM_ENABLE_PROJECTS="lld;clang;flang" \
        -DLLVM_ENABLE_RUNTIMES="openmp;compiler-rt" -DLIBOMP_DEVICELIBS_ROOT=${ROCM_GIT_DIR}/ROCm-Device-Libs \
        -DPROJECT_VERSION_MAJOR=${ROCM_MAJOR_VERSION} -DPROJECT_VERSION_MINOR=${ROCM_MINOR_VERSION} -DPROJECT_VERSION_PATCH=${ROCM_PATCH_VERSION} \
        -G Ninja \
        ${ROCM_GIT_DIR}/llvm-project/llvm
	# -DLLVM_EXTERNAL_PROJECTS="flang" \
	# -DLLVM_EXTERNAL_FLANG_SOURCE_DIR="${ROCM_GIT_DIR}/openmp-extras/flang/" \
    #-DLIBOMP_HAVE_QUAD_PRECISION=False
    cmake --build .
    cmake --install .
    popd
    #hipcc tries to find things in lib and not in lib64 for some reason, so lets just fix that real quick
    if [ ! -e ${ROCM_INSTALL_DIR}/lib ] ; then
        ln -s ${ROCM_INSTALL_DIR}/lib64 ${ROCM_INSTALL_DIR}/lib
    fi
    ;&
"flang-extras" | 9)
    mkdir -p $ROCM_BUILD_DIR/openmpextras-flangmain
    pushd $ROCM_BUILD_DIR/openmpextras-flangmain
    CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/llvm/ -DCMAKE_BUILD_TYPE=Release \
        -DFLANG_LIBOMP=${ROCM_INSTALL_DIR}/llvm/lib/libomp.so \
        -Wno-dev \
        ${ROCM_GIT_DIR}/openmp-extras/flang
    cmake --build . -v
    cmake --install .
    popd
    ;&
"libpgmath" | 10)
    mkdir -p $ROCM_BUILD_DIR/openmpextras-pgmath
    pushd $ROCM_BUILD_DIR/openmpextras-pgmath
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/llvm/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/openmp-extras/flang/runtime/libpgmath
    cmake --build . -v
    cmake --install .
    #For some reason, they don't copy the required files for other things to compile with into the incldue directory
    cp include/* ${ROCM_INSTALL_DIR}/llvm/include/
    popd
    ;&
"flang-runtime" | 11)
    mkdir -p $ROCM_BUILD_DIR/openmpextras-flangruntime
    pushd $ROCM_BUILD_DIR/openmpextras-flangruntime
    CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/llvm/ -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_INSTALL_RUNTIME=1 -DFLANG_LIBOMP=${ROCM_INSTALL_DIR}/llvm/lib/libomp.so \
        -Wno-dev \
        ${ROCM_GIT_DIR}/openmp-extras/flang
    cmake --build . -v
    cmake --install .
    popd
    ;&
"hip" | 12)
    mkdir -p $ROCM_BUILD_DIR/hip
    pushd $ROCM_BUILD_DIR/hip
    CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DOFFLOAD_ARCH_STR="--offload-arch=$AMDGPU_TARGETS" \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -DPROJECT_VERSION_MAJOR=${ROCM_MAJOR_VERSION} -DPROJECT_VERSION_MINOR=${ROCM_MINOR_VERSION} -DPROJECT_VERSION_PATCH=${ROCM_PATCH_VERSION} -DROCM_PATCH_VERSION=${ROCM_LIBPATCH_VERSION} \
        -DHIP_COMMON_DIR="${ROCM_GIT_DIR}/HIP" -DAMD_OPENCL_PATH="${ROCM_GIT_DIR}/ROCm-OpenCL-Runtime" -DROCCLR_PATH="${ROCM_GIT_DIR}/ROCclr" \
        -G Ninja \
        ${ROCM_GIT_DIR}/hipamd
    cmake --build .
    cmake --install .
    popd
    ;&
"rocfft" | 13)
    mkdir -p $ROCM_BUILD_DIR/rocfft
    pushd $ROCM_BUILD_DIR/rocfft
    CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocFFT
    cmake --build . -v
    cmake --install .
    popd
    ;&
"rocblas" | 14)
    mkdir -p $ROCM_BUILD_DIR/rocblas
    pushd $ROCM_BUILD_DIR/rocblas
    CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
		-DROCM_PATH=$ROCM_INSTALL_DIR \
		-DTensile_LOGIC=asm_full -DTensile_ARCHITECTURE=all -DTensile_CODE_OBJECT_VERSION=V5 \
		-DTensile_LIBRARY_FORMAT=yaml -DRUN_HEADER_TESTING=OFF -DTensile_COMPILER=hipcc \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocBLAS
    cmake --build . -v
    cmake --install .
    popd
    ;&
"rocprim" | 15)
    mkdir -p $ROCM_BUILD_DIR/rocprim
    pushd $ROCM_BUILD_DIR/rocprim
    CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
		-DBUILD_BENCHMARK=OFF -DBUILD_TEST=OFF \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocPRIM
    cmake --build . -v
    cmake --install .
    popd
    ;&
"rocrand" | 16)
	pushd $ROCM_GIT_DIR/rocRAND
	git submodule update --init
	popd
    mkdir -p $ROCM_BUILD_DIR/rocrand
    pushd $ROCM_BUILD_DIR/rocrand
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_PREFIX_PATH=$ROCM_INSTALL_DIR:$ROCM_INSTALL_DIR/llvm \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocRAND
    cmake --build . -v
    cmake --install .
    popd
    ;&
"rocsparse" | 17)
    mkdir -p $ROCM_BUILD_DIR/rocsparse
    pushd $ROCM_BUILD_DIR/rocsparse
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
		-DBUILD_CLIENTS_SAMPLES=OFF -DROCM_PATH=$ROCM_INSTALL_DIR \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocSPARSE
    # -DCMAKE_Fortran_FLAGS=-I/media/fast/rocm/workbuild/openmpextras-flangruntime/include/\ -I${ROCM_INSTALL_DIR}/llvm/include/flang \
    cmake --build . -v
    cmake --install .
    ;&
"hipsparse" | 18)
    mkdir -p $ROCM_BUILD_DIR/hipsparse
    pushd $ROCM_BUILD_DIR/hipsparse
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
		-DROCM_PATH=$ROCM_INSTALL_DIR -DBUILD_CUDA=OFF \
        -G Ninja \
        ${ROCM_GIT_DIR}/hipSPARSE
    cmake --build . -v
    cmake --install .
    popd
    ;&
"rocm-smi-lib" | 19)
    mkdir -p $ROCM_BUILD_DIR/rocm-smi-lib
    pushd $ROCM_BUILD_DIR/rocm-smi-lib
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocm_smi_lib
    cmake --build . -v
    cmake --install .
    popd
    ;&
# "rccl" | 20)
#     mkdir -p $ROCM_BUILD_DIR/rccl
#     pushd $ROCM_BUILD_DIR/rccl
#     CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#         -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
#         -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
# 		-DROCM_PATH=$ROCM_INSTALL_DIR -DBUILD_TESTS=OFF \
#         -G Ninja \
#         ${ROCM_GIT_DIR}/rccl
#     cmake --build . -v
#     cmake --install .
#     popd
#     ;&
"hipfft" | 21)
    mkdir -p $ROCM_BUILD_DIR/hipfft
    pushd $ROCM_BUILD_DIR/hipfft
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/ -DCMAKE_BUILD_TYPE=Release \
		-DROCM_PATH=$ROCM_INSTALL_DIR -DHIP_ROOT_DIR=$ROCM_INSTALL_DIR \
        -G Ninja \
        ${ROCM_GIT_DIR}/hipFFT
    cmake --build . -v
    cmake --install .
    popd
    ;&
"rocm-opencl-runtime" | 22)
    pushd ${ROCM_GIT_DIR}/ROCclr
        git apply ${SCRIPT_DIR}/ROCclr.patch || true
    popd

    mkdir -p $ROCM_BUILD_DIR/rocm-opencl-runtime
    pushd $ROCM_BUILD_DIR/rocm-opencl-runtime
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR}/opencl -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=$ROCM_INSTALL_DIR -Dhsa-runtime64_DIR=$ROCM_INSTALL_DIR/lib/cmake/hsa-runtime64 \
		-DROCM_PATH=$ROCM_INSTALL_DIR -DROCCLR_PATH=${ROCM_GIT_DIR}/ROCclr \
        -G Ninja \
        ${ROCM_GIT_DIR}/ROCm-OpenCL-Runtime
    cmake --build . -v
    cmake --install .
    popd
    ;&
"clang-ocl" | 23)
    mkdir -p $ROCM_BUILD_DIR/clang-ocl
    pushd $ROCM_BUILD_DIR/clang-ocl
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=$ROCM_INSTALL_DIR \
        -G Ninja \
        ${ROCM_GIT_DIR}/clang-ocl
    cmake --build . -v
    cmake --install .
    popd
    ;&
# "rocprofiler" | 24)
#     mkdir -p $ROCM_BUILD_DIR/rocprofiler
#     pushd $ROCM_BUILD_DIR/rocprofiler
#     CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#         -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
#         -DCMAKE_PREFIX_PATH=$ROCM_INSTALL_DIR \
#         -DPROF_API_HEADER_PATH=$ROCM_GIT_DIR/roctracer/inc/ext/ \
#         -G Ninja \
#         ${ROCM_GIT_DIR}/rocprofiler
#     cmake --build . -v
#     cmake --install .
#     popd
#     ;&
# "roctracer" | 25)
#     mkdir -p $ROCM_BUILD_DIR/roctracer
#     pushd $ROCM_BUILD_DIR/roctracer
#     CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#         -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
#         -DCMAKE_PREFIX_PATH=$ROCM_INSTALL_DIR \
#         -DPROF_API_HEADER_PATH=$ROCM_GIT_DIR/roctracer/inc/ext/ \
#         -G Ninja \
#         ${ROCM_GIT_DIR}/roctracer
#     cmake --build . -v
#     cmake --install .
#     popd
#     ;&
"half" | 26)
    mkdir -p $ROCM_BUILD_DIR/half
    pushd $ROCM_BUILD_DIR/half
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=$ROCM_INSTALL_DIR \
        -G Ninja \
        ${ROCM_GIT_DIR}/half
    cmake --build . -v
    cmake --install .
    popd
    ;&
"libbost" | 27)
    echo;echo
    echo "Your system may or may not have static libboost libraries."
    echo "If you do not have static libboost available, then I recomend either getting you package manager to install it or to compile libboost into the rocm prefix"
    echo "eg download and untar boost, run './bootstrap --prefix=/opt/rocm-VERSION' and then './b2 cxxflags=-fPIC cflags=-fPIC install'"
    echo;echo
    ;&
"composable-kernel" | 28)
    if [ ! -e ${ROCM_GIT_DIR}/composable_kernel ] ; then
        pushd ${ROCM_GIT_DIR}
        git clone https://github.com/ROCmSoftwarePlatform/composable_kernel
        popd
    fi

    mkdir -p $ROCM_BUILD_DIR/composable-kernel
    pushd $ROCM_BUILD_DIR/composable-kernel
    #CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -DCMAKE_PREFIX_PATH=/opt/rocm -DINSTANCES_ONLY=true \
        -G Ninja \
        ${ROCM_GIT_DIR}/composable_kernel
    cmake --build . -v
    cmake --install .
    popd
    ;&
"miopen" | 29)
    mkdir -p $ROCM_BUILD_DIR/miopen
    pushd $ROCM_BUILD_DIR/miopen
    #CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS -DMIOPEN_USE_MLIR=0 \
        -G Ninja \
        ${ROCM_GIT_DIR}/MIOpen
    cmake --build . -v
    cmake --install .
    popd
    ;&
# "rocdbgapi" | 30)
#     mkdir -p $ROCM_BUILD_DIR/rocdbgapi
#     pushd $ROCM_BUILD_DIR/rocdbgapi
#     #CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#     CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#         -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
#         -G Ninja \
#         ${ROCM_GIT_DIR}/ROCdbgapi
#     cmake --build . -v
#     cmake --install .
#     popd
#     ;&
# "rocgdb" | 31)
#     mkdir -p $ROCM_BUILD_DIR/rocgdb
#     pushd $ROCM_BUILD_DIR/rocgdb
#     #CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#     CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang \
#         $ROCM_GIT_DIR/ROCgdb/configure --program-prefix=roc \
#         --enable-64-bit-bfd --enable-targets="x86_64-linux-gnu,amdgcn-amd-amdhsa" \
#         --disable-ld --disable-gas --disable-gdbserver --disable-sim --enable-tui \
#         --disable-gdbtk --disable-shared --with-expat --with-system-zlib \
#         --without-guile --with-babeltrace --with-lzma --with-python=python3
#     cmake --build . -v
#     cmake --install .
#     popd
#     ;&
"rocsolver" | 32)
    mkdir -p $ROCM_BUILD_DIR/rocsolver
    pushd $ROCM_BUILD_DIR/rocsolver
    # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocSOLVER
    cmake --build . -v
    cmake --install .
    popd
    ;&
"rocthrust" | 33)
    mkdir -p $ROCM_BUILD_DIR/rocthrust
    pushd $ROCM_BUILD_DIR/rocthrust
    # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocThrust
    cmake --build . -v
    cmake --install .
    popd
    ;&
"hipblas" | 34)
    mkdir -p $ROCM_BUILD_DIR/hipblas
    pushd $ROCM_BUILD_DIR/hipblas
    # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -G Ninja \
        ${ROCM_GIT_DIR}/hipBLAS
    cmake --build . -v
    cmake --install .
    popd
    ;&
"rocalution" | 35)
    mkdir -p $ROCM_BUILD_DIR/rocalution
    pushd $ROCM_BUILD_DIR/rocalution
    # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS -DHIP_CLANG_PATH=$ROCM_INSTALL_DIR/llvm/bin/ \
        -DSUPPORT_HIP=ON -DROCM_PATH=$ROCM_INSTALL_DIR -DHIP_ROOT_DIR=${ROCM_INSTALL_DIR} \
        -G Ninja \
        ${ROCM_GIT_DIR}/rocALUTION
    cmake --build . -v
    cmake --install .
    popd
    ;&
"hipcub" | 36)
    mkdir -p $ROCM_BUILD_DIR/hipcub
    pushd $ROCM_BUILD_DIR/hipcub
    # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -G Ninja \
        ${ROCM_GIT_DIR}/hipCUB
    cmake --build . -v
    cmake --install .
    popd
    ;&
"hipsolver" | 37)
    mkdir -p $ROCM_BUILD_DIR/hipsolver
    pushd $ROCM_BUILD_DIR/hipsolver
    # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -G Ninja \
        ${ROCM_GIT_DIR}/hipSOLVER
    cmake --build . -v
    cmake --install .
    popd
    ;&
# "amdmigraphx" | 38)
#     I am having a lot of truble with the msgpackc-cxx linking thing and i really don't think i care about this package

#     mkdir -p $ROCM_BUILD_DIR/amdmigraphx
#     pushd $ROCM_BUILD_DIR/amdmigraphx
#     #something is wrong with the cmake logic for stripping out comments, and so it errors on the copyright headers. Just remove them and it is fine
#     # sed -i "/^#.*/d" $ROCM_GIT_DIR/AMDMIGraphX/dev-requirements.txt $ROCM_GIT_DIR/AMDMIGraphX/requirements.txt
#     # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#     #     -P $ROCM_GIT_DIR/AMDMIGraphX/install_deps.cmake --prefix ${ROCM_INSTALL_DIR}
#     #ALRIGHT, fine, I give up! Go into the two requirments.txt file and check that you have the various packages installed on your system.
#     #It is likely that msgpack (not the python one) and protobuf are the ones you will need to install for this to work
#     #gentoo, those would be dev-cpp/msgpack-cxx and dev-libs/protobuf

#     #The package is called msgpack-cxx, not msgpack, so lets fix that
#     sed -i "s/find_package(msgpack REQUIRED)/find_package(msgpack-cxx REQUIRED)/g" ${ROCM_GIT_DIR}/AMDMIGraphX/src/CMakeLists.txt

#     # CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#     CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#         -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
#         -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
#         -G Ninja \
#         ${ROCM_GIT_DIR}/AMDMIGraphX
#     cmake --build . -v
#     cmake --install .
#     popd
#     ;&
# "dkms-kernel-driver" | 39)
#     Skipping this since you should be able to use the kerrnel driver shipping in the mainline kernel
#     mkdir -p $ROCM_BUILD_DIR/dkms-kernel-driver
#     pushd $ROCM_BUILD_DIR/dkms-kernel-driver
#     # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#     CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
#         -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
#         -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
#         -G Ninja \
#         ${ROCM_GIT_DIR}/ROCK-Kernel-Driver
#     cmake --build . -v
#     cmake --install .
#     popd
#     ;&
"hipfort" | 40)
    mkdir -p $ROCM_BUILD_DIR/hipfort
    pushd $ROCM_BUILD_DIR/hipfort
    # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    # CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    # This apparently needs gfortran and not flang to compile
    cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
        -G Ninja \
        ${ROCM_GIT_DIR}/hipfort
    cmake --build . -v
    cmake --install .
    popd
    ;&
"hipify" | 41)
    mkdir -p $ROCM_BUILD_DIR/hipify
    pushd $ROCM_BUILD_DIR/hipify
    #apparently they have left some in-progress dev work in the defines or something and are not using the new clang path if we are using clang16
    sed -i "s/ && SWDEV_375013//g" ${ROCM_GIT_DIR}/HIPIFY/src/HipifyAction.cpp

    # CC=$ROCM_INSTALL_DIR/llvm/bin/clang CXX=$ROCM_INSTALL_DIR/llvm/bin/clang++ FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
    CC=$ROCM_INSTALL_DIR/hip/bin/hipcc CXX=$ROCM_INSTALL_DIR/hip/bin/hipcc FC=${ROCM_INSTALL_DIR}/llvm/bin/flang cmake \
        -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_DIR} -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=$ROCM_INSTALL_DIR/llvm/ \
        -G Ninja \
        ${ROCM_GIT_DIR}/HIPIFY
    cmake --build . -v
    cmake --install .
    popd
    ;;
*)
    echo "Unkown step to start at: $COMMAND"
    ;;
esac
