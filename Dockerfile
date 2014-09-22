#
# Cassandra
# Debian:wheezy
# docker build -t meabed/cassandra:latest .
#
# sudo sysctl -w vm.max_map_count=2621444
# sudo su
# echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# you might need to run this commands in DOCKER HOST
# ulimit -l unlimited
# ulimit -n 16240
# ulimit -c unlimited

FROM debian:wheezy
MAINTAINER Mohamed Meabed "mo.meabed@gmail.com"

USER root
ENV DEBIAN_FRONTEND noninteractive

# Download and Install JDK / Hadoop
ENV JDK_VERSION 7

# install dev tools
RUN apt-get update
RUN apt-get install -y apt-utils curl tar openssh-server openssh-client rsync vim lsof

# ADD DataStax sources
RUN echo "deb http://debian.datastax.com/community stable main" | tee -a /etc/apt/sources.list.d/cassandra.sources.list
RUN curl -L http://debian.datastax.com/debian/repo_key | apt-key add -

RUN apt-get update


# passwordless ssh
RUN rm /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key

RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa

RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# java
RUN apt-get install -y openjdk-$JDK_VERSION-jre-headless

ENV JAVA_HOME /usr/lib/jvm/java-$JDK_VERSION-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin

# Install cassandra
RUN apt-get install -y dsc21
RUN apt-get install -y opscenter

# Comment the ulimit setters by cassandra deamon
RUN sed  -i "/^[^#]*ulimit/ s/.*/#&/"  /etc/init.d/cassandra


RUN service cassandra stop
RUN rm -rf /var/lib/cassandra/data/system/*

RUN sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

RUN sed -i "/^cluster_name:/ s|.*|cluster_name: 'iData Cluster'\n|" /etc/cassandra/cassandra.yaml
RUN sed -i "/^rpc_address:/ s|.*|rpc_address: 0.0.0.0\n|" /etc/cassandra/cassandra.yaml

VOLUME ["/data"]
RUN ln -svf /data/cassandra /var/lib/cassandra

RUN service ssh start && service opscenterd start && service cassandra start

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

VOLUME ["/data"]

CMD ["/etc/bootstrap.sh", "-d"]

# http://www.datastax.com/documentation/cassandra/2.1/cassandra/security/secureFireWall_r.html
EXPOSE 22 8888 7000 7001 7199 9160 9042 61620 61621
