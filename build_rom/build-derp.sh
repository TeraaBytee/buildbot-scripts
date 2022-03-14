#!/bin/bash

#   Copyright (C) 2022 TeraaBytee
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

MainPath=$(pwd)

# Telegram message
# echo 'your bot token' > .bot_token
# echo 'your group or channel chat id' > .chat_id
BOT_TOKEN=$(cat .bot_token)
CHAT_ID=$(cat .chat_id)

msg(){
    curl -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
    -d chat_id=$CHAT_ID \
    -d parse_mode=html \
    -d disable_web_page_preview=true \
    -d text="$text"
}

upload(){
    curl -F parse_mode=markdown https://api.telegram.org/bot$BOT_TOKEN/sendDocument \
    -F chat_id=$CHAT_ID \
    -F document=@"$document" \
    -F caption="$caption"
}

time_start(){
    TIME_START=$(date +"%s")
}

time_count(){
    TIME_END=$(date +"%s")
    TIME_DIFF=$((TIME_END - TIME_START))
    TIME_COUNT="$((TIME_DIFF / 3600)) hour(s) $((TIME_DIFF / 60 % 60)) minute(s) and $((TIME_DIFF % 60)) second(s)"
}

# Git config
git config --global user.name "TeraaBytee"
git config --global user.email "terabyte3766@gmail.com"

text="[=========== <b>Time to DerpFest</b> ===========]" msg

# Repo init
repo init -u git@github.com:DerpFest-12/manifest.git -b 12 --depth=1

# Repo sync
RESYNC='0'
if [[ $RESYNC = '1' ]]; then
    text="<code>repo sync . . .</code>" msg
    time_start
    repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
    time_count
    text="<b>Sync finish in</b>:%0A<code>$TIME_COUNT</code>" msg
elif [[ $RESYNC = '0' ]]; then
    text="<code>skip sync source</code>" msg
fi

# Clone tree
CloneTree='0'
if [[ $CloneTree = '1' ]]; then
    TreeType="begonia"
    if [[ $TreeType = "common" ]]; then
        git clone git@github.com:DerpFest-begonia/device_mediatek_common -b 12 device/mediatek/common
        git clone git@github.com:DerpFest-begonia/device_mediatek_sepolicy_vndr -b 12 device/mediatek/sepolicy_vndr
        git clone git@github.com:DerpFest-begonia/device_xiaomi_begonia -b 12 device/xiaomi/begonia
        git clone git@github.com:DerpFest-begonia/vendor_xiaomi_begonia -b 12 vendor/xiaomi/begonia
        git clone git@github.com:DerpFest-begonia/kernel_xiaomi_begonia -b 12 kernel/xiaomi/begonia --depth=1
        git clone git@github.com:DerpFest-begonia/vendor_mediatek_ims -b 12 vendor/mediatek/ims
        git clone git@github.com:DerpFest-begonia/vendor_mediatek_interfaces -b 12 vendor/mediatek/interfaces
        git clone git@github.com:DerpFest-begonia/vendor_mediatek-opensource -b 12 vendor/mediatek/opensource
        git clone https://github.com/PixelExperience/packages_resources_devicesettings -b twelve packages/resource/devicesettings-custom
    elif [[ $TreeType = "begonia" ]]; then
        git clone git@github.com:TeraaBytee/device_mediatek_sepolicy -b 12 device/mediatek/sepolicy
        git clone git@github.com:TeraaBytee/device_xiaomi_begonia -b 12 device/xiaomi/begonia
        git clone git@github.com:TeraaBytee/vendor_xiaomi_begonia -b 12 vendor/xiaomi/begonia
        git clone git@github.com:TeraaBytee/vendor_xiaomi_begonia-ims -b 12 vendor/xiaomi/begonia-ims
        git clone git@github.com:TeraaBytee/kernel_xiaomi_begonia -b 12 kernel/xiaomi/begonia --depth=1
    fi
fi

# Building ROM
BUILD_START='1'
if [[ $BUILD_START = '1' ]]; then
    BUILD_TYPE="CI"
    if [[ $BUILD_TYPE = "CI" ]]; then
        sed -i s/"DERP_BUILDTYPE :=.*"/"DERP_BUILDTYPE := CI"/g device/xiaomi/begonia/derp_begonia.mk
    elif [[ $BUILD_TYPE = "Official" ]]; then
        sed -i s/"DERP_BUILDTYPE :=.*"/"DERP_BUILDTYPE := Official"/g device/xiaomi/begonia/derp_begonia.mk
    fi

    text="<code>lunch derp_begonia-userdebug</code>" msg
    source build/envsetup.sh && lunch derp_begonia-userdebug

    text="<code>clean image . . .</code>" msg
    mka installclean

    text="<code>start building . . .</code>" msg

    time_start
    mka derp -j$(nproc --all)
    time_count

    if [[ $BUILD_TYPE = "CI" ]]; then
        sed -i s/"DERP_BUILDTYPE :=.*"/"DERP_BUILDTYPE := Official"/g device/xiaomi/begonia/derp_begonia.mk
    fi

    # Upload
    FileZip=$(echo out/target/product/begonia/DerpFest-*.zip)
    FileSize=$(du -h out/target/product/begonia/DerpFest-*.zip | awk '{ print $1 }')
    json="out/target/product/begonia/begonia.json"

    if [[ ! -e $FileZip ]]; then
        cat out/error.log > error.log
        document="error.log"
        caption="$(date)" upload
        text="$(
        printf "<b>Build fail in</b>:\n"
        printf "<code>$TIME_COUNT</code>\n\n"
        printf "[============ <b>Yahaha Wahyu</b> ============]\n"
        )" msg
    else
        document=$json
        caption="$(date)" upload
        LINK=$(gdrive upload --share --parent 1zQ8gUqQtBM3BRxlNMzSgh0tPjQM-64o5 $FileZip | grep download)
        text="$(
        printf "[======================================]\n\n"
        printf "BUILD_ID : <code>$(cat out/soong.log | grep "BUILD_ID" | awk '{ print $5 }')</code>\n"
        printf "PLATFORM_VERSION : <code>12</code>\n"
        printf "PLATFORM_VERSION_CODENAME : <code>REL</code>\n"
        printf "TARGET_ARCH : <code>arm64</code>\n"
        printf "TARGET_ARCH_VARIANT : <code>armv8-a</code>\n"
        printf "TARGET_BUILD_VARIANT : <code>$(cat out/soong.log | sed s/Environment:.*//g | grep "TARGET_BUILD_VARIANT=" | awk '{ print $4 }' | sed s/"TARGET_BUILD_VARIANT="//g)</code>\n"
        printf "TARGET_CPU_VARIANT : <code>generic</code>\n"
        printf "TARGET_PRODUCT : <code>derp_begonia</code>\n"
        printf "WITH_GMS : <code>true</code>\n"
        printf "DERP_VERSION : <code>$(cat out/soong.log | grep "DERP_VERSION" | awk '{ print $5 }')</code>\n\n"
        printf "[======================================]\n\n"
        printf "Size: ${FileSize}\n"
        printf "${LINK}"
        )" msg
        text="<b>Build success in</b>:%0A<code>$TIME_COUNT</code>" msg
    fi

elif [[ $BUILD_START = '0' ]]; then
    text="<code>build not started, need bringup for first</code>" msg
fi
