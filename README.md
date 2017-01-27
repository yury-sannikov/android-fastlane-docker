# android-fastlane-docker
A Docker container with all toolchain to build react-native apps (Android) and deploy it through Fastlane 

# Build
```
./buildContainer
```

# Usage

Release Build
```
docker run -it -v /path/to/your/react-native/project/:/build -w /build android-fastlane-docker:latest /bin/sh -c "cd android && ./gradlew assembleRelease"
```

Fastlane Alpha
```
docker run -it -v /path/to/your/react-native/project/:/build -w /build android-fastlane-docker:latest /bin/sh -c "fastlane android alpha"
```
