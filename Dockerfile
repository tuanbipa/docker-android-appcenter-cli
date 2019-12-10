# Build environment
FROM openjdk:8 as base

USER root
ENV SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip" \
    ANDROID_HOME="/usr/local/android-sdk" \
    ANDROID_VERSION=28 \
    ANDROID_BUILD_TOOLS_VERSION=29.0.1
    
# Download Android SDK
RUN mkdir "$ANDROID_HOME" .android \
    && cd "$ANDROID_HOME" \
    && curl -o sdk.zip $SDK_URL \
    && unzip sdk.zip \
    && rm sdk.zip \
    && yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses

# Install Android Build Tool and Libraries
RUN $ANDROID_HOME/tools/bin/sdkmanager --update
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_VERSION}" \
    "platform-tools"

# Install Build Essentials
RUN apt-get update \
    && apt-get upgrade -y \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g react-tools

# Install app center
RUN mkdir ~/.appcenter-cli && \
    echo false > ~/.appcenter-cli/telemetryEnabled.json && \
    npm install -g appcenter-cli

# Copy source code to docker container and build project
FROM base as build
WORKDIR /src
COPY . .
RUN ./gradlew clean assembleDebug

# Upload a build to distribute via appcenter
FROM build as publish
ENV APK_FOLDER="/src/app/build/outputs/apk/debug/"
ENV APPCENTER_ACCESS_TOKEN=""
ENV OWNERNAME=""
ENV APPNAME=""
ENV RELEASENOTES=""
WORKDIR /src
RUN echo "Finding build artifacts" && \
    apkPath=$(find ${APK_FOLDER} -name "*.apk" | head -1) && \
    if [ -z ${apkPath} ] ; then echo "No apks were found, skip publishing to App Center" ; \
    else \ 
        echo "Found apk at $apkPath" && \
        echo "Pushing to app center" && \
        appcenter distribute release \
        --group Collaborators \
        --file "${apkPath}" \
        --release-notes "${RELEASENOTES}" \
        --app "${OWNERNAME}/${APPNAME}" \
        --token "${APPCENTER_ACCESS_TOKEN}" \
        --quiet && \
        echo "Pushed to app center" \
    ; fi