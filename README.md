# android-fastlane-docker
A Docker container with all toolchain to build react-native apps (Android) and deploy it through Fastlane 

# Build
```
./buildContainer
```

# Components
```
openjdk version "1.8.0_111"
OpenJDK Runtime Environment (build 1.8.0_111-8u111-b14-2~bpo8+1-b14)
OpenJDK 64-Bit Server VM (build 25.111-b14, mixed mode)
```

| Component Name | Version |
|:---------------|--------:|
|gradle|3.3|
|android-sdk|24.0.2|
|build-tools|23.0.1|
|nodejs|7.4.0|
|npm|4.0.5|
|ruby|2.3.3|
|gems|2.6.10|
|bundler|1.14.3|

# Usage

Release Build
```
docker run -it -v /path/to/your/react-native/project/:/build -w /build android-fastlane-docker:latest /bin/sh -c "cd android && ./gradlew assembleRelease"
```

Fastlane Alpha
```
docker run -it -v /path/to/your/react-native/project/:/build -w /build android-fastlane-docker:latest /bin/sh -c "fastlane android alpha"
```
