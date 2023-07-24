export ROCM_MAJOR_VERSION=5
export ROCM_MINOR_VERSION=5
export ROCM_PATCH_VERSION=1
export ROCM_VERSION=$ROCM_MAJOR_VERSION.$ROCM_MINOR_VERSION.$ROCM_PATCH_VERSION
export ROCM_INSTALL_DIR=/opt/rocm-$ROCM_VERSION
export ROCM_LIBPATCH_VERSION=50501
export ROCM_GIT_DIR=/media/fast/rocm/rocm
export ROCM_BUILD_DIR=/media/fast/rocm/workbuild
#export AMDGPU_TARGETS="gfx1030;gfx1031;gfx1032;gfx1100;gfx1101;gfx1102"
#gfx1032 fails to compile with rocsparse
#gfx1031 fails with composable kernel
export AMDGPU_TARGETS="gfx1030;gfx1100;gfx1101;gfx1102"
export PATH=$ROCM_INSTALL_DIR/bin:$ROCM_INSTALL_DIR/llvm/bin:$ROCM_INSTALL_DIR/hip/bin:$PATH
export DEVICELIBS_ROOT=$ROCM_GIT_DIR/ROCm-Device-Libs
export LD_LIBRARY_PATH=/opt/rocm-$ROCM_VERSION/lib64:/opt/rocm-$ROCM_VERSION/lib:/opt/rocm-$ROCM_VERSION/llvm/lib:$LD_LIBRARY_PATH
export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )