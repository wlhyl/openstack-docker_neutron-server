#!/bin/bash

if [ -z "$NOVA_PASS" ];then
  echo "error: NOVA_PASS not set"
  exit 1
fi
if [ -z "$NEUTRON_DBPASS" ];then
  echo "error: NEUTRON_DBPASS not set"
  exit 1
fi

if [ -z "$NEUTRON_DB" ];then
  echo "error: NEUTRON_DB not set"
  exit 1
fi

if [ -z "$RABBIT_HOST" ];then
  echo "error: RABBIT_HOST not set"
  exit 1
fi

if [ -z "$RABBIT_USERID" ];then
  echo "error: RABBIT_USERID not set"
  exit 1
fi

if [ -z "$RABBIT_PASSWORD" ];then
  echo "error: RABBIT_PASSWORD not set"
  exit 1
fi

if [ -z "$KEYSTONE_ENDPOINT" ];then
  echo "error: KEYSTONE_ENDPOINT not set"
  exit 1
fi

if [ -z "$NEUTRON_PASS" ];then
  echo "error: NEUTRON_PASS not set. user nova password."
  exit 1
fi

# NOVA_URL pillar['nova']['endpoint']
if [ -z "$NOVA_URL" ];then
  echo "error: NOVA_URL not set. user nova password."
  exit 1
fi

CRUDINI='/usr/bin/crudini'

CONNECTION=mysql://neutron:$NEUTRON_DBPASS@$NEUTRON_DB/neutron
if [ ! -f /etc/neutron/.complete ];then
    cp -rp /neutron/* /etc/neutron

    chown neutron:neutron /var/log/netron/
    
    $CRUDINI --set /etc/neutron/neutron.conf database connection $CONNECTION

    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit

    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWORD

    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

    $CRUDINI --del /etc/neutron/neutron.conf keystone_authtoken

    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$KEYSTONE_ENDPOINT:5000
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$KEYSTONE_ENDPOINT:35357
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken project_name service
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken username netron
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASS
    
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT service_plugins router
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
    
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT nova_url http://${NOVA_URL}:8774/v2
    
    $CRUDINI --set /etc/neutron/neutron.conf nova auth_url http://$KEYSTONE_ENDPOINT:35357
    $CRUDINI --set /etc/neutron/neutron.conf nova auth_plugin password
    $CRUDINI --set /etc/neutron/neutron.conf nova project_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf nova user_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf nova region_name regionOne
    $CRUDINI --set /etc/neutron/neutron.conf nova project_name service
    $CRUDINI --set /etc/neutron/neutron.conf nova username nova
    $CRUDINI --set /etc/neutron/neutron.conf nova password $NOVA_PASS


    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
    
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 10:100
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini vxlan_group 224.0.0.1
    
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
    
    touch /etc/neutron/.complete
fi
# 同步数据库
echo 'select * from agents limit 1;' | mysql -h$NEUTRON_DB  -unetron -p$NEUTRON_DBPASS neutron
if [ $? != 0 ];then
    su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
fi

/usr/bin/supervisord -n