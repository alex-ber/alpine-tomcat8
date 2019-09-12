# AlpineLinux with a glibc-2.29-r0 and Oracle Java 8
FROM alexberkovich/alpine-openjdk:0.0.1

# Java Version and other ENV
ENV JAVA_VERSION=8.212.04-r1 \
    JAVA_HOME=/usr/lib/jvm/default-jvm/
    #PATH=${PATH}:${JAVA_HOME}/bin

# Install & configure Tomcat
ARG TOMCAT_VERSION=8.5.24
ARG TOMCAT_MAJOR_VERSION=8
ARG TOMCAT_NATIVE_VERSION=1.2.17

ENV TOMCAT_MAJOR_VERSION=$TOMCAT_MAJOR_VERSION
ENV TOMCAT_VERSION=$TOMCAT_VERSION
ENV TOMCAT_NATIVE_VERSION=$TOMCAT_NATIVE_VERSION
ENV CATALINA_HOME=/opt/tomcat
ENV CLASSPATH=$CLASSPATH:$CATALINA_HOME/common/lib
ENV PATH=$PATH:$CATALINA_HOME/bin

RUN set -ex
RUN apk add --no-cache apr-dev=1.6.3-r1 make=4.2.1-r2 openssl-dev=1.0.2r-r0 gcc=6.4.0-r9 musl-dev=1.1.19-r11

#copy&paste
ENV GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc
ENV GLIBC_VERSION=2.29-r0


## let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR=$CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH=${TOMCAT_NATIVE_LIBDIR}:$LD_LIBRARY_PATH

#ENV setenv.sh
ONBUILD ARG TOMCAT_SERVER_XMS
ONBUILD ARG TOMCAT_SERVER_NEW_SIZE
ONBUILD ARG TOMCAT_SERVER_MAX_NEW_SIZE
ONBUILD ARG TOMCAT_SERVER_USERNAME
ONBUILD ARG TOMCAT_SERVER_PASSWORD

#GLIBC
# do all in one step
RUN set -ex && \
    #Remarked by Alex \
    #[[ ${JAVA_VERSION_MAJOR} != 7 ]] || ( echo >&2 'Oracle no longer publishes JAVA7 packages' && exit 1 ) && \
    #Remarked by Alex \
    #apk -U upgrade && \
    #Alex added --no-cache
    apk --no-cache add libstdc++=6.4.0-r9 curl=7.61.1-r2 ca-certificates=20190108-r0 bash=4.4.19-r1 && \
    #Added  by Alex \
    #Alex added --no-cache
    apk --no-cache add net-tools=1.60_git20140218-r2 nano=2.9.8-r0 && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    #Alex added --no-cache
    apk --no-cache add /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    mkdir /opt


#Tomcat
#RUN curl -s -L --url "http://www.us.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" | tar xz -C /opt \
RUN curl -s -L --url "http://mirror.23media.de/apache/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" | tar xz -C /opt \
&& ln -s /opt/apache-tomcat-${TOMCAT_VERSION} ${CATALINA_HOME}
#Alex remark
#&& rm -rf ${CATALINA_HOME}/webapps/* \
#Alex remark
#&& sed -i 's/redirectPort="8443"/redirectPort="8443" URIEncoding="UTF-8"/g' ${CATALINA_HOME}/conf/server.xml \


#Tomcat Native
WORKDIR ${CATALINA_HOME}

RUN wget https://archive.apache.org/dist/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE_VERSION}/source/tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz \
&& curl -s https://archive.apache.org/dist/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE_VERSION}/source/tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz.sha512 | sha512sum \
#&& chown root:root tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz \
&& tar -xvf tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz \
&& cd tomcat-native-*/native \
&& ./configure --libdir="$TOMCAT_NATIVE_LIBDIR" \
--with-java-home=$JAVA_HOME --with-os-type=jre --prefix=$CATALINA_HOME --with-ssl=yes; \
make && make install

