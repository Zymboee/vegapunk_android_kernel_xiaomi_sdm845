#!/bin/sh

# Some general variables
PHONE="beryllium"
ARCH="arm64"
SUBARCH="arm64"
DEFCONFIG=punk_defconfig
#DEFCONFIG=beryllium_defconfig

# AOSP Clang directory (adjust to your setup)
CLANGDIR="/root/aosp-clang"

# Outputs
rm -rf out
rm -rf PUNK/

mkdir out

mkdir PUNK/
mkdir PUNK/SE-old
mkdir PUNK/NSE-old
mkdir PUNK/SE-new
mkdir PUNK/NSE-new

# Export shits
export KBUILD_BUILD_USER=Zymboe
export KBUILD_BUILD_HOST=SSG
export PATH="${CLANGDIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${CLANGDIR}/lib"   # opsional, amankan

# Speed up build process
MAKE="./makeparallel"

# Basic build function (unified, full LLVM + AOSP cross compilers)
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

Build () {
make -j$(nproc --all) O=out LLVM=1 LLVM_IAS=1 \
ARCH=${ARCH} \
CC=clang \
LD=ld.lld \
AR=llvm-ar \
AS=llvm-as \
NM=llvm-nm \
STRIP=llvm-strip \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
READELF=llvm-readelf \
HOSTCC=clang \
HOSTCXX=clang++ \
HOSTAR=llvm-ar \
HOSTLD=ld.lld \
CROSS_COMPILE=aarch64-linux-android- \
CROSS_COMPILE_ARM32=arm-linux-androideabi- \
KBUILD_COMPILER_STRING="AOSP Clang"
}

# Make defconfig
make O=out ARCH=${ARCH} ${DEFCONFIG}
if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Made ${DEFCONFIG}"
fi

# Build starts here - now always use unified Build
#Start with SE-old
cp firmware/touch_fw_variant/9.1.24/* firmware/
cp arch/arm64/boot/dts/qcom/SE_NSE/SE/* arch/arm64/boot/dts/qcom/
Build

if [ $? -ne 0 ]
then
    echo "Build failed"
    rm -rf out/outputs/${PHONE}/*
else
    echo "Build succesful"
    cp out/arch/arm64/boot/Image.gz-dtb PUNK/SE-old/Image.gz-dtb

    #NSE-old
    cp arch/arm64/boot/dts/qcom/SE_NSE/NSE/* arch/arm64/boot/dts/qcom/
    Build
    if [ $? -ne 0 ]
    then
        echo "Build failed"
        rm -rf out/outputs/${PHONE}/NSE-old/*
    else
        echo "Build succesful"
        cp out/arch/arm64/boot/Image.gz-dtb PUNK/NSE-old/Image.gz-dtb

        #SE-new
        cp firmware/touch_fw_variant/10.3.7/* firmware/
        cp arch/arm64/boot/dts/qcom/SE_NSE/SE/* arch/arm64/boot/dts/qcom/
        Build
        if [ $? -ne 0 ]
        then
            echo "Build failed"
            rm -rf out/outputs/${PHONE}/SE-new/*
        else
            echo "Build succesful"
            cp out/arch/arm64/boot/Image.gz-dtb PUNK/SE-new/Image.gz-dtb

            #NSE-new
            cp arch/arm64/boot/dts/qcom/SE_NSE/NSE/* arch/arm64/boot/dts/qcom/
            Build
            if [ $? -ne 0 ]
            then
                echo "Build failed"
                rm -rf out/outputs/${PHONE}/NSE-new/*
            else
                echo "Build succesful"
                cp out/arch/arm64/boot/Image.gz-dtb PUNK/NSE-new/Image.gz-dtb
            fi
        fi
    fi
fi

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"

./script.sh 2>&1 | tee -a out/compile.log
