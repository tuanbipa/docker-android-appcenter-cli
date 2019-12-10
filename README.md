# docker-android-appcenter-cli
Build docker image to publish android app to App Center

## Usage

1. Replace enviroments in Dockerfile
`APPCENTER_ACCESS_TOKEN, OWNERNAME, APPNAME, RELEASENOTES`.
Visit this page for more details.
https://github.com/microsoft/appcenter-cli

2. Add Dockerfile to the project directory.
3. Run this command to build docker image.
`docker build -t android-ci .`

