# CODE FROM https://github.com/electron-userland/electron-builder/blob/master/docker/base/Dockerfile
FROM buildpack-deps:bionic-curl

########
# base #
########

ENV DEBIAN_FRONTEND noninteractive

RUN curl -L https://yarnpkg.com/latest.tar.gz | tar xvz && mv yarn-* /yarn && ln -s /yarn/bin/yarn /usr/bin/yarn
RUN apt-get -qq update && apt-get -qq dist-upgrade && \
  # add repo for git-lfs
  curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
  # git ssh for using as docker image on CircleCI
  # python for node-gyp
  # rpm is required for FPM to build rpm package
  # libsecret-1-dev and libgnome-keyring-dev are required even for prebuild keytar
  apt-get -qq install --no-install-recommends qtbase5-dev bsdtar build-essential autoconf libssl-dev gcc-multilib g++-multilib lzip rpm python libcurl4 git git-lfs ssh unzip \
  libsecret-1-dev libgnome-keyring-dev \
  libopenjp2-tools && \
  # git-lfs
  git lfs install && \
  apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/*


WORKDIR /project

# fix error /usr/local/bundle/gems/fpm-1.5.0/lib/fpm/package/freebsd.rb:72:in `encode': "\xE2" from ASCII-8BIT to UTF-8 (Encoding::UndefinedConversionError)
# http://jaredmarkell.com/docker-and-locales/
# http://askubuntu.com/a/601498
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

ENV DEBUG_COLORS true
ENV FORCE_COLOR true

################
# install node #
################
ENV NODE_VERSION 12.14.1

# this package is used for snapcraft and we should not clear apt list - to avoid apt-get update during snap build
RUN curl -L https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz | tar xz -C /usr/local --strip-components=1 && \
  unlink /usr/local/CHANGELOG.md && unlink /usr/local/LICENSE && unlink /usr/local/README.md && \
  # https://github.com/npm/npm/issues/4531
  npm config set unsafe-perm true

################
# install wine #
################

RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common && dpkg --add-architecture i386 && curl -L https://dl.winehq.org/wine-builds/winehq.key > winehq.key && apt-key add winehq.key && apt-add-repository https://dl.winehq.org/wine-builds/ubuntu && \
  apt-get update && \
  apt-get -y purge software-properties-common libdbus-glib-1-2 python3-dbus python3-gi python3-pycurl python3-software-properties && \
  apt-get install -y --no-install-recommends winehq-stable && \
  # clean
  apt-get clean && rm -rf /var/lib/apt/lists/* && unlink winehq.key

RUN curl -L https://github.com/electron-userland/electron-builder-binaries/releases/download/wine-2.0.3-mac-10.13/wine-home.zip > /tmp/wine-home.zip && unzip /tmp/wine-home.zip -d /root/.wine && unlink /tmp/wine-home.zip

ENV WINEDEBUG -all,err+all
ENV WINEDLLOVERRIDES winemenubuilder.exe=d

################
# install wine #
################

RUN apt-get update && apt-get install -y jq && \
  curl -L https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 -o /usr/bin/yq && chmod u+x /usr/bin/yq
