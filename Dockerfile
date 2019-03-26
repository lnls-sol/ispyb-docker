#FROM dockcs.esrf.fr/cs/debian8:latest
FROM debian:9

MAINTAINER Alejandro DE MARIA <demariaa@esrf.fr>

#############################
# ESRF specific for testing
#############################
#ENV proxy proxy.esrf.fr 
#ENV proxy_port 3128
#ENV http_proxy http://$proxy:$proxy_port
#ENV https_proxy https://$proxy:$proxy_port



# Profile GENERIC and env develpment are default
#ENV profile GENERIC

#ISPyB repository
ENV repository https://github.com/lnls-sol/ISPyB.git
ENV branch manaca

#ISPyB-client repository
#ENV client_repository https://github.com/ispyb/ispyb-client.git
#ENV client_branch master 

ENV DEBIAN_FRONTEND noninteractive
ENV JAVA_HOME /opt/jdk

#######################
# PACKAGES
#######################

RUN apt-get update 
RUN apt-get install -y wget unzip supervisor mysql-server mysql-client git vim python-suds python-pip 
RUN pip install requests

#######################
# INSTALLING JAVA
#######################

RUN cd /opt &&  wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz -O jdk.tar.gz

# Extract and create link
RUN cd /opt && tar xvfz jdk.tar.gz && ln -s jdk1.8.0_201 jdk

#######################
# INSTALLING MAVEN
#######################

RUN cd /opt && wget http://mirrors.standaloneinstaller.com/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.zip && unzip apache-maven-3.3.9-bin.zip

#COPY config/settings.xml /root/.m2/settings.xml

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

        # Just copying the already downloaded repo
        #RUN cd /opt && git clone $repository && cd ISPyB && git checkout $branch
        COPY ISPyB /opt/ISPyB

        #############################
        # REPLACE AUTHENTICATOR
        #############################

        COPY java/AuthenticationRestWebService.java /opt/ISPyB/ispyb-ws/src/main/java/ispyb/ws/rest/security/AuthenticationRestWebService.java

        #############################
        # REPLACE POM.XML
        #############################

        #COPY java/pom.xml /opt/ISPyB/ispyb-ejb/pom.xml


        #############################
        # BUILDING LATEST VERSION
        #############################

        ENV PATH $JAVA_HOME/jre/bin:/opt/apache-maven-3.3.9/bin:$PATH
        WORKDIR /opt/ISPyB/dependencies

        RUN mvn install:install-file -Dfile=securityfilter.jar -DgroupId=securityfilter -DartifactId=securityfilter -Dversion=1.0 -Dpackaging=jar
        RUN mvn install:install-file -Dfile=securityaes.jar -DgroupId=securityaes -DartifactId=securityaes -Dversion=1.0 -Dpackaging=jar
        RUN mvn install:install-file -Dfile=jhdf.jar -DgroupId=jhdf -DartifactId=jhdf -Dversion=1.0 -Dpackaging=jar
        RUN mvn install:install-file -Dfile=jhdf5.jar -DgroupId=jhdf5 -DartifactId=jhdf5 -Dversion=1.0 -Dpackaging=jar
        RUN mvn install:install-file -Dfile=jhdf5obj.jar -DgroupId=jhdf5obj -DartifactId=jhdf5obj -Dversion=1.0 -Dpackaging=jar
        RUN mvn install:install-file -Dfile=jhdfobj.jar -DgroupId=jhdfobj -DartifactId=jhdfobj -Dversion=1.0 -Dpackaging=jar
        RUN mvn install:install-file -Dfile=Struts-Layout-1.2.jar -DgroupId=struts-layout -DartifactId=struts-layout -Dversion=1.2 -Dpackaging=jar
        RUN mvn install:install-file -Dfile=ojdbc6.jar -DgroupId=ojdbc6 -DartifactId=ojdbc6 -Dversion=1.0 -Dpackaging=jar
        RUN mvn install:install-file -Dfile=ispyb-userportal-gen-1.5.jar -DgroupId=ispyb -DartifactId=ispyb-userportal-gen -Dversion=1.5 -Dpackaging=jar

	WORKDIR /opt/ISPyB
        RUN sed -i 's/${jboss.modules.base}/\/opt\/wildfly\/modules\/system\/layers\/base/g' ispyb-ui/pom.xml
        RUN sed -i 's/${jboss.modules.base}/\/opt\/wildfly\/modules\/system\/layers\/base/g' ispyb-bcr/pom.xml
        RUN mvn clean install
	
	#############################
        # DEPLOY ISPyB
        #############################

        RUN cp /opt/ISPyB/ispyb-ear/target/ispyb.ear /opt/wildfly/standalone/deployments/ispyb.ear
	
