#FROM dockcs.esrf.fr/cs/debian8:latest
FROM debian:8

MAINTAINER Alejandro DE MARIA <demariaa@esrf.fr>

ENV profile ALBA

ENV proxy proxy.esrf.fr 
ENV proxy_port 3128

ENV http_proxy http://$proxy:$proxy_port
ENV https_proxy https://$proxy:$proxy_port

#ISPyB repository
ENV repository https://github.com/ispyb/ISPyB.git
ENV branch master

#ISPyB-client repository
ENV client_repository https://github.com/ispyb/ispyb-client.git
ENV client_branch master 

ENV DEBIAN_FRONTEND noninteractive
ENV JAVA_HOME /opt/jdk

#######################
# PACKAGES
#######################

RUN apt-get update && apt-get install -y wget unzip supervisor mysql-server mysql-client git vim python-suds python-pip && pip install requests

#######################
# INSTALLING JAVA
#######################

RUN cd /opt &&  wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u112-b15/jdk-8u112-linux-x64.tar.gz
RUN cd /opt && tar xvfz jdk-8u112-linux-x64.tar.gz && ln -s jdk1.8.0_112 jdk

#######################
# INSTALLING MAVEN
#######################

RUN cd /opt && wget http://mirrors.standaloneinstaller.com/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.zip && unzip apache-maven-3.3.9-bin.zip
COPY config/settings.xml /root/.m2/settings.xml

#######################
# INSTALLING WILDFLY
#######################

RUN wget http://download.jboss.org/wildfly/8.2.0.Final/wildfly-8.2.0.Final.zip && unzip wildfly-8.2.0.Final.zip && mv wildfly-8.2.0.Final/ /opt/wildfly-10.1.0.Final
RUN ln -s /opt/wildfly-10.1.0.Final /opt/wildfly

	#############################
	# CONFIGURING WILDFLY 
	#############################

	COPY config/standalone.xml /opt/wildfly/standalone/configuration/standalone.xml

	        #############################
		## SIMPLE AUTHENTICATOR
	        #############################
		COPY users/users.properties /opt/wildfly/standalone/configuration/users.properties
		COPY users/roles.properties /opt/wildfly/standalone/configuration/roles.properties

		#############################
		## MYSQL CONNECTOR
	        #############################
		COPY connector/mysql-connector-java-5.1.21.jar /opt/wildfly/modules/system/layers/base/com/mysql/main/mysql-connector-java-5.1.21.jar
         	COPY connector/module.xml /opt/wildfly/modules/system/layers/base/com/mysql/main/module.xml


#######################
# INSTALLING ISPyB
#######################

	#############################
	# DOWNLOADING ISPyB
	#############################

	RUN cd /opt && git clone $repository && cd ISPyB && git checkout $branch

	#############################
	# REPLACE AUTHENTICATOR
	#############################

	COPY java/AuthenticationRestWebService.java /opt/ISPyB/ispyb-ws/src/main/java/ispyb/ws/rest/security/AuthenticationRestWebService.java

        #############################
	# REPLACE POM.XML
	#############################

	COPY java/pom.xml /opt/ISPyB/ispyb-ejb/pom.xml


	#############################
	# BUILDING LATEST VERSION
	#############################

	RUN export PATH=$JAVA_HOME/jre/bin:$PATH && export PATH=/opt/apache-maven-3.3.9/bin:$PATH \ 
	&& cd /opt/ISPyB/dependencies \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=securityfilter.jar -DgroupId=securityfilter -DartifactId=securityfilter -Dversion=1.0 -Dpackaging=jar \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=securityaes.jar -DgroupId=securityaes -DartifactId=securityaes -Dversion=1.0 -Dpackaging=jar \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=jhdf.jar -DgroupId=jhdf -DartifactId=jhdf -Dversion=1.0 -Dpackaging=jar \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=jhdf5.jar -DgroupId=jhdf5 -DartifactId=jhdf5 -Dversion=1.0 -Dpackaging=jar \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=jhdf5obj.jar -DgroupId=jhdf5obj -DartifactId=jhdf5obj -Dversion=1.0 -Dpackaging=jar \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=jhdfobj.jar -DgroupId=jhdfobj -DartifactId=jhdfobj -Dversion=1.0 -Dpackaging=jar \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=Struts-Layout-1.2.jar -DgroupId=struts-layout -DartifactId=struts-layout -Dversion=1.2 -Dpackaging=jar \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=ojdbc6.jar -DgroupId=ojdbc6 -DartifactId=ojdbc6 -Dversion=1.0 -Dpackaging=jar \
	&& mvn -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  install:install-file -Dfile=ispyb-WSclient-userportal-gen-1.3.jar -DgroupId=ispyb -DartifactId=ispyb-WSclient-userportal-gen -Dversion=1.3 -Dpackaging=jar \
	&& cd /opt/ISPyB && sed -i 's/${jboss.modules.base}/\/opt\/wildfly\/modules\/system\/layers\/base/g' ispyb-ui/pom.xml \
        && cd /opt/ISPyB && sed -i 's/${jboss.modules.base}/\/opt\/wildfly\/modules\/system\/layers\/base/g' ispyb-bcr/pom.xml \
	&&  mvn clean install -P $profile -Dhttps.proxyHost=$proxy -Dhttps.proxyPort=$proxy_port  
	
	#############################
	# DEPLOY ISPyB
	#############################

	RUN cp /opt/ISPyB/ispyb-ear/target/ispyb.ear /opt/wildfly/standalone/deployments/ispyb.ear