#------------------------------------ Tomcat general fixes ---------------------------
#setenv.sh
RUN set -ex && \
    echo -e '#!/bin/sh\n' > $CATALINA_HOME/bin/setenv.sh; \
    echo -e 'cd $CATALINA_BASE\n' >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'JAVA_OPTS="${JAVA_OPTS} -Dfile.encoding=UTF-8 -server -XX:+DisableExplicitGC -XX:+CMSClassUnloadingEnabled"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'JAVA_OPTS="${JAVA_OPTS} -Xdebug"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo '#JAVA_OPTS="${JAVA_OPTS} -Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo -e 'TOMCAT_HOSTNAME=$(hostname -i)\n'  >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'JAVA_OPTS="${JAVA_OPTS} -Djava.rmi.server.hostname=$TOMCAT_HOSTNAME''"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'JPDA_ADDRESS=8100' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.port=8086"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.ssl=false"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'CATALINA_OPTS="${CATALINA_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'CATALINA_OPTS="${CATALINA_OPTS} -XX:+CMSClassUnloadingEnabled -XX:+CMSPermGenSweepingEnabled"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    chmod 750 $CATALINA_HOME/bin/setenv.sh;

ONBUILD RUN set -ex && \
    echo 'JAVA_HOME='$JAVA_HOME >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'JAVA_OPTS="${JAVA_OPTS} -Xms'$TOMCAT_SERVER_XMS '"' \
        >> $CATALINA_HOME/bin/setenv.sh; \
    echo 'JAVA_OPTS="${JAVA_OPTS} -XX:NewSize='$TOMCAT_SERVER_NEW_SIZE '-XX:MaxNewSize='$TOMCAT_SERVER_MAX_NEW_SIZE'"' \
        >> $CATALINA_HOME/bin/setenv.sh;


#Enables parallel deployment, see http://tomcat.apache.org/tomcat-7.0-doc/config/context.html#Parallel_deployment
RUN sed -i 's/autoDeploy="true"/autoDeploy="true" undeployOldVersions="true"/g' ${CATALINA_HOME}/conf/server.xml

#To enable access to Manager-Manager, content of context tag should be reamarked, other
ENV filename=$CATALINA_HOME/webapps/manager/META-INF/context.xml
#starting remark
RUN sed -i "$(( $( wc -l < $filename) -3 ))i <\!--" $filename
#ending remark
RUN sed -i '$i\
-->' $filename

#To enable access to Host-Manager, content of context tag should be reamarked, other
ENV filename=$CATALINA_HOME/webapps/host-manager/META-INF/context.xml
#starting remark
RUN sed -i "$(( $( wc -l < $filename) -2 ))i <\!--" $filename
#ending remark
RUN sed -i '$i\
-->' $filename
ENV filename=

#---------------- Tomcat custom fixes -------------------------------------------------
#tomcat-users.xml
#remoove last line, closing tag of tomcat-users,
#adding user with all roles
ONBUILD RUN set -ex && \
    sed -i '$ d' $CATALINA_HOME/conf/tomcat-users.xml; \
    echo -e '<user username="'$TOMCAT_SERVER_USERNAME'" password="'$TOMCAT_SERVER_PASSWORD'" \n\
    roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>' \
        >> $CATALINA_HOME/conf/tomcat-users.xml; \
    echo '</tomcat-users>' \
        >> $CATALINA_HOME/conf/tomcat-users.xml;


#Create symb link for logs
RUN ln -s /opt/apache-tomcat-${TOMCAT_VERSION}/logs /root/logs
#Create symb link for recovery (we want to store recovery files inside tomcat's log directory)
RUN ln -s /opt/apache-tomcat-${TOMCAT_VERSION}/logs/recovery /opt/apache-tomcat-${TOMCAT_VERSION}/recovery


#Cleanup
RUN set -ex && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* \
&& rm -rf tomcat-native*
WORKDIR /
RUN apk del glibc-i18n make gcc musl-dev
RUN rm -rf /var/cache/apk/*


EXPOSE 8080 8100 8086 9001


#VOLUME ${CATALINA_HOME}/webapps
#CMD tail -f /dev/null
CMD catalina.sh jpda run


#docker rmi -f run-env
#docker rm -f runtime
#docker build --squash . -t run-env
#docker run --name runtime -d -p8080:8080 -p8100:8100 -p8086:8086 -p9001:9001 -h=alex run-env
#smoke test
#docker exec -it $(docker ps -q -n=1) ps aux | grep java
#docker exec -it $(docker ps -q -n=1) bash
#docker tag run-env alexberkovich/alpine-tomcat8
#docker push alexberkovich/alpine-tomcat8

# EOF