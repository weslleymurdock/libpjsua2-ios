#!/bin/bash
CUR_DIR="$(pwd)"
BASE_DIR="/home/runner/work/libpjsua2/libpjsua2"
DOWNLOAD_DIR="$BASEDIR/external"
BUILD_DIR="$BASEDIR/output"

NDK_VERSION=r21e 
NDK_DIR_NAME="android-ndk-$NDK_VERSION"
CMD_TOOLS_VERSION=8512546
SDK_DIR_NAME="android-sdk-linux"
CMD_TOOLS="cmdline-tools"
CMD_TOOLS_DIR_NAME="latest"

PJSIP_BUILD_OUT_PATH="$BUILD_DIR/pjsip-build-output"

# The generated java bindings and .so lib are placed under different location based on pjsip version
# >= 2.11 -> "pjsua2" (default)
# >= 2.4 -> "app"
PJSIP_GENERATED_ROOT_DIR_NAME="pjsua2" 
SWIG_BUILD_OUT_PATH="$BUILD_DIR/swig-build-output"

OPENSSL_DIR_NAME="openssl"
OPENSSL_BUILD_OUT_PATH="$BUILD_DIR/openssl-build-output"
OPENSSL_TARGET_NDK_LEVEL=21

OPENH264_DIR_NAME="openh264-$OPENH264_VERSION"
 
OPENH264_BUILD_OUT_PATH="$BUILD_DIR/openh264-build-output"
OPENH264_TARGET_NDK_LEVEL=21
OPUS_BUILD_OUT_PATH="$BUILD_DIR/opus-build-output" 

TARGET_ARCHS=("armeabi-v7a" "x86" "arm64-v8a" "x86_64") 
SETUP_ANDROID_APIS=("21")
ANDROID_BUILD_TOOLS="30.0.3" 
TARGET_ANDROID_API=21 

BASE_FOLDER=$DOWNLOAD_DIR

PJSIP_BASE_PATH="${BASE_FOLDER}/pjproject"
PJSIP_TMP_PATH="/tmp/pjsip"
CONFIG_SITE_PATH="${PJSIP_BASE_PATH}/pjlib/include/pj/config_site.h"
PJSUA_BASE_DIR="${PJSIP_TMP_PATH}/pjsip-apps/src/swig"
PJSUA_GENERATED_SRC_DIR="${PJSUA_BASE_DIR}/java/android/$PJSIP_GENERATED_ROOT_DIR_NAME/src/main/java/"
PJSUA_GENERATED_SO_PATH="${PJSUA_BASE_DIR}/java/android/$PJSIP_GENERATED_ROOT_DIR_NAME/src/main/jniLibs"
FINAL_BUILD_DIR=$PJSIP_BUILD_OUT_PATH
FINAL_BUILD_LIB="${FINAL_BUILD_DIR}/lib"
FINAL_BUILD_LOGS="${FINAL_BUILD_DIR}/logs"

export ANDROID_NDK_ROOT="${BASE_FOLDER}/${NDK_DIR_NAME}"
export PATH="$ANDROID_NDK_ROOT:$PATH" 
export NDK_CFLAGS="-g -O2" 

NDK_PATH="$DOWNLOAD_DIR/${NDK_DIR_NAME}"
OPUS_PATH="$DOWNLOAD_DIR/${OPUS_DIR_NAME}"
OPUS_LIB_PATH="${OPUS_BUILD_OUT_PATH}/libs"
OPUS_LOG_PATH="${OPUS_BUILD_OUT_PATH}/logs"

OPUS_LIB_BUILD_PATH="$OPUS_PATH/obj/local"
OPUS_LIB_HEADERS_PATH="$OPUS_PATH/include"


function initialH264Setup {
    NDK_PATH="$DOWNLOAD_DIR/$NDK_DIR_NAME"
    SDK_TOOLS_PATH="$DOWNLOAD_DIR/${SDK_DIR_NAME}"/tools
    OPENH264_SRC_PATH="$DOWNLOAD_DIR/${OPENH264_DIR_NAME}"
    OPENH264_TMP_DIR="/tmp/openh264"
}