#######################
# INSTALLING DB
#######################

	#############################
	# CREATING DB
	#############################

	RUN service mysql start \
	&& mysql -uroot -e "CREATE USER 'pxuser'@'%' IDENTIFIED BY 'pxuser';" \
	&& mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'pxuser'@'%';" \
	&& mysql -uroot -e "CREATE DATABASE pyconfig;"  \
	&& mysql -uroot -e "CREATE DATABASE pydb;" 

	#############################
	# CREATING SCHEMA
	#############################
 
	RUN service mysql start && mysql -upxuser -ppxuser -h localhost pyconfig < /opt/ISPyB/ispyb-ejb/db/pyconfig.sql

	#############################
	# Replacing pxadmin by pxuser
	#############################

	RUN service mysql start && sed -i 's/pxadmin/pxuser/g' /opt/ISPyB/ispyb-ejb/db/pydb.sql && mysql -upxuser -ppxuser -h localhost pydb < /opt/ISPyB/ispyb-ejb/db/pydb.sql && mysql -upxuser -ppxuser -h localhost pydb < /opt/ISPyB/ispyb-ejb/db/schemastatus.sql

	#############################
	# RUNNING SQL SCRIPTS
	#############################
	RUN service mysql start && for entry in /opt/ISPyB/ispyb-ejb/db/scripts/ahead/*; do  echo "Running " $entry; mysql -upxuser -ppxuser pydb < $entry; done


############################
# INGESTING
############################

	#############################
	# DOWNLOADING ISPyB-CLIENT
	#############################

	RUN cd /opt && git clone $client_repository && cd ispyb-client && git checkout $client_branch

	#############################
	# USER PORTAL
	#############################
        #RUN service mysql start && /opt/wildfly/bin/standalone.sh -b 0.0.0.0 && cd /opt/ispyb-client/python/userportal && python Ingester.py


#############################
# INSTALLING EXI
#############################

	#############################
	# DOWNLOADING APACHE TOMCAT
	#############################

	RUN cd /opt && wget http://wwwftp.ciril.fr/pub/apache/tomcat/tomcat-8/v8.5.14/bin/apache-tomcat-8.5.14.zip && unzip apache-tomcat-8.5.14.zip && ln -s apache-tomcat-8.5.14 tomcat
	RUN cd /opt  && chmod +x /opt/tomcat/bin/*sh
	RUN sed -i 's/8080/8090/g' /opt/tomcat/conf/server.xml

	#############################
	# INSTALLING NPM
	#############################

	RUN apt-get update && apt-get install -y npm nodejs-legacy 


	#############################
	# DOWNLOADING EXI
	#############################

	RUN cd /opt/tomcat/webapps && git clone https://github.com/ispyb/EXI.git

	#############################
	# BUILDING EXI
	#############################

	RUN echo '{ "proxy":"http://proxy.esrf.fr:3128", "https-proxy":"http://proxy.esrf.fr:3128"}' > /opt/tomcat/webapps/EXI/.bowerrc
	RUN npm config set strict-ssl false && npm config set proxy http://proxy.esrf.fr:3128 && npm config set https-proxy http://proxy.esrf.fr:3128 && cd /opt/tomcat/webapps/EXI && npm install && npm install -g bower --allow-root && npm install -g grunt && bower install --allow-root  && grunt --force

        
	
	
##################
# DOCKER SUPERVISOR
##################
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]
