# Dockerfile: jdk7, sdk, android19/21, studio, ndk, ant, gradle
# user account setup: to access kvm, etc. system facilities,
# "dev" user inside container must have same user-id/group-id 
# as host user who run the container, also added to "kvm" 
# and "libvirtd" groups as host user.
# Here are the assumption of this dockerfile:
# userid: 1234; groupid:1245
# kvm groupid: 123; libvirtd groupid: 124
# changed them according to your system's settings
#
FROM ubuntu:14.04

MAINTAINER Yigong Liu yigongliu@gmail.com

# Never ask for confirmations
ENV DEBIAN_FRONTEND noninteractive

# add i386
RUN dpkg --add-architecture i386 && apt-get update

# add oracle license
RUN echo "debconf shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
RUN echo "debconf shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections

# install add-apt-repository and bzip2
RUN apt-get -y install software-properties-common python-software-properties bzip2 unzip openssh-client git lib32stdc++6 lib32z1

# Add oracle-jdk7 to repositories
RUN add-apt-repository ppa:webupd8team/java

# Update apt
RUN apt-get update

# Install oracle-jdk7
RUN apt-get -y install oracle-java7-installer

# install other dev tools
RUN apt-get install -y emacs iceweasel g++ ruby curl

# fix android-adt dependency.
RUN apt-get install -y libgtk2.0-0:i386 libcanberra-gtk-module  libcanberra-gtk-module:i386 libxtst6 libxtst6:i386

# make workspace
run mkdir /home/dev
run groupadd -g 1234 dev 
run useradd -d /home/dev -u 1234 -g 1234 dev
run mkdir -p /home/dev/go /home/dev/bin /home/dev/lib /home/dev/include 
run mkdir -p /home/dev/workspace 
run mkdir -p /home/dev/tools 
run chown -R dev:dev /home/dev

env PATH /home/dev/bin:$PATH
env PKG_CONFIG_PATH /home/dev/lib/pkgconfig
env LD_LIBRARY_PATH /home/dev/lib

#install kvm: kvm/libvirtd group id must match host settings
RUN groupadd -g 123 kvm && groupadd -g 124 libvirtd
RUN apt-get install -y qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils qemu-system virt-manager
RUN adduser dev libvirtd

#clean up apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create a shared data volume
# We need to create an empty file, otherwise the volume will
# belong to root.
# This is probably a Docker bug.
RUN mkdir /var/shared/ 
RUN touch /var/shared/placeholder 
RUN chown -R dev:dev /var/shared 
VOLUME /var/shared

# add dev env settings
# ADD dot_emacs /home/dev/.emacs
# RUN chown dev:dev /home/dev/.emacs

# switch to user "dev" to install android sdk
USER dev
ENV HOME /home/dev

# install tools

WORKDIR /home/dev/tools

# Install Gradle
RUN wget https://services.gradle.org/distributions/gradle-2.1-bin.zip
RUN unzip gradle-2.1-bin.zip
RUN rm gradle-2.1-bin.zip

# Install ant
RUN curl -sSL http://mirrors.ibiblio.org/apache//ant/binaries/apache-ant-1.9.4-bin.tar.gz | tar -v -C /home/dev/tools -xz

# install sdk tools. whenever android sdk update, increase version number here
RUN curl -sSL http://dl.google.com/android/android-sdk_r24.0.1-linux.tgz | tar -v -C /home/dev/tools -xz

# prepare for update android sdk tools, old files seems blocking update
RUN mv /home/dev/tools/android-sdk-linux/tools /home/dev/tools/android-sdk-linux/tools.old
RUN ln -s /home/dev/tools/android-sdk-linux/tools.old /home/dev/tools/android-sdk-linux/tools

# update Android sdk tools
RUN echo y | /home/dev/tools/android-sdk-linux/tools/android update sdk --filter tools,platform-tools,build-tools-21.1.2 --no-ui --force -a
#RUN echo y | /home/dev/tools/android-sdk-linux/tools/android update sdk --filter platform-tools,build-tools-21.1.2 --no-ui --force -a

#clean up
RUN rm -fr /home/dev/tools/android-sdk-linux/*.old

# install android 4.4 platforms
RUN echo y | /home/dev/tools/android-sdk-linux/tools/android update sdk --filter android-19,sys-img-armeabi-v7a-android-19,addon-google_apis-google-19 --no-ui --force -a

# Install android studio, increase version number for new releases
RUN wget https://dl.google.com/dl/android/studio/ide-zips/1.0.1/android-studio-ide-135.1641136-linux.zip
RUN unzip android-studio-ide-135.1641136-linux.zip 
RUN rm android-studio-ide-135.1641136-linux.zip

# install android 5.0 platforms
RUN echo y | /home/dev/tools/android-sdk-linux/tools/android update sdk --filter doc-21,source-21,android-21,sample-21,sys-img-x86_64-android-21,addon-google_apis-google-21,sys-img-x86_64-addon-google_apis-google-21,extra-android-support,extra-google-webdriver --no-ui --force -a

# Install Android NDK
RUN wget http://dl.google.com/android/ndk/android-ndk-r10d-linux-x86_64.bin
RUN chmod a+x android-ndk-r10d-linux-x86_64.bin 
RUN ./android-ndk-r10d-linux-x86_64.bin 
RUN rm android-ndk-r10d-linux-x86_64.bin

# Install eclipse jee, for eclipse lover
RUN curl -sSL http://mirror.netcologne.de/eclipse/technology/epp/downloads/release/luna/SR1/eclipse-jee-luna-SR1-linux-gtk-x86_64.tar.gz | tar -v -C /home/dev/tools -xz

# Environment variables
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle
ENV STUDIO_HOME /home/dev/tools/android-studio
ENV ANDROID_SDK_HOME /home/dev/tools/android-sdk-linux
ENV ECLIPSE_HOME /home/dev/tools/eclipse
ENV ANDROID_NDK_HOME /home/dev/tools/android-ndk-r10d
ENV GRADLE_HOME /home/dev/tools/gradle-2.1
ENV ANT_HOME /home/dev/tools/apache-ant-1.9.4
ENV PATH $PATH:$ANDROID_SDK_HOME/tools
ENV PATH $PATH:$ANDROID_SDK_HOME/platform-tools
ENV PATH $PATH:$STUDIO_HOME/bin
ENV PATH $PATH:$ECLIPSE_HOME
ENV PATH $PATH:$ANDROID_NDK_HOME
ENV PATH $PATH:$GRADLE_HOME/bin
ENV PATH $PATH:$ANT_HOME/bin

# force 32bit for emulator to work
ENV ANDROID_EMULATOR_FORCE_32BIT true

WORKDIR /home/dev

CMD ["/bin/bash"]
