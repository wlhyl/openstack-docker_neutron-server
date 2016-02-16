# image name lzh/neutron-server:liberty
FROM 10.64.0.50:5000/lzh/openstackbase:liberty

MAINTAINER Zuhui Liu penguin_tux@live.com

ENV BASE_VERSION 2015-01-07
ENV OPENSTACK_VERSION liberty
ENV BUID_VERSION 2016-02-16

RUN yum update -y && \
         yum install -y openstack-neutron openstack-neutron-ml2 && \
         rm -rf /var/cache/yum/*

RUN cp -rp /etc/neutron/ /neutron && \
         rm -rf /etc/neutron/* && \
         rm -rf /var/log/neutron/*

VOLUME ["/etc/neutron"]
VOLUME ["/var/log/neutron"]

ADD entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

ADD neutron-server.ini /etc/supervisord.d/neutron-server.ini

EXPOSE 9696

ENTRYPOINT ["/usr/bin/entrypoint.sh"]