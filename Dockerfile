FROM jenkins:alpine
#COPY ./plugins.txt /usr/share/jenkins/plugins.txt

#We want a place for local source repos to be mirrored in to
VOLUME ["/repos", "/var/jenkins_home"]
USER root
RUN apk update && \
	apk add wget

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.

RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.23-r3" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

#We want jdk & maven to be predefined for localhost
ENV JAVA_VERSION=8 \
    JAVA_UPDATE=112 \
    JAVA_BUILD=15 \
    MVN_VERSION='3.3.9' \
    JDK_HOME="/usr/lib/jdk/default-jdk"


RUN cd "/tmp" && \
    wget --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
        "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}u${JAVA_UPDATE}-b${JAVA_BUILD}/jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    tar -xzf "jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    mkdir -p "/usr/lib/jdk" 
RUN mv "/tmp/jdk1.${JAVA_VERSION}.0_${JAVA_UPDATE}" "/usr/lib/jdk/java-${JAVA_VERSION}-oracle" && \
    ln -s "java-${JAVA_VERSION}-oracle" "$JDK_HOME" && \
    rm -rf "$JDK_HOME/"*src.zip && \
    rm "/tmp/"*

RUN wget http://ftp.fau.de/apache/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz
RUN tar -zxvf apache-maven-${MVN_VERSION}-bin.tar.gz
RUN rm apache-maven-${MVN_VERSION}-bin.tar.gz
RUN mv apache-maven-${MVN_VERSION} /usr/lib/mvn

#ENV JAVA_HOME /usr/lib/jvm/$
ENV JAVA=$JDK_HOME/bin
ENV M2_HOME=/usr/lib/mvn
ENV M2=$M2_HOME/bin

RUN cd /usr/share/jenkins/ref/plugins/; \
    install-plugins.sh git \
        Parameterized-Remote-Trigger \
        promoted-builds \
        filesystem_scm;


