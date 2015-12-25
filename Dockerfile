# image name lzh/neutron-server:liberty
FROM 10.64.0.50:5000/lzh/openstackbase:liberty

MAINTAINER Zuhui Liu penguin_tux@live.com

ENV BASE_VERSION 2015-12-24
ENV OPENSTACK_VERSION liberty
ENV BUILD_VERSION 2015-12-25

RUN yum update -y
RUN yum install -y openstack-neutron openstack-neutron-ml2
RUN yum clean all
RUN rm -rf /var/cache/yum/*

RUN cp -rp /etc/neutron/ /neutron
RUN rm -rf /etc/neutron/*
RUN rm -rf /var/log/neutron/*

VOLUME ["/etc/neutron"]
VOLUME ["/var/log/neutron"]

ADD entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

ADD neutron-server.ini /etc/supervisord.d/neutron-server.ini

EXPOSE 9696

ENTRYPOINT ["/usr/bin/entrypoint.sh"]