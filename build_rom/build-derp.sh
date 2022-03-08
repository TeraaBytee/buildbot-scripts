#!/bin/sh

# Copyright 2022 TeraaBytee
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

text="[===== <b>Time to DerpFest A12</b> =====]" msg

# Repo init
repo init -u git@github.com:DerpFest-12/manifest.git -b 12 --depth=1

# Repo sync
RESYNC=0
if [ $RESYNC = "1" ]; then
    text="<code>repo sync . . .</code>" msg
    time_start
    repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
    time_count
    text="<b>Sync finish in</b>:%0A<code>$TIME_COUNT</code>" msg
fi

# Building ROM
BUILD_START=1
if [ $BUILD_START = "1" ]; then
    text="<code>lunch derp_begonia-userdebug</code>" msg
    source build/envsetup.sh && lunch derp_begonia-userdebug

    text="<code>clean image . . .</code>" msg
    mka installclean

    text="<code>start building . . .</code>" msg

    time_start
    mka derp -j$(nproc --all)
    time_count

    # Upload
    FileZip=$(echo $MainPath/out/target/product/begonia/DerpFest-*.zip)
    json="$MainPath/out/target/product/begonia/begonia.json"

    if [ ! -e $FileZip ]; then
        cat out/error.log > error.log
        document="$MainPath/error.log"
        caption="$(date)" upload
        text="$(
        printf "<b>Build fail in</b>:\n"
        printf "<code>$TIME_COUNT</code>\n\n"
        printf "[======== <b>Yahaha Wahyu</b> ========]\n"
        )" msg
    else
        document=$json
        caption="$(date)" upload
        LINK=$(gdrive upload --share $FileZip | grep download)
        text="$(
        printf "[======== <b>Update BuildBot</b> ========]\n\n"
        printf "<code>PLATFORM_VERSION=12</code>\n"
        printf "<code>DERP_VERSION=$(cat out/soong.log | grep "DERP_VERSION" | awk '{ print $5 }')</code>\n"
        printf "<code>WITH_GMS=true</code>\n"
        printf "<code>TARGET_PRODUCT=derp_begonia</code>\n"
        printf "<code>$(cat out/soong.log | sed s/Environment:.*//g | grep "TARGET_BUILD_VARIANT=" | awk '{ print $4 }')</code>\n"
        printf "<code>TARGET_ARCH=arm64</code>\n"
        printf "<code>TARGET_ARCH_VARIANT=armv8-a</code>\n"
        printf "<code>TARGET_CPU_VARIANT=generic</code>\n"
        printf "<code>BUILD_ID=$(cat out/soong.log | grep "BUILD_ID" | awk '{ print $5 }')</code>\n\n"
        printf "[======== <b>Update BuildBot</b> ========]\n\n"
        printf "$LINK"
        )" msg
        text="<b>Build success in</b>:%0A<code>$TIME_COUNT</code>" msg
    fi
elif [ $BUILD_START = "0" ]; then
    text="<code>build not started, need bringup for first</code>" msg
fi
