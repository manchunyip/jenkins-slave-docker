FROM jenkinsci/jnlp-slave:3.10-1

# Set desired Android Linux SDK version
ENV ANDROID_SDK_VERSION 24.4.1

ENV ANDROID_SDK_ZIP android-sdk_r$ANDROID_SDK_VERSION-linux.tgz
ENV ANDROID_SDK_ZIP_URL https://dl.google.com/android/$ANDROID_SDK_ZIP
ENV ANDROID_HOME /opt/android-sdk-linux

ENV GRADLE_ZIP gradle-3.0-bin.zip
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/$GRADLE_ZIP

ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools
ENV PATH $PATH:/opt/gradle-3.0/bin

USER root

WORKDIR /opt

# Add docker client
# The version number is the docker version you want to move to
ENV DOCKER_VERION 17.05.0-ce
RUN wget https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERION}.tgz
RUN tar -zxvf docker-${DOCKER_VERION}.tgz
RUN cp docker/docker /usr/bin/
RUN rm -rf /opt/docker*

# Add kubectl client
ENV KUBECTL_VERSION 1.7.0
RUN wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN chmod +x kubectl
RUN mv kubectl /usr/bin/

RUN apt-get update

# Change /home/jenkins ownership to root
RUN chown -R root /home/jenkins

# Add python virtualenv and libs
#RUN apt-get install -y python-pip python-dev libxml2-dev libxslt1-dev zlib1g-dev
#RUN pip install virtualenv

# node.js
# versions: https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
#RUN curl -sL https://deb.nodesource.com/setup_6.x | bash
#RUN apt-get install -y nodejs
#RUN apt-get install -y npm nodejs-legacy
#RUN npm install -g jasmine-node

# install junit
#RUN apt-get install -y junit

# install bc - math expressions
#RUN apt-get install -y bc

# Installing envsubst for file variable substitution
#RUN apt-get install -y gettext-base

# Installing helm
# versions: https://github.com/kubernetes/helm#install
ENV HELM_VERSION 2.5.1
RUN wget https://kubernetes-helm.storage.googleapis.com/helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN tar -zxvf helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN cp linux-amd64/helm /usr/bin/
RUN rm -rf /opt/helm*

# Install gradle
ADD $GRADLE_ZIP_URL /opt/
RUN unzip /opt/$GRADLE_ZIP -d /opt/ && \
        rm /opt/$GRADLE_ZIP

# Install Android SDK
# ADD $ANDROID_SDK_ZIP_URL /opt/
RUN wget $ANDROID_SDK_ZIP_URL -P /opt/ && \
        tar xzvf /opt/$ANDROID_SDK_ZIP -C /opt/ && \
        rm /opt/$ANDROID_SDK_ZIP

# Install 32-bit compatibility for 64-bit environments
#RUN apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 -y

# Create the license folder
RUN mkdir "$ANDROID_HOME/licenses" || true
RUN echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > "$ANDROID_HOME/licenses/android-sdk-license"
RUN echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"

# Cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


ENTRYPOINT ["jenkins-slave"]
