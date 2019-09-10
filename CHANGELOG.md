# Changelog
All notable changes to this project will be documented in this file.



## [0.0.1] - 2019-09-10
Initial release.
### Added
- Based on alexberkovich/alpine-openjdk - AlpineLinux with a glibc-2.29-r0 and Oracle Java 8
- Tomcat 8.5.24
- Tomcat Native 1.2.17
- In the child build you should provide TOMCAT_SERVER_XMS, TOMCAT_SERVER_XMX, TOMCAT_SERVER_NEW_SIZE, TOMCAT_SERVER_MAX_NEW_SIZE, 
TOMCAT_SERVER_USERNAME, TOMCAT_SERVER_PASSWORD 
- Tomcat installation has couple of fixes:
* setenv.sh has paramters for JVM that will start Tomcat. It also has -Xdebug and couple of ther swithces. 
* JPDA port (remote debug port) is 8100
* JMX port is 8086
* -Xms$TOMCAT_SERVER_XMS, -XX:NewSize=$TOMCAT_SERVER_NEW_SIZE, -XX:MaxNewSize=$TOMCAT_SERVER_MAX_NEW_SIZE
(will be set in the child build)
* server.xml has undeployOldVersions="true" in order to enable parallel deployment. See http://tomcat.apache.org/tomcat-7.0-doc/config/context.html#Parallel_deployment
* $CATALINA_HOME/webapps/manager/META-INF/context.xml content of context is reamarked o enable access to Manager-Manager
* $CATALINA_HOME/webapps/host-manager/META-INF/context.xml content of context is reamarked o enable access to Host-Manager

- Tomcat installation has couple of more custom fixes:
* $CATALINA_HOME/conf/tomcat-users.xml define user with $TOMCAT_SERVER_USERNAME and $TOMCAT_SERVER_PASSWORD that 
has all relevant roles.
* There is symb link for logs.
* There is symb link for recovery folder.
* Tomcat start with jpda (remote debug is enabled by default).

<!--
### Changed
### Removed
-->
