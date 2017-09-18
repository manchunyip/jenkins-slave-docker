FROM jenkinsci/slave:alpine

USER root
RUN apk add --no-cache \
ca-certificates \
curl \
openssl && \
   rm -rf /var/cache/apk/*

#########ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_BUCKET download.docker.com
#ENV DOCKER_VERSION 17.04.0-ce
ENV DOCKER_VERSION 17.06.0-ce
#ENV DOCKER_SHA256 c52cff62c4368a978b52e3d03819054d87bcd00d15514934ce2e0e09b99dd100
ENV DOCKER_SHA256 e582486c9db0f4229deba9f8517145f8af6c5fae7a1243e6b07876bd3e706620 

RUN set -x \
&& wget "https://${DOCKER_BUCKET}/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
&& echo "${DOCKER_SHA256} *docker-${DOCKER_VERSION}.tgz" | sha256sum -c - \
&& tar -xzvf docker-${DOCKER_VERSION}.tgz \
&& mv docker/* /usr/local/bin/ \
&& rmdir docker \
&& rm docker-${DOCKER_VERSION}.tgz \
&& docker -v

#RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.7.3/bin/linux/amd64/kubectl

RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

COPY docker-entrypoint.sh /usr/local/bin/

COPY jenkins-slave /usr/local/bin/jenkins-slave

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/jenkins-slave

# Set desired Android Linux SDK version
ENV ANDROID_SDK_VERSION 24.4.1

ENV ANDROID_SDK_ZIP android-sdk_r$ANDROID_SDK_VERSION-linux.tgz
ENV ANDROID_SDK_ZIP_URL https://dl.google.com/android/$ANDROID_SDK_ZIP
ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_API_LEVELS android-23,android-24 


ENV GRADLE_ZIP gradle-3.0-bin.zip
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/$GRADLE_ZIP

ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools
ENV PATH $PATH:/opt/gradle-3.0/bin

USER root

# Init dependencies for the setup process
#RUN dpkg --add-architecture i386

#RUN apt-get update && \
#	apt-get install software-properties-common unzip -y
#RUN apt-get update && \
#	apt-get install software-properties-common unzip -y

RUN apk update && apk add openjdk7 bash && \
    mkdir /opt && cd /opt && \
    wget -q ${ANDROID_SDK_ZIP_URL} && \
    tar -xzf ${ANDROID_SDK_ZIP} && \
    rm ${ANDROID_SDK_ZIP} && \
    echo y | android update sdk --no-ui -a --filter tools,platform-tools,${ANDROID_API_LEVELS},build-tools-${ANDROID_BUILD_TOOLS_VERSION} --no-https && \
    rm /var/cache/apk/*    

# Install gradle
ADD $GRADLE_ZIP_URL /opt/
RUN unzip /opt/$GRADLE_ZIP -d /opt/ && \
	rm /opt/$GRADLE_ZIP

# Install Android SDK
#ADD $ANDROID_SDK_ZIP_URL /opt/
#RUN tar xzvf /opt/$ANDROID_SDK_ZIP -C /opt/ && \
#	rm /opt/$ANDROID_SDK_ZIP

# Install required build-tools
#RUN	echo "y" | android update sdk -u -a --filter platform-tools,android-23,build-tools-23.0.3 && \
#	chmod -R 777 $ANDROID_HOME
	
#RUN	echo "y" | android update sdk -u -a --filter platform-tools,android-24,build-tools-24.0.1 && \
#	chmod -R 777 $ANDROID_HOME
#RUN chmod -R 777 $ANDROID_HOME

# Install 32-bit compatibility for 64-bit environments
#RUN apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 -y

# Create the license folder
RUN mkdir "$ANDROID_HOME/licenses" || true
RUN echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > "$ANDROID_HOME/licenses/android-sdk-license"
RUN echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"

# Cleanup
#RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER jenkins

# List desired Jenkins plugins here
#RUN /usr/local/bin/install-plugins.sh git gradle

ENTRYPOINT docker-entrypoint.sh; jenkins-slave