function setupH264PathsAndExports {
    LIB_PATH="${OPENH264_BUILD_OUT_PATH}/libs"
    LOG_PATH="${OPENH264_BUILD_OUT_PATH}/logs"

    export ANDROID_NDK_HOME=$NDK_PATH
    export ANDROID_HOME=$DOWNLOAD_DIR/${SDK_DIR_NAME}

    export PATH=${SDK_TOOLS_PATH}:$PATH
}

function clearBuildDirectory {
    rm -rf "${OPENH264_BUILD_OUT_PATH}"
    mkdir -p "${LIB_PATH}"
    mkdir -p "${LOG_PATH}"
}

function clearH264TmpAndInitDirectory {
    rm -rf "${OPENH264_TMP_DIR}"
    mkdir -p "${OPENH264_TMP_DIR}"
    cd ${OPENH264_SRC_PATH}
    cp -r * ${OPENH264_TMP_DIR}
    cd ${OPENH264_TMP_DIR}
    mkdir -p "$BUILD_DIR"
    mkdir -p "${LIB_PATH}/${arch}"
    mkdir -p "${LOG_PATH}"
}

function finalizeH264Args {
    arch=$1
    if [ "$arch" == "armeabi" ]
    then
        ARGS="${ARGS}arm APP_ABI=armeabi"
    elif [ "$arch" == "armeabi-v7a" ]
    then
        ARGS="${ARGS}arm"
    elif [ "$arch" == "x86" ]
    then
        ARGS="${ARGS}x86 ENABLEPIC=Yes"
    elif [ "$arch" == "x86_64" ]
    then
        ARGS="${ARGS}x86_64"
    elif [ "$arch" == "arm64-v8a" ]
    then
        ARGS="${ARGS}arm64"
    else
        echo "Unsupported target ABI: $arch"
        exit 1
    fi
}


function setConfigSite {
    echo "Creating config site file for Android ..."
    echo "#define PJ_CONFIG_ANDROID 1" > "$CONFIG_SITE_PATH"
    echo "#define PJMEDIA_HAS_G7221_CODEC 1" >> "$CONFIG_SITE_PATH"
    echo "#define PJMEDIA_AUDIO_DEV_HAS_ANDROID_JNI 0" >> "$CONFIG_SITE_PATH"
    echo "#define PJMEDIA_AUDIO_DEV_HAS_OPENSL 1" >> "$CONFIG_SITE_PATH"
    echo "#define PJSIP_AUTH_AUTO_SEND_NEXT 0" >> "$CONFIG_SITE_PATH"
    echo "#define PJMEDIA_HAS_OPUS_CODEC 1" >> "$CONFIG_SITE_PATH"

    # Check the README in patches README.md for more info
    if [ "${USE_FIXED_CALLID}" == "1" ]
    then
        echo "Changing PJSIP_MAX_URL_SIZE to 512"
        echo "#define PJSIP_MAX_URL_SIZE 512" >> "$CONFIG_SITE_PATH"
    fi

    # If you are compiling pjsip with openssl you will likely use srtp
    # in such scenario it might happen that the sdp contains srtp info
    # thus the whole packet will likely exceed the default 4000 bytes.
    # We are here increasing that limit to 6000 bytes.
    if [ "${ENABLE_OPENSSL}" == "1" ]
    then
        echo "Changing PJSIP_MAX_PKT_LEN to 6000"
        echo "#define PJSIP_MAX_PKT_LEN 6000" >> "$CONFIG_SITE_PATH"
    else
        echo "You have not enabled OpenSSL in config_site"
    fi

    if [ "${ENABLE_IPV6}" == "1" ]
    then
        echo "Enabling IPV6 in config_site"
        echo "#define PJ_HAS_IPV6 1" >> "$CONFIG_SITE_PATH"
    else
        echo "You have not enabled IPV6 in config_site"
    fi

    if [ "${ENABLE_BCG729}" == "1" ]
    then
        echo "Enabling BCG729 in config_site"
        echo "#define PJMEDIA_HAS_BCG729 1" >> "$CONFIG_SITE_PATH"
    else
        echo "You have not enabled BCG729 in config_site"
    fi

    if [ "${ENABLE_OPENH264}" == "1" ]
    then
        echo "Enabling Video support in config_site"
        echo "#define PJMEDIA_HAS_VIDEO 1" >> "$CONFIG_SITE_PATH"
        # TODO: must be tested before enabling following settings
        # echo "#define PJMEDIA_VIDEO_DEV_HAS_OPENGL 1" >> "$CONFIG_SITE_PATH"
        # echo "#define PJMEDIA_VIDEO_DEV_HAS_OPENGL_ES 1" >> "${CONFIG_SITE_PATH}"
        # echo "#include <OpenGLES/ES3/glext.h>" >> "${CONFIG_SITE_PATH}"
    else
        echo "You have not enabled Video support in config_site"
    fi

    if [ "${CHANGE_PJSIP_TRANSPORT_IDLE_TIME}" == "1" ]
    then
        echo "Changing PJSIP_TRANSPORT_IDLE_TIME to $PJSIP_TRANSPORT_IDLE_TIME"
        echo "#define PJSIP_TRANSPORT_IDLE_TIME $PJSIP_TRANSPORT_IDLE_TIME" >> "$CONFIG_SITE_PATH"
    fi

    echo "#include <pj/config_site_sample.h>" >> "$CONFIG_SITE_PATH"
}

