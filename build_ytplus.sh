#!/bin/bash

# 本地打包脚本 - 仿照GitHub workflow

# 设置默认参数
enable_youpip=false
enable_ytuhd=false
enable_yq=false
enable_ryd=false
enable_demc=false
ipa_url=""
tweak_version="5.2b4"
display_name="YouTube"
bundle_id="com.google.ios.youtube"

# 参数处理
while [[ $# -gt 0 ]]; do
    case $1 in
        --enable-youpip)
            enable_youpip=true
            shift
            ;;
        --enable-ytuhd)
            enable_ytuhd=true
            shift
            ;;
        --enable-yq)
            enable_yq=true
            shift
            ;;
        --enable-ryd)
            enable_ryd=true
            shift
            ;;
        --enable-demc)
            enable_demc=true
            shift
            ;;
        --ipa-url)
            ipa_url="$2"
            shift 2
            ;;
        --tweak-version)
            tweak_version="$2"
            shift 2
            ;;
        --display-name)
            display_name="$2"
            shift 2
            ;;
        --bundle-id)
            bundle_id="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --enable-youpip       Enable YouPiP integration"
            echo "  --enable-ytuhd        Enable YTUHD integration"
            echo "  --enable-yq           Enable YouQuality integration"
            echo "  --enable-ryd          Enable Return YouTube Dislikes integration"
            echo "  --enable-demc         Enable DontEatMyContent integration"
            echo "  --ipa-url URL         URL to the decrypted IPA file"
            echo "  --tweak-version VER   Version of the tweak to use (default: 5.2b4)"
            echo "  --display-name NAME   App name (default: YouTube)"
            echo "  --bundle-id ID        Bundle ID (default: com.google.ios.youtube)"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# 检查必要参数
if [ -z "$ipa_url" ]; then
    echo "Error: --ipa-url is required"
    echo "Use -h or --help for usage information"
    exit 1
fi

# 设置工作目录
WORKSPACE=$(pwd)
BUILD_DIR="$WORKSPACE/build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "=== YouTube Plus Local Build Script ==="
echo "Working directory: $BUILD_DIR"
echo "Tweak version: $tweak_version"
echo "Display name: $display_name"
echo "Bundle ID: $bundle_id"
echo "Integrations:"
echo "  YouPiP: $enable_youpip"
echo "  YTUHD: $enable_ytuhd"
echo "  YouQuality: $enable_yq"
echo "  Return YouTube Dislikes: $enable_ryd"
echo "  DontEatMyContent: $enable_demc"
echo ""

# 下载和验证IPA
echo "Step 1: Downloading and validating IPA..."
wget "$ipa_url" --no-verbose -O youtube.ipa

file_type=$(file --mime-type -b youtube.ipa)
if [[ "$file_type" != "application/x-ios-app" && "$file_type" != "application/zip" ]]; then
    echo "Error: Validation failed: The downloaded file is not a valid IPA. Detected type: $file_type."
    exit 1
fi
echo "✓ IPA downloaded and validated successfully"

# 安装依赖
echo "\nStep 2: Installing dependencies..."
brew list make > /dev/null 2>&1 || brew install make
brew list ldid > /dev/null 2>&1 || brew install ldid
echo "✓ Dependencies installed"

# 设置PATH环境变量
echo "\nStep 3: Setting up PATH..."
export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"
echo "✓ PATH updated"

# 安装或使用现有Theos
echo "\nStep 4: Setting up Theos..."
THEOS="$BUILD_DIR/theos"

if [ "$enable_youpip" = "true" ] || [ "$enable_ytuhd" = "true" ] || [ "$enable_yq" = "true" ] || [ "$enable_ryd" = "true" ] || [ "$enable_demc" = "true" ]; then
    if [ -d "$THEOS" ]; then
        echo "Theos already exists. Using existing installation."
    else
        echo "Cloning Theos..."
        git clone --quiet --recursive https://github.com/theos/theos.git "$THEOS"
        cd "$THEOS"
        git checkout 67db2ab8d950910161730de77c322658ea3e6b44
        git submodule update --recursive
        cd "$BUILD_DIR"
        
        # 下载iOS SDK
        echo "Downloading iOS SDK..."
        git clone --quiet -n --depth=1 --filter=tree:0 https://github.com/theos/sdks/
        cd sdks
        git sparse-checkout set --no-cone iPhoneOS16.5.sdk
        git checkout
        mv *.sdk "$THEOS/sdks"
        cd ..
        rm -rf sdks
    fi
    export THEOS="$THEOS"
fi
echo "✓ Theos setup complete"

# 安装cyan工具
echo "\nStep 5: Installing cyan tool..."
which pipx > /dev/null 2>&1 || brew install pipx
pipx ensurepath > /dev/null 2>&1
export PATH="$HOME/.local/bin:$PATH"
pipx install --force https://github.com/asdfzxcvbn/pyzule-rw/archive/main.zip > /dev/null 2>&1
echo "✓ cyan tool installed"

