# Rocm Compile Script

This is tested on gentoo on July 20th, 2023 with rocm 5.5.1

Steps:

1. git clone --recurse-submodules https://github.com/glop102/glop-rocm-compile-script.git
2. cd rocm
3. ../repo sync  # this will grab all the source files
4. cd ..
5. Edit the env.sh file as you see fit
6. ./build.sh   # and then hope and pray. A couple steps in the build script have comments that might help you fix any problems you run into


To use the enviroment once built, then add it to your path, eg 
> PATH=/opt/rocm/bin:/opt/rocm/llvm/bin:/opt/rocm/hip:$PATH LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
