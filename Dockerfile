FROM java:jdk

LABEL maintainer "yury.sannikov@gmail.com"

ENV DEBIAN_FRONTEND noninteractive

################################################################################################
###
### Environment variables
###
# Android & Gradle
ENV GRADLE_URL http://services.gradle.org/distributions/gradle-3.3-all.zip
ENV GRADLE_HOME /usr/local/gradle-3.3
ENV ANDROID_SDK_URL http://dl.google.com/android/android-sdk_r24.0.2-linux.tgz
ENV ANDROID_HOME /usr/local/android-sdk-linux
ENV ANDROID_SDK_COMPONENTS platform-tools,build-tools-23.0.1,android-23,extra-android-support,extra-android-m2repository

# NodeJS
ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 7.4.0

#Ruby
ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.3
ENV RUBY_DOWNLOAD_SHA256 1a4fa8c2885734ba37b97ffdb4a19b8fba0e8982606db02d936e65bac07419dc
ENV RUBYGEMS_VERSION 2.6.10
ENV BUNDLER_VERSION 1.14.3


################################################################################################
###
### Install Android SDK & Build Tools
###

# Dependencies
RUN dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -yq libstdc++6:i386 zlib1g:i386 libncurses5:i386 ant maven --no-install-recommends \
  && curl -L ${GRADLE_URL} -o /tmp/gradle-3.3-all.zip \
  && unzip /tmp/gradle-3.3-all.zip -d /usr/local \
  && rm /tmp/gradle-3.3-all.zip \
  && curl -L ${ANDROID_SDK_URL} | tar xz -C /usr/local \
  && mkdir -p  /usr/local/opt/ \
  && ln -s /usr/local/android-sdk-linux /usr/local/opt/android-sdk \
  && (while sleep 3; do echo "y"; done) | ${ANDROID_HOME}/tools/android update sdk --no-ui --all --filter "${ANDROID_SDK_COMPONENTS}"


################################################################################################
###
### Install NodeJS & NPM
###

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done


RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

################################################################################################
###
### Install Ruby & bundler
###

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -ex \
  \
  && buildDeps=' \
    bison \
    libgdbm-dev \
    ruby \
    autoconf bison build-essential libssl-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev \
  ' \
  && apt-get install -y libtool libyaml-dev imagemagick \
  && apt-get install -y --no-install-recommends $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  \
  && wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - \
  \
  && mkdir -p /usr/src/ruby \
  && tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.xz \
  \
  && cd /usr/src/ruby \
  \
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
  && { \
    echo '#define ENABLE_PATH_CHECK 0'; \
    echo; \
    cat file.c; \
  } > file.c.new \
  && mv file.c.new file.c \
  \
  && autoconf \
  && ./configure --disable-install-doc --enable-shared \
  && make -j"$(nproc)" \
  && make install \
  \
  && cd / \
  && rm -r /usr/src/ruby \
  \
  && gem update --system "$RUBYGEMS_VERSION"


RUN gem install bundler --version "$BUNDLER_VERSION"

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
  && chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

# Path
ENV PATH $PATH:$BUNDLE_BIN:${ANDROID_HOME}/tools:$ANDROID_HOME/platform-tools:${GRADLE_HOME}/bin


################################################################################################
###
### Install Fastlane and plugins
###

RUN gem install fastlane -NV \
  && gem install fastlane-plugin-appicon fastlane-plugin-android_change_string_app_name fastlane-plugin-humanable_build_number \
  && gem update --system "$RUBYGEMS_VERSION"

# Remove Build Deps
RUN apt-get purge -y --auto-remove $buildDeps

# Output versions
RUN node -v && npm -v && ruby -v && bundler -v