# 下载YouTube Plus
echo "\nStep 6: Downloading YouTube Plus..."
deb_url="https://github.com/dayanch96/YTLite/releases/download/v$tweak_version/com.dvntm.ytlite_${tweak_version}_iphoneos-arm.deb"
wget "$deb_url" --no-verbose -O ytplus.deb
echo "✓ YouTube Plus downloaded"

# 克隆依赖项
echo "\nStep 7: Cloning dependencies..."

# 清理可能存在的旧依赖项目录
# if [ "$enable_youpip" = "true" ]; then
#     rm -rf "$BUILD_DIR/YouPiP"
# fi
# if [ "$enable_ytuhd" = "true" ]; then
#     rm -rf "$BUILD_DIR/YTUHD"
# fi
# if [ "$enable_ryd" = "true" ]; then
#     rm -rf "$BUILD_DIR/Return-YouTube-Dislikes"
# fi
# if [ "$enable_demc" = "true" ]; then
#     rm -rf "$BUILD_DIR/YouGroupSettings"
#     rm -rf "$BUILD_DIR/DontEatMyContent"
# fi
# if [ "$enable_yq" = "true" ]; then
#     rm -rf "$BUILD_DIR/YouQuality"
# fi
# if [ "$enable_yq" = "true" ] || [ "$enable_youpip" = "true" ]; then
#     rm -rf "$BUILD_DIR/YTVideoOverlay"
# fi

# YouTubeHeader
if [ "$enable_youpip" = "true" ] || [ "$enable_ytuhd" = "true" ] || [ "$enable_yq" = "true" ] || [ "$enable_ryd" = "true" ] || [ "$enable_demc" = "true" ]; then
    if [ -d "$THEOS/include/YouTubeHeader" ]; then
        echo "YouTubeHeader exists. Pulling latest changes..."
        cd "$THEOS/include/YouTubeHeader"
        git pull --quiet
        cd "$BUILD_DIR"
    else
        echo "Cloning YouTubeHeader..."
        mkdir -p "$THEOS/include"
        git clone --quiet --depth=1 https://github.com/PoomSmart/YouTubeHeader.git "$THEOS/include/YouTubeHeader"
    fi
    
    if [ "$enable_demc" = "true" ]; then
        echo "Copying YouTubeHeader to YTHeaders..."
        rm -rf "$THEOS/include/YTHeaders"
        cp -r "$THEOS/include/YouTubeHeader" "$THEOS/include/YTHeaders"
    fi
fi

# PSHeader
if [ "$enable_youpip" = "true" ] || [ "$enable_ytuhd" = "true" ] || [ "$enable_yq" = "true" ] || [ "$enable_ryd" = "true" ] || [ "$enable_demc" = "true" ]; then
    if [ -d "$THEOS/include/PSHeader" ]; then
        echo "PSHeader exists. Pulling latest changes..."
        cd "$THEOS/include/PSHeader"
        git pull --quiet
        cd "$BUILD_DIR"
    else
        echo "Cloning PSHeader..."
        mkdir -p "$THEOS/include"
        git clone --quiet --depth=1 https://github.com/PoomSmart/PSHeader.git "$THEOS/include/PSHeader"
    fi
fi

# YouPiP
if [ "$enable_youpip" = "true" ]; then
    echo "Cloning YouPiP..."
    git clone --quiet --depth=1 https://github.com/PoomSmart/YouPiP.git
fi

# YTUHD
if [ "$enable_ytuhd" = "true" ]; then
    echo "Cloning YTUHD..."
    git clone --quiet --depth=1 https://github.com/Tonwalter888/YTUHD.git
fi

# Return-YouTube-Dislikes
if [ "$enable_ryd" = "true" ]; then
    echo "Cloning Return-YouTube-Dislikes..."
    git clone --quiet --depth=1 https://github.com/PoomSmart/Return-YouTube-Dislikes.git
fi

# YouGroupSettings
if [ "$enable_demc" = "true" ]; then
    echo "Cloning YouGroupSettings..."
    git clone --quiet --depth=1 https://github.com/PoomSmart/YouGroupSettings.git
fi

# YouQuality
if [ "$enable_yq" = "true" ]; then
    echo "Cloning YouQuality..."
    git clone --quiet --depth=1 https://github.com/PoomSmart/YouQuality.git
fi

# YTVideoOverlay
if [ "$enable_yq" = "true" ] || [ "$enable_youpip" = "true" ]; then
    echo "Cloning YTVideoOverlay..."
    git clone --quiet --depth=1 https://github.com/PoomSmart/YTVideoOverlay.git
fi

