FROM centos:centos7
MAINTAINER flyceek <flyceek@gmail.com>

ENV JAVA_WORK_HOME=/opt/soft/java
ENV JAVA_VERSION_MAJOR=8
ENV JAVA_VERSION_MINOR=141
ENV JAVA_VERSION_BUILD=15
ENV JAVA_JRE_FILE_NAME=server-jre-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz
ENV JAVA_JRE_FILE_EXTRACT_DIR=jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR}
ENV JAVA_DOWNLOAD_HASH=336fa29ff2bb4ef291e347e091f7f4a7
ENV JAVA_DOWNLOAD_URL=http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_DOWNLOAD_HASH}/${JAVA_JRE_FILE_NAME}

ENV JAVA_HOME=${JAVA_WORK_HOME}/${JAVA_JRE_FILE_EXTRACT_DIR}
ENV JRE_HOME=${JAVA_HOME}/jre
ENV CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar
ENV PATH=${PATH}:${JAVA_HOME}/bin:${JRE_HOME}/bin

ARG NEXUS_VERSION=3.5.1-02
ARG NEXUS_FILE_NAME=nexus-${NEXUS_VERSION}-unix.tar.gz
ARG NEXUS_FILE_EXTRACT_DIR=nexus-${NEXUS_VERSION}
ARG NEXUS_DOWNLOAD_URL=https://download.sonatype.com/nexus/3/${NEXUS_FILE_NAME}

ENV SONATYPE_DIR=/opt/soft/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus
ENV NEXUS_DATA=/nexus-data
ENV NEXUS_CONTEXT=''
ENV SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work

ENV INSTALL4J_ADD_VM_PARAMS="-Xms1200m -Xmx1200m"
ENV INSTALL4J_JAVA_HOME_OVERRIDE=${JAVA_HOME}

RUN yum install -y curl tar \
    && yum clean all \
    && mkdir -p ${JAVA_WORK_HOME} \
    && curl --location --retry 3 --header "Cookie: oraclelicense=accept-securebackup-cookie; " ${JAVA_DOWNLOAD_URL} | gunzip | tar -x -C ${JAVA_WORK_HOME} \
    && alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 1 \
    && alternatives --install /usr/bin/javac javac ${JAVA_HOME}/bin/javac 1 \
    && alternatives --install /usr/bin/jar jar ${JAVA_HOME}/bin/jar 1 \
    && mkdir -p ${NEXUS_HOME} \
    && curl --location --retry 3 ${NEXUS_DOWNLOAD_URL} | gunzip | tar x -C ${NEXUS_HOME} --strip-components=1 ${NEXUS_FILE_EXTRACT_DIR} \
    && chown -R root:root ${NEXUS_HOME} \
    && sed -e '/^nexus-context/ s:$:${NEXUS_CONTEXT}:' -i ${NEXUS_HOME}/etc/nexus-default.properties \
    && sed -e '/^-Xms/d' -e '/^-Xmx/d' -i ${NEXUS_HOME}/bin/nexus.vmoptions \
    && useradd -r -u 200 -m -c "nexus role account" -d ${NEXUS_DATA} -s /bin/false nexus \
    && mkdir -p ${NEXUS_DATA}/etc ${NEXUS_DATA}/log ${NEXUS_DATA}/tmp ${SONATYPE_WORK} \
    && ln -s ${NEXUS_DATA} ${SONATYPE_WORK}/nexus3 \
    && chown -R nexus:nexus ${NEXUS_DATA} \
    && echo "root:123321" | chpasswd

VOLUME ${NEXUS_DATA}
EXPOSE 8081
USER nexus
WORKDIR ${NEXUS_HOME}

CMD ["bin/nexus", "run"]