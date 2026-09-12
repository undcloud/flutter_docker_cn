FROM ubuntu:24.04
USER root

# 静默安装
ARG DEBIAN_FRONTEND=noninteractive
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# apt换源 
RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse" |  tee /etc/apt/sources.list.d/docker.list  \
    && echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse" |  tee /etc/apt/sources.list.d/docker.list  \
    && echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse" |  tee /etc/apt/sources.list.d/docker.list  \
    && echo "deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse" |  tee /etc/apt/sources.list.d/docker.list  

# 参考： https://github.com/cirruslabs/docker-images-android 
RUN apt update \
    && apt install  wget -y 

ENV ANDROID_HOME=/opt/android-sdk-linux \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

ENV ANDROID_SDK_ROOT=$ANDROID_HOME \
    PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator

# comes from https://developer.android.com/studio/#command-line-tools-only
ENV ANDROID_SDK_TOOLS_VERSION 13114758
# 国内镜像加速配置（Flutter / Dart）
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn \
    FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
    FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git

RUN set -o xtrace \
    && cd /opt \
    && apt-get update \
    && apt-get install -y jq \
    && apt-get install -y openjdk-21-jdk \
    && apt-get install -y sudo wget zip unzip git openssh-client curl bc software-properties-common build-essential ruby-full ruby-bundler libstdc++6 libpulse0 libglu1-mesa locales lcov libsqlite3-dev --no-install-recommends \
    # for x86 emulators
    && apt-get install -y libxtst6 libnss3-dev libnspr4 libxss1 libasound2t64 libatk-bridge2.0-0 libgtk-3-0 libgdk-pixbuf2.0-0 \
    && apt-get install -y -qq xxd \
    && apt-get install -y lftp \
    && apt-get install -qq -y sqlite3 libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && sh -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen' \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip -O android-sdk-tools.zip \
    && mkdir -p ${ANDROID_HOME}/cmdline-tools/ \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME}/cmdline-tools/ \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && chown -R root:root $ANDROID_HOME \
    && rm android-sdk-tools.zip \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && yes | sdkmanager --licenses \
    && wget -O /usr/bin/android-wait-for-emulator https://raw.githubusercontent.com/travis-ci/travis-cookbooks/master/community-cookbooks/android-sdk/files/default/android-wait-for-emulator \
    && chmod +x /usr/bin/android-wait-for-emulator \
    && touch /root/.android/repositories.cfg \
    && sdkmanager platform-tools \
    && mkdir -p /root/.android \
    && touch /root/.android/repositories.cfg \
    && git config --global user.email "support@cirruslabs.org" \
    && git config --global user.name "Cirrus CI"

# emulator is not available on linux/arm64 (https://issuetracker.google.com/issues/227219818)
RUN if [ $(uname -m) = "x86_64" ]; then sdkmanager emulator ; fi

# https://developer.android.com/studio/releases/build-tools
ENV ANDROID_PLATFORM_VERSION 36
ENV ANDROID_BUILD_TOOLS_VERSION 36.0.0

# 好像不需要
# RUN apt-get update && apt-get install -y \
#     libxcb-cursor0 \
#     libxcb-xinerama0 \
#     libxcb-randr0 \
#     libxcb-shape0 \
#     libxcb-xfixes0 \
#     libxcb-render-util0 \
#     libxcb-keysyms1 \
#     libxcb-icccm4 \
#     libxcb-image0 \
#     libxcb-util1 \
#     libxkbcommon-x11-0 \
#     mesa-vulkan-drivers

# RUN apt-get update \
#   && apt-get install --yes --no-install-recommends openjdk-$JAVA_VERSION-jdk curl unzip sed git bash xz-utils libglvnd0 ssh xauth x11-xserver-utils libpulse0 libxcomposite1 libgl1-mesa-glx sudo \
#   && rm -rf /var/lib/{apt,dpkg,cache,log}

RUN yes | sdkmanager \
    # 模拟器
    "platforms;android-$ANDROID_PLATFORM_VERSION" \
    "build-tools;$ANDROID_BUILD_TOOLS_VERSION"


ARG flutter_ver=3.41.6
ARG build_rev=0


# Install Flutter  https://github.com/instrumentisto/flutter-docker-image
ENV FLUTTER_HOME=/usr/local/flutter \
    FLUTTER_VERSION=${flutter_ver} \
    # 设置 Dart 包的镜像源
    PUB_HOSTED_URL=https://pub.flutter-io.cn \
    # 设置 Flutter SDK 的镜像源
    FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
    PATH=$PATH:/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            ca-certificates \
 && update-ca-certificates \
    \
 # Install dependencies for Linux toolchain
 && apt-get install -y --no-install-recommends --no-install-suggests \
            build-essential \
            clang cmake \
            lcov \
            libgtk-3-dev liblzma-dev \
            ninja-build \
            pkg-config \
    \
 # Install Flutter itself
 && curl --retry 5 --retry-delay 3 -fL -o /tmp/flutter.tar.xz \
        https://storage.flutter-io.cn/flutter_infra_release/releases/stable/linux/flutter_linux_${flutter_ver}-stable.tar.xz \
 && tar -xf /tmp/flutter.tar.xz -C /usr/local/ \
 && git config --global --add safe.directory /usr/local/flutter \
 && flutter config --enable-android \
                   --enable-linux-desktop \
                   --enable-web \
                   --no-enable-ios \
 && flutter precache --universal --linux --web --no-ios \
 && (yes | flutter doctor --android-licenses) \
 && flutter --version \
    \
 # Make Flutter tools available for non-root usage
 && chown -R 1000:1000 /usr/local/flutter/packages/flutter_tools/.dart_tool/ \
    \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

# 1. 清理重复的源警告，并更新包列表
RUN rm -f /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    # 2. 安装图形驱动依赖，解决 eglinfo 警告
    && apt-get install -y --no-install-recommends mesa-vulkan-drivers mesa-utils \
    # 3. 下载并安装真正的 Google Chrome (非 Snap 版)
    && wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y --no-install-recommends /tmp/google-chrome.deb \
    # 4. 清理临时文件和缓存，减小镜像体积
    && rm -f /tmp/google-chrome.deb \
    && rm -rf /var/lib/apt/lists/*

# # 让镜像构建时就预创建好 AVD
RUN yes | sdkmanager \
    # 系统镜像
    "system-images;android-36;google_apis;x86_64" \
    "system-images;android-34;google_apis;x86_64"
RUN mkdir -p /root/.android/avd \
 && echo no | avdmanager create avd \
      -n flutter_emulator \
      -k "system-images;android-34;google_apis;x86_64" \
      -d pixel