function buildPjSip {
    arch=$1
    echo ""
    echo "Compile PJSIP for arch $arch ..."
    rm -rf "${PJSIP_TMP_PATH}"
    mkdir -p "${PJSIP_TMP_PATH}"
    cd "${PJSIP_BASE_PATH}"
    cp -r * "${PJSIP_TMP_PATH}"
    cd "${PJSIP_TMP_PATH}"

    args=("--use-ndk-cflags")

    if [ "${ENABLE_OPENSSL}" == "1" ]
    then
        echo "with OpenSSL support"
        args+=("--with-ssl=${OPENSSL_BUILD_OUT_PATH}/libs/${arch}")
    else
        echo "without OpenSSL support"
    fi

    if [ "${ENABLE_OPENH264}" == "1" ]
    then
        echo "with OpenH264 support"
        args+=("--with-openh264=${OPENH264_BUILD_OUT_PATH}/libs/${arch}")
    else
        echo "without OpenH264 support"
    fi

    if [ "${ENABLE_OPUS}" == "1" ]
    then
        echo "with Opus support"
        args+=("--with-opus=${OPUS_BUILD_OUT_PATH}/libs/${arch}")
    else
        echo "without Opus support"
    fi

    if [ "${ENABLE_BCG729}" == "1" ]
    then
        echo "with BCG729 support"
        args+=("--with-bcg729=${BCG729_BUILD_OUT_PATH}/libs/${arch}")
    else
        echo "without BCG729 support"
    fi

    APP_PLATFORM=android-${TARGET_ANDROID_API} TARGET_ABI=$arch ./configure-android "${args[@]}" >> "${FINAL_BUILD_LOGS}/${arch}.log" 2>&1

    make dep >>"${FINAL_BUILD_LOGS}/${arch}.log" 2>&1
    make clean >>"${FINAL_BUILD_LOGS}/${arch}.log" 2>&1
    make >>"${FINAL_BUILD_LOGS}/${arch}.log" 2>&1

    echo "Compile PJSUA for arch $arch ..."
    cd "${PJSUA_BASE_DIR}"
    make >>"${FINAL_BUILD_LOGS}/${arch}.log" 2>&1

    echo "Copying PJSUA .so library to final build directory ..."
    mkdir -p "${FINAL_BUILD_LIB}/${arch}"
    # Different versions of PJSIP put .so libs in different directory name
    # using /*/* we assume there is only one directory (whatever its name is)
    # and retrieve all its content (.so libs)
    mv "${PJSUA_GENERATED_SO_PATH}"/*/* "${FINAL_BUILD_LIB}/${arch}"

    if [ -f ${OPENH264_BUILD_OUT_PATH}/libs/${arch}/lib/libopenh264.so ]; then
        echo "Copying OpenH264 .so library to final build directory ..."
        cp ${OPENH264_BUILD_OUT_PATH}/libs/${arch}/lib/libopenh264.so ${FINAL_BUILD_LIB}/${arch}/
    fi
}

function copyPjSuaJava {
    echo "Copying PJSUA2 java bindings to final build directory ..."
    cp -r "${PJSUA_GENERATED_SRC_DIR}" "${FINAL_BUILD_DIR}"
    rm -r "${PJSIP_TMP_PATH}"
}

function clearToolsDirectory {
    if [ "$REMOVE_TOOLS" == "1" ]
    then
        echo ""
        echo "Cleaning up tools ..."
        cd $BASEDIR
        rm -r tools
        echo "Finished cleaning up tools"
    fi
}

function setPermissions {
    if [ "$SET_PERMISSIONS" == "1" ] && [ "$OWNER" != "" ]
    then
        echo ""
        echo "Setting permissions on $BUILD_DIR for user $OWNER"
        chown $OWNER -R $BUILD_DIR
        echo "Finished Setting permissions"
    elif [ "$SET_PERMISSIONS" == "1" ] || [ "$OWNER" != "" ]
    then
        echo "You must set both the toggle [SET_PERMISSIONS] to 1 and the name of the user [OWNER] that should own the files"
    fi
}



function initialOpenSSLSetup {
    CUR_DIR="$(pwd)"
    OPENSSL_SRC_PATH="$DOWNLOAD_DIR/${OPENSSL_DIR_NAME}"
    OPENSSL_TMP_FOLDER="/tmp/openssl"
}

function setupSSLPathsAndExports {
    NDK_PATH="$DOWNLOAD_DIR/${NDK_DIR_NAME}"
    LIB_PATH="${OPENSSL_BUILD_OUT_PATH}/libs"
    LOG_PATH="${OPENSSL_BUILD_OUT_PATH}/logs"

    # Export ANDROID_NDK_HOME env var
    export ANDROID_NDK_HOME=$NDK_PATH
    # Add toolchains bin directory to PATH
    TOOLCHAIN_PATH="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64"
    # for some reason it does not need to be exported
    PATH=$TOOLCHAIN_PATH/bin:$PATH
}
 
function clearSSLTmpDirectory {
    rm -rf "$OPENSSL_TMP_FOLDER"
    mkdir -p "$OPENSSL_TMP_FOLDER"
    cp -r ${OPENSSL_SRC_PATH}/* ${OPENSSL_TMP_FOLDER}
}

function getSSLArchitecture {
    OPENSSL_TARGET_ABI=$1
    if [ "$OPENSSL_TARGET_ABI" == "armeabi-v7a" ]
    then
        ARCHITECTURE="android-arm"
    elif [ "$OPENSSL_TARGET_ABI" == "arm64-v8a" ]
    then
        ARCHITECTURE="android-arm64"
    elif [ "$OPENSSL_TARGET_ABI" == "x86" ]
    then
        # Use "no-asm" arg as specified in Merge Request #28 --- Use Only for x86 ARCH
        ARCHITECTURE="android-x86 no-asm"
    elif [ "$OPENSSL_TARGET_ABI" == "x86_64" ]
    then
        ARCHITECTURE="android-x86_64"
    else
        echo "Unsupported target ABI: $OPENSSL_TARGET_ABI"
        exit 1
    fi
}

function _setup_system {

    echo ""
    echo "Downloading Android NDK  ..."
    echo ""
    NDK_DOWNLOAD_URL="https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-linux-x86_64.zip"
    cd $DOWNLOAD_DIR
    curl -L -# -o ndk.zip "$NDK_DOWNLOAD_URL" 2>&1
    echo "Extracting Android NDK ..."
    echo ""
    unzip ndk.zip -d ndk
    mv ndk/$NDK_DIR_NAME .
    rm -rf ndk
    rm -rf ndk.zip
    CMD_TOOLS_VERSION=8512546
    CMD_TOOLS_DOWNLOAD_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMD_TOOLS_VERSION}_latest.zip"
    CMD_ZIP_FILE="$CMD_TOOLS.zip"
    curl -L -# -o $CMD_ZIP_FILE $CMD_TOOLS_DOWNLOAD_URL 2>&1
    echo ""
    echo "Android CMD Tools downloaded!"
    echo "" 
    echo "Extracting Android CMD Tools ..."
    rm -rf $SDK_DIR_NAME
    unzip -d $SDK_DIR_NAME $CMD_ZIP_FILE

    # Remove zip file
    rm -rf $CMD_ZIP_FILE

    # Create empty repositories.cfg file to avoid warning
    mkdir -p ~/.android
    touch ~/.android/repositories.cfg

    # Since new updates, there are some changes that are not mentioned in the documentation.
    # After unzipping the command line tools package, the top-most directory you'll get is $CMD_TOOLS.
    # Rename the unpacked directory from $CMD_TOOLS to $CMD_TOOLS_DIR_NAME, and place it under $ANDROID_HOME/$CMD_TOOLS
    # which will then look like $ANDROID_HOME/$CMD_TOOLS/$CMD_TOOLS_DIR_NAME
    cd $SDK_DIR_NAME/$CMD_TOOLS
    mkdir -p $CMD_TOOLS_DIR_NAME
    mv `ls | grep -w -v $CMD_TOOLS_DIR_NAME` $CMD_TOOLS_DIR_NAME


    echo "Exporting ANDROID_HOME"
    export ANDROID_HOME=$DOWNLOAD_DIR/$SDK_DIR_NAME
    SDK_MANAGER=$ANDROID_HOME/$CMD_TOOLS/$CMD_TOOLS_DIR_NAME/bin/sdkmanager
    echo "Downloading Android Platforms"
    for api in ${SETUP_ANDROID_APIS[@]}
    do
        echo yes | $SDK_MANAGER "platforms;android-$api"
    done

    echo "Downloading Android Platform-Tools"
    echo yes | $SDK_MANAGER "platform-tools"
    echo "Exporting TOOLS & PLATFORM_TOOLS"
    export PATH=$ANDROID_HOME/platform-tools/:$ANDROID_HOME/tools:$PATH

    echo "Downloading Android Build-Tools"
    echo yes | $SDK_MANAGER "build-tools;$ANDROID_BUILD_TOOLS"
    SWIG_VERSION=4.0.2
    SWIG_BUILD_OUT_PATH="$BUILD_DIR/swig-build-output"
    SWIG_DIR_NAME="swig-$SWIG_VERSION"
    echo ""
    echo "Downloading SWIG ${SWIG_VERSION} ..."
    echo ""
    cd $DOWNLOAD_DIR
    SWIG_DOWNLOAD_URL="http://prdownloads.sourceforge.net/swig/swig-$SWIG_VERSION.tar.gz"
    curl -L -# -o swig.tar.gz "$SWIG_DOWNLOAD_URL" 2>&1
    rm -rf "$SWIG_DIR_NAME"
    echo "SWIG downloaded!"
    echo "Extracting SWIG ..."
    tar xzf swig.tar.gz && rm -rf swig.tar.gz
    cd "$SWIG_DIR_NAME"
    mkdir -p $SWIG_BUILD_OUT_PATH
    echo "Configuring SWIG ..."
    ./configure >> "$SWIG_BUILD_OUT_PATH/swig.log" 2>&1
    echo "Compiling SWIG ..."
    make >> "$SWIG_BUILD_OUT_PATH/swig.log" 2>&1
    echo "Installing SWIG ..."
    make install >> "$SWIG_BUILD_OUT_PATH/swig.log" 2>&1
    cd ..
    rm -rf "$SWIG_DIR_NAME"
  
}

start=`date +%s`

_setup_system

# OpenH264
initialH264Setup
setupH264PathsAndExports

for arch in "${TARGET_ARCHS[@]}"
do
    echo "Building OpenH264 for target arch $arch ..."
    # Clear the tmp source directory
    clearH264TmpAndInitDirectory

    #change default output DIR for make install
    sed -i "s*PREFIX=/usr/local*PREFIX=${LIB_PATH}/${arch}*g" Makefile
    
    ARGS="APP_PLATFORM=android-${TARGET_ANDROID_API} OS=android NDKROOT=${NDK_PATH} NDK_TOOLCHAIN_VERSION=clang NDKLEVEL=${OPENH264_TARGET_NDK_LEVEL} "
    ARGS="${ARGS}TARGET=android-${TARGET_ANDROID_API} ARCH="
    # Add final architecture dependent info
    finalizeH264Args $arch

    make ${ARGS} >> "${LOG_PATH}/${arch}.log" 2>&1
    mkdir -p ${LIB_PATH}/${arch}
    make ${ARGS} install >> "${LOG_PATH}/${arch}.log" 2>&1
done

# OpenSSL
 
initialOpenSSLSetup 
setupSSLPathsAndExports 
 
# Set clang compiler, instead of gcc by default
CC=clang
 
# Build OpenSSL for each ARCH specified in config.conf
for arch in "${TARGET_ARCHS[@]}"
do
    echo "Configuring OpenSSL for target arch $arch ..."

    # Clear the tmp source directory
    clearSSLTmpDirectory
    # Go to source files
    cd ${OPENSSL_TMP_FOLDER}

    OPENSSL_OUTPUT_PATH=$LIB_PATH/$arch

    # Set the target architecture
    # Can be android-arm, android-arm64, android-x86 etc
    ARCHITECTURE="android-arm"
    getSSLArchitecture $arch

    # Create Makefile
    ./Configure $ARCHITECTURE -D__ANDROID_API__=${OPENSSL_TARGET_NDK_LEVEL} >> "${LOG_PATH}/${arch}.log" 2>&1

    # Build Openssl
    echo "Building OpenSSL Library for Android arch $arch"
    make >> "${LOG_PATH}/${arch}.log" 2>&1
    mkdir -p $OPENSSL_OUTPUT_PATH
    OUTPUT_LIB=$OPENSSL_OUTPUT_PATH/lib
    mkdir -p $OUTPUT_LIB
    OUTPUT_INCLUDE=${OPENSSL_OUTPUT_PATH}/include
    mkdir -p $OUTPUT_INCLUDE
    cp -RL include/openssl $OUTPUT_INCLUDE

    # Copy libs to final destination folder
    cp libssl.a $OUTPUT_LIB
    cp libcrypto.a $OUTPUT_LIB

    cp libssl.so $OUTPUT_LIB
    cp libcrypto.so $OUTPUT_LIB
    echo "Build completed! Check output libraries in ${OPENSSL_OUTPUT_PATH}"
done

rm -rf ${OPENSSL_TMP_FOLDER}
echo "Finished building OpenSSL! "

# OPUS

mkdir -p jni
cd jni  
cp $BASE_DIR/pjsip/Android.mk .
# Build Opus
echo "Building Opus"
$NDK_PATH/ndk-build APP_PLATFORM=android-${TARGET_ANDROID_API} >> "${LOG_PATH}/opus.log" 2>&1

# Copy Files to Build Directory
echo "Copying build file in Opus Build directory ..."
cp -r $LIB_BUILD_PATH/* $OPUS_LIB_PATH

for arch in "${TARGET_ARCHS[@]}"
do
    echo "Copying Opus file for target arch $arch ..."
    cd $OPUS_LIB_PATH/$arch
    mkdir -p lib
    mv `ls | grep -w -v lib` lib
    mkdir -p include/opus
    cp $LIB_HEADERS_PATH/* include/opus
done

echo "Finished building Opus"

# PJSIP
setConfigSite
for arch in "${TARGET_ARCHS[@]}"
do
    buildPjSip $arch
done
copyPjSuaJava
clearToolsDirectory
echo "Finished building pjsua2! "

end=`date +%s`
echo "End time: $end"
runtime=$((end-start))
echo "Total script runtime: $runtime"