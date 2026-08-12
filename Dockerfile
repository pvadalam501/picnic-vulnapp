FROM eclipse-temurin:8-jdk as BUILDAPP

RUN mkdir /workspace
WORKDIR /workspace
COPY app .

RUN ./gradlew build

  
FROM ubuntu:18.04

LABEL maintainer Ihab Hag Shamas "ihab.hagshamas@teampicnic.com"

ADD NAME .
ADD VERSION .

EXPOSE 8080 20 21 139 445 6200 137/udp 138/udp

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y

WORKDIR /root/

### FTP Part ###

COPY vsftpd/* /root/

RUN mkdir /usr/share/empty/ && \
	mkdir /var/ftp/ && \
	useradd -d /var/ftp ftp

RUN chown root.root /var/ftp && \
	chmod og-w /var/ftp

RUN mv vsftpd /usr/local/sbin/vsftpd && \
	mv vsftpd.conf /etc/

RUN echo 'echo Started FTP Server@ `hostname -i 2>/dev/null`:21' > /root/run.sh && \
	echo "/usr/local/sbin/vsftpd &" >> /root/run.sh && \
	echo 'echo Started Web App' >> /root/run.sh && \
	echo "java -jar ./spring-boot-app.jar" >> /root/run.sh


RUN mkdir /workspace && mkdir /entrypoint && \
	ln -s /workspace /appspace && \
	chmod -R 0777 /workspace && chmod +x /workspace;

WORKDIR /workspace

# Setup JDK
RUN apt-get update && \
	apt-get install -y openjdk-8-jdk && \
	apt-get install -y ant && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/cache/oracle-jdk8-installer;

RUN apt-get update && \
	apt-get install -y ca-certificates-java && \
	apt-get clean && \
	update-ca-certificates -f && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/cache/oracle-jdk8-installer;

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

### WebApp Part ###

COPY --from=BUILDAPP /workspace/build/libs/*.jar spring-boot-app.jar

ENTRYPOINT ["/bin/bash", "-c", "/bin/bash /root/run.sh"]