# DontEatMyContent
if [ "$enable_demc" = "true" ]; then
    echo "Cloning DontEatMyContent..."
    git clone --quiet --depth=1 --recurse-submodules https://github.com/therealFoxster/DontEatMyContent.git
fi

echo "✓ Dependencies cloned"

# 构建依赖项
echo "\nStep 8: Building dependencies..."

# 定义一个通用的构建函数
build_tweak() {
    local tweak_name=$1
    local tweak_dir=$2
    local output_deb=$3
    local build_command=$4
    
    echo "Building $tweak_name..."
    cd "$BUILD_DIR/$tweak_dir"
    
    # 执行构建命令，输出到临时文件以便调试
    build_output=$(mktemp)
    make $build_command DEBUG=0 FINALPACKAGE=1 > "$build_output" 2>&1
    build_result=$?
    
    if [ $build_result -ne 0 ]; then
        echo "✗ Build failed for $tweak_name. Check log: $build_output"
        echo "Last 20 lines of build log:"
        tail -n 20 "$build_output"
        rm "$build_output"
        return 1
    fi
    
    # 检查packages目录是否存在
    if [ ! -d "packages" ]; then
        echo "✗ Build failed for $tweak_name: packages directory not found"
        echo "Last 20 lines of build log:"
        tail -n 20 "$build_output"
        rm "$build_output"
        return 1
    fi
    
    # 检查是否生成了deb文件
    deb_files=(packages/*.deb)
    if [ ! -f "${deb_files[0]}" ]; then
        echo "✗ Build failed for $tweak_name: no deb files found in packages directory"
        echo "Contents of packages directory:"
        ls -la packages/
        echo "Last 20 lines of build log:"
        tail -n 20 "$build_output"
        rm "$build_output"
        return 1
    fi
    
    # 移动生成的deb文件
    mv packages/*.deb "$BUILD_DIR/$output_deb"
    
    echo "✓ $tweak_name built successfully"
    rm "$build_output"
    cd "$BUILD_DIR"
    return 0
}

# Build YouPiP
if [ "$enable_youpip" = "true" ]; then
    build_tweak "YouPiP" "YouPiP" "youpip.deb" "clean package" || exit 1
fi

# Build YTUHD
if [ "$enable_ytuhd" = "true" ]; then
    build_tweak "YTUHD" "YTUHD" "ytuhd.deb" "clean package" || exit 1
fi

# Build Return-YouTube-Dislikes
if [ "$enable_ryd" = "true" ]; then
    build_tweak "Return-YouTube-Dislikes" "Return-YouTube-Dislikes" "ryd.deb" "clean package" || exit 1
fi

# Build YouGroupSettings
if [ "$enable_demc" = "true" ]; then
    build_tweak "YouGroupSettings" "YouGroupSettings" "ygs.deb" "clean package" || exit 1
fi

# Build YouQuality
if [ "$enable_yq" = "true" ]; then
    build_tweak "YouQuality" "YouQuality" "yq.deb" "clean package" || exit 1
fi

# Build YTVideoOverlay
if [ "$enable_yq" = "true" ] || [ "$enable_youpip" = "true" ]; then
    build_tweak "YTVideoOverlay" "YTVideoOverlay" "ytvo.deb" "clean package" || exit 1
fi

# Build DontEatMyContent
if [ "$enable_demc" = "true" ]; then
    build_tweak "DontEatMyContent" "DontEatMyContent" "demc.deb" "clean package" || exit 1
fi

echo "✓ Dependencies built"

# 注入tweak到IPA
echo "\nStep 9: Injecting tweaks into IPA..."

tweaks="ytplus.deb"

for f in *.deb; do
    if [ -f "$f" ] && [ "$f" != "ytplus.deb" ]; then
        tweaks="$tweaks $f"
    fi
done

echo "Tweaks to inject: $tweaks"

cyan -i youtube.ipa -o YouTubePlus_${tweak_version}.ipa -uwf $tweaks -n "$display_name" -b "$bundle_id"

echo "✓ Tweaks injected successfully"

# 完成
echo "\n=== Build Complete! ==="
IPA_FILE="$BUILD_DIR/YouTubePlus_${tweak_version}.ipa"
if [ -f "$IPA_FILE" ]; then
    echo "IPA file created: $IPA_FILE"
    echo "File size: $(du -h "$IPA_FILE" | cut -f1)"
    echo ""
    echo "To install the IPA, you can use:"
    echo "- Cydia Impactor"
    echo "- AltStore"
    echo "- Sideloadly"
    echo "- Any other IPA sideloading tool"
else
    echo "Error: IPA file was not created. Check the build logs for errors."
    exit 1
fi

echo "\n=== Build Summary ==="
echo "Build successful: ✓"
echo "IPA location: $IPA_FILE"
echo "Build time: $(date)"
