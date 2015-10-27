##
# Author: Nitin Madhok, Yang Li
# Date Created: Monday, June 29, 2015
# Date Last Modified: Monday, July 13, 2015
##


{%- set baseFolder = "openstack/networking/neutron" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set controllerHost = salt['pillar.get']('openstack:CONTROLLER_HOST', '') %}
{%- set domain = salt['grains.get']('domain', 'domain.com') %}
{%- set managementIP = salt['grains.get']('ip4_interfaces:eth1')[0] %}
{%- set dbRootPass = salt['pillar.get']('openstack:DB_PASS', 'dbPass') %}
{%- set adminToken = salt['pillar.get']('openstack:ADMIN_TOKEN', 'ADMIN') %}
{%- set adminUser = salt['pillar.get']('openstack:ADMIN_USER', 'admin') %}
{%- set neutronDbName = salt['pillar.get']('openstack:NEUTRON_DBNAME', 'neutron') %}
{%- set neutronDbUser = salt['pillar.get']('openstack:NEUTRON_DBUSER', 'neutron') %}
{%- set neutronDbPass = salt['pillar.get']('openstack:NEUTRON_DBPASS', 'neutronDbPass') %}
{%- set neutronUser = salt['pillar.get']('openstack:NEUTRON_USER', 'neutron') %}
{%- set neutronPass = salt['pillar.get']('openstack:NEUTRON_PASS', 'neutronPass') %}
{%- set neutronEmail = salt['pillar.get']('openstack:NEUTRON_EMAIL', neutronUser ~ '@' ~ domain) %}
{%- set novaUser = salt['pillar.get']('openstack:NOVA_USER', 'nova') %}
{%- set novaPass = salt['pillar.get']('openstack:NOVA_PASS', 'novaPass') %}
{%- set metadataSecret = salt['pillar.get']('openstack:METADATA_SECRET', 'metadataSecret') %}
{%- set endpointURL = "http://" ~ controllerHost ~ ":35357/v2.0" %}
{%- set messagingType = salt['pillar.get']('openstack:MESSAGING_TYPE', 'rabbitmq') %}
{%- set messagingUser = salt['pillar.get']('openstack:MESSAGING_USER', messagingType) %}
{%- set messagingPass = salt['pillar.get']('openstack:MESSAGING_PASS', messagingType ~ 'Pass') %}
{%- set tenantNetworkTypes = salt['pillar.get']('openstack:TENANT_NETWORK_TYPES', ['gre']) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}

{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Install necessary neutron packages:
  pkg.installed:
    - pkgs:
      - openstack-neutron
      - openstack-neutron-ml2
      - python-neutronclient

{{fileName}} - Manage neutron config file /etc/neutron/neutron.conf:
  file.managed:
    - name: /etc/neutron/neutron.conf
    - source: {{baseURL}}/neutron.conf
    - makedirs: True
    - template: jinja
    - defaults:
        neutronDbUser: {{neutronDbUser}}
        neutronDbPass: {{neutronDbPass}}
        neutronDbName: {{neutronDbName}}
        neutronUser: {{neutronUser}}
        neutronPass: {{neutronPass}}
        novaUser: {{novaUser}}
        novaPass: {{novaPass}}
        controllerHost: {{controllerHost}}
        messagingType: {{messagingType}}
        messagingUser: {{messagingUser}}
        messagingPass: {{messagingPass}}
        openstackRole: {{openstackRole}}
        endpointURL: {{endpointURL}}
    - require:
      - pkg: {{fileName}} - Install necessary neutron packages

{{fileName}} - Manage ml2 plugin config file /etc/neutron/plugins/ml2/ml2_conf.ini:
  file.managed:
    - name: /etc/neutron/plugins/ml2/ml2_conf.ini
    - source: {{baseURL}}/ml2_conf.ini
    - makedirs: True
    - template: jinja
    - defaults:
        managementIP: {{managementIP}}
        openstackRole: {{openstackRole}}
        tenantNetworkTypes: {{tenantNetworkTypes}}
    - require:
      - pkg: {{fileName}} - Install necessary neutron packages

{{fileName}} - Set the nova_admin_tenant_id in /etc/neutron/neutron.conf:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_tenant_id $(keystone --os-token={{adminToken}} --os-endpoint='{{endpointURL}}' tenant-list | awk '/ service / { print $2 }')"
    - unless: "[ $(openstack-config --get /etc/neutron/neutron.conf DEFAULT nova_admin_tenant_id) == $(keystone --os-token={{adminToken}} --os-endpoint='{{endpointURL}}' tenant-list | awk '/ service / { print $2 }') ]"

{{fileName}} - Set 'network_api_class' to 'nova.network.neutronv2.api.API' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT network_api_class) = nova.network.neutronv2.api.API ]"

{{fileName}} - Set 'neutron_url' to 'http://{{controllerHost}}:9696' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://{{controllerHost}}:9696"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_url) = http://{{controllerHost}}:9696 ]"

{{fileName}} - Set 'neutron_auth_strategy' to 'keystone' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_auth_strategy) = keystone ]"

{{fileName}} - Set 'neutron_admin_tenant_name' to 'service' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name) = service ]"

{{fileName}} - Set 'neutron_admin_username' to '{{neutronUser}}' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username {{neutronUser}}"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_admin_username) = {{neutronUser}} ]"

{{fileName}} - Set 'neutron_admin_password' to '{{neutronPass}}' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password {{neutronPass}}"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_admin_password) = {{neutronPass}} ]"

{{fileName}} - Set 'neutron_admin_auth_url' to '{{endpointURL}}' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url {{endpointURL}}"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_admin_auth_url) = {{endpointURL}} ]"

{{fileName}} - Set 'linuxnet_interface_driver' to 'nova.network.linux_net.LinuxOVSInterfaceDriver' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT linuxnet_interface_driver) = nova.network.linux_net.LinuxOVSInterfaceDriver ]"

{{fileName}} - Set 'firewall_driver' to 'nova.virt.firewall.NoopFirewallDriver' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT firewall_driver) = nova.virt.firewall.NoopFirewallDriver ]"

{{fileName}} - Set 'security_group_api' to 'neutron' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT security_group_api) = neutron ]"

{{fileName}} - Set 'service_neutron_metadata_proxy' to 'true' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy true"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy) = true ]"

{{fileName}} - Set 'neutron_metadata_proxy_shared_secret' to '{{metadataSecret}}' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_metadata_proxy_shared_secret {{metadataSecret}}"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_metadata_proxy_shared_secret) = {{metadataSecret}} ]"

{{fileName}} - Create database for neutron service:
  mysql_database.present:
    - name: "{{neutronDbName}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - connection_charset: utf8
    - require:
      - pkg: {{fileName}} - Install necessary neutron packages

{% for host in ['localhost', '%'] %}
{{fileName}} - Create user {{neutronDbUser}}@{{host}} for neutron service:
  mysql_user.present:
    - name: "{{neutronDbUser}}"
    - password: "{{neutronDbPass}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - host: "{{host}}"
    - connection_charset: utf8
    - require:
      - mysql_database: {{fileName}} - Create database for neutron service

{{fileName}} - Grant all privileges on {{neutronDbName}}.* to {{neutronDbUser}}@{{host}}:
  mysql_grants.present:
    - name: "Grant all privileges on {{neutronDbName}}.* to {{neutronDbUser}}@{{host}}" 
    - grant: "all privileges"
    - database: "{{neutronDbName}}.*"
    - user: "{{neutronDbUser}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - host: "{{host}}"
    - connection_charset: utf8
    - require:
      - mysql_database: {{fileName}} - Create database for neutron service
      - mysql_user: {{fileName}} - Create user {{neutronDbUser}}@{{host}} for neutron service
{% endfor %}

{{fileName}} - Create {{neutronUser}} account:
  keystone.user_present:
    - name: "{{neutronUser}}"
    - password: "{{neutronPass}}"
    - email: "{{neutronEmail}}"
    - roles:
        service:
          - {{adminUser}}
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install necessary neutron packages

{{fileName}} - Create service entry for Networking Service:
  keystone.service_present:
    - name: "neutron"
    - service_type: "network"
    - description: "OpenStack Networking Service"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install necessary neutron packages

{{fileName}} - Create an API endpoint for the Networking Service:
  keystone.endpoint_present:
    - name: "neutron"
    - publicurl: 'http://{{controllerHost}}:9696'
    - internalurl: 'http://{{controllerHost}}:9696'
    - adminurl: 'http://{{controllerHost}}:9696'
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install necessary neutron packages
      - keystone: {{fileName}} - Create service entry for Networking Service

{{fileName}} - Create symlink from '/etc/neutron/plugin.ini' to '/etc/neutron/plugins/ml2/ml2_conf.ini':
  file.symlink:
    - name: '/etc/neutron/plugin.ini'
    - target: '/etc/neutron/plugins/ml2/ml2_conf.ini'

{% for service in ['openstack-nova-api', 'openstack-nova-scheduler', 'openstack-nova-conductor'] %}
{{fileName}} - Start {{service}} and enable it to start at boot:
  service.running:
    - name: {{service}}
    - enable: True
    - watch:
      - cmd: {{fileName}} - Set 'network_api_class' to 'nova.network.neutronv2.api.API' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_url' to 'http://{{controllerHost}}:9696' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_auth_strategy' to 'keystone' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_admin_tenant_name' to 'service' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_admin_username' to '{{neutronUser}}' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_admin_password' to '{{neutronPass}}' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_admin_auth_url' to '{{endpointURL}}' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'linuxnet_interface_driver' to 'nova.network.linux_net.LinuxOVSInterfaceDriver' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'firewall_driver' to 'nova.virt.firewall.NoopFirewallDriver' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'security_group_api' to 'neutron' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'service_neutron_metadata_proxy' to 'true' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_metadata_proxy_shared_secret' to '{{metadataSecret}}' in /etc/nova/nova.conf
{% endfor %}

{{fileName}} - Start neutron-server service and enable it to start at boot:
  service.running:
    - name: neutron-server
    - enable: True
    - watch:
      - file: {{fileName}} - Manage neutron config file /etc/neutron/neutron.conf
      - file: {{fileName}} - Manage ml2 plugin config file /etc/neutron/plugins/ml2/ml2_conf.ini
    - require:
      - pkg: {{fileName}} - Install necessary neutron packages
{% endif %}

{% if 'compute' in openstackRole or 'network' in openstackRole %}
{{fileName}} - Install necessary networking components:
  pkg.installed:
    - pkgs:
      - openstack-neutron-ml2
      - openstack-neutron-openvswitch

{% if 'compute' in openstackRole %}
{% set sysctlOptionList = [['net.ipv4.conf.all.rp_filter', 0], ['net.ipv4.conf.default.rp_filter', 0], ['net.bridge.bridge-nf-call-arptables', 1], ['net.bridge.bridge-nf-call-iptables', 1], ['net.bridge.bridge-nf-call-ip6tables', 1]] %}
{% endif %}

{% if 'network' in openstackRole %}
{% set sysctlOptionList = [['net.ipv4.ip_forward', 1], ['net.ipv4.conf.all.rp_filter', 0], ['net.ipv4.conf.default.rp_filter', 0], ['net.bridge.bridge-nf-call-arptables', 1], ['net.bridge.bridge-nf-call-iptables', 1], ['net.bridge.bridge-nf-call-ip6tables', 1]] %}

{{fileName}} - Install openstack-neutron for network node:
  pkg.installed:
    - name: openstack-neutron
{% endif %}

{%- for option, value in sysctlOptionList %}
{{fileName}} - Set '{{option}}' to '{{value}}' in /etc/sysctl.conf:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: ^(#*\s*){{option}}.*
    - repl: {{option}} = {{value}}
    - append_if_not_found: True
    - watch_in:
      - cmd: {{fileName}} - Run "sysctl -p" if changes were made to /etc/sysctl.conf
{%- endfor %}

{{fileName}} - Run "sysctl -p" if changes were made to /etc/sysctl.conf:
  cmd.wait:
    - name: "sysctl -p"

{{fileName}} - Manage neutron config file /etc/neutron/neutron.conf:
  file.managed:
    - name: /etc/neutron/neutron.conf
    - source: {{baseURL}}/neutron.conf
    - makedirs: True
    - template: jinja
    - defaults:
        neutronDbUser: {{neutronDbUser}}
        neutronDbPass: {{neutronDbPass}}
        neutronDbName: {{neutronDbName}}
        neutronUser: {{neutronUser}}
        neutronPass: {{neutronPass}}
        novaUser: {{novaUser}}
        novaPass: {{novaPass}}
        controllerHost: {{controllerHost}}
        messagingType: {{messagingType}}
        messagingUser: {{messagingUser}}
        messagingPass: {{messagingPass}}
        openstackRole: {{openstackRole}}
        endpointURL: {{endpointURL}}
    - require:
      - pkg: {{fileName}} - Install necessary networking components

{% if 'network' in openstackRole %}
{{fileName}} - Set 'interface_driver' to 'neutron.agent.linux.interface.OVSInterfaceDriver' in /etc/neutron/l3_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver"
    - unless: "[ $(openstack-config --get /etc/neutron/l3_agent.ini DEFAULT interface_driver) = neutron.agent.linux.interface.OVSInterfaceDriver ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-l3-agent service and enable it to start at boot

{{fileName}} - Set 'use_namespaces' to 'True' in /etc/neutron/l3_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/l3_agent.ini DEFAULT use_namespaces True"
    - unless: "[ $(openstack-config --get /etc/neutron/l3_agent.ini DEFAULT use_namespaces) = True ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-l3-agent service and enable it to start at boot

{{fileName}} - Set 'router_delete_namespaces' to 'True' in /etc/neutron/l3_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/l3_agent.ini DEFAULT router_delete_namespaces True"
    - unless: "[ $(openstack-config --get /etc/neutron/l3_agent.ini DEFAULT router_delete_namespaces) = True ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-l3-agent service and enable it to start at boot

{{fileName}} - Set 'verbose' to 'True' in /etc/neutron/l3_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/l3_agent.ini DEFAULT verbose True"
    - unless: "[ $(openstack-config --get /etc/neutron/l3_agent.ini DEFAULT verbose) = True ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-l3-agent service and enable it to start at boot

{{fileName}} - Set 'interface_driver' to 'neutron.agent.linux.interface.OVSInterfaceDriver' in /etc/neutron/dhcp_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver"
    - unless: "[ $(openstack-config --get /etc/neutron/dhcp_agent.ini DEFAULT interface_driver) = neutron.agent.linux.interface.OVSInterfaceDriver ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-dhcp-agent service and enable it to start at boot

{{fileName}} - Set 'dhcp_driver' to 'neutron.agent.linux.dhcp.Dnsmasq' in /etc/neutron/dhcp_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq"
    - unless: "[ $(openstack-config --get /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver) = neutron.agent.linux.dhcp.Dnsmasq ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-dhcp-agent service and enable it to start at boot

{{fileName}} - Set 'use_namespaces' to 'True' in /etc/neutron/dhcp_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT use_namespaces True"
    - unless: "[ $(openstack-config --get /etc/neutron/dhcp_agent.ini DEFAULT use_namespaces) = True ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-dhcp-agent service and enable it to start at boot

{{fileName}} - Set 'dhcp_delete_namespaces' to 'True' in /etc/neutron/dhcp_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_delete_namespaces True"
    - unless: "[ $(openstack-config --get /etc/neutron/dhcp_agent.ini DEFAULT dhcp_delete_namespaces) = True ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-dhcp-agent service and enable it to start at boot

{{fileName}} - Set 'verbose' to 'True' in /etc/neutron/dhcp_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT verbose True"
    - unless: "[ $(openstack-config --get /etc/neutron/dhcp_agent.ini DEFAULT verbose) = True ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-dhcp-agent service and enable it to start at boot

{{fileName}} - Set 'auth_url' to 'http://{{controllerHost}}:5000/v2.0' in /etc/neutron/metadata_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_url http://{{controllerHost}}:5000/v2.0"
    - unless: "[ $(openstack-config --get /etc/neutron/metadata_agent.ini DEFAULT auth_url) = http://{{controllerHost}}:5000/v2.0 ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-metadata-agent service and enable it to start at boot

{{fileName}} - Set 'auth_region' to 'regionOne' in /etc/neutron/metadata_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_region regionOne"
    - unless: "[ $(openstack-config --get /etc/neutron/metadata_agent.ini DEFAULT auth_region) = regionOne ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-metadata-agent service and enable it to start at boot

{{fileName}} - Set 'admin_tenant_name' to 'service' in /etc/neutron/metadata_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name service"
    - unless: "[ $(openstack-config --get /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name) = service ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-metadata-agent service and enable it to start at boot

{{fileName}} - Set 'admin_user' to '{{neutronUser}}' in /etc/neutron/metadata_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_user {{neutronUser}}"
    - unless: "[ $(openstack-config --get /etc/neutron/metadata_agent.ini DEFAULT admin_user) = {{neutronUser}} ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-metadata-agent service and enable it to start at boot

{{fileName}} - Set 'admin_password' to '{{neutronPass}}' in /etc/neutron/metadata_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_password {{neutronPass}}"
    - unless: "[ $(openstack-config --get /etc/neutron/metadata_agent.ini DEFAULT admin_password) = {{neutronPass}} ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-metadata-agent service and enable it to start at boot

{{fileName}} - Set 'nova_metadata_ip' to '{{controllerHost}}' in /etc/neutron/metadata_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip {{controllerHost}}"
    - unless: "[ $(openstack-config --get /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip) = {{controllerHost}} ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-metadata-agent service and enable it to start at boot

{{fileName}} - Set 'metadata_proxy_shared_secret' to '{{metadataSecret}}' in /etc/neutron/metadata_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret {{metadataSecret}}"
    - unless: "[ $(openstack-config --get /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret) = {{metadataSecret}} ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-metadata-agent service and enable it to start at boot

{{fileName}} - Set 'verbose' to 'True' in /etc/neutron/metadata_agent.ini:
  cmd.run:
    - name: "openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT verbose True"
    - unless: "[ $(openstack-config --get /etc/neutron/metadata_agent.ini DEFAULT verbose) = True ]"
    - watch_in:
      - service: {{fileName}} - Start neutron-metadata-agent service and enable it to start at boot
{% endif %}

{{fileName}} - Manage ml2 plugin config file /etc/neutron/plugins/ml2/ml2_conf.ini:
  file.managed:
    - name: /etc/neutron/plugins/ml2/ml2_conf.ini
    - source: {{baseURL}}/ml2_conf.ini
    - makedirs: True
    - template: jinja
    - defaults:
        managementIP: {{managementIP}}
        openstackRole: {{openstackRole}}
        tenantNetworkTypes: {{tenantNetworkTypes}}
    - require:
      - pkg: {{fileName}} - Install necessary networking components

{{fileName}} - Start openvswitch service and enable it to start at boot:
  service.running:
    - name: openvswitch
    - enable: True
    - watch:
      - file: {{fileName}} - Manage ml2 plugin config file /etc/neutron/plugins/ml2/ml2_conf.ini
    - require:
      - pkg: {{fileName}} - Install necessary networking components

{{fileName}} - Add the integration bridge:
  cmd.run:
    - name: "ovs-vsctl add-br br-int"
    - unless: "ovs-vsctl -t 1 br-exists br-int"
    - require:
      - pkg: {{fileName}} - Install necessary networking components

{% if 'network' in openstackRole %}
{{fileName}} - Add the external bridge:
  cmd.run:
    - name: "ovs-vsctl add-br br-ex"
    - unless: "ovs-vsctl -t 1 br-exists br-ex"
    - require:
      - pkg: {{fileName}} - Install necessary networking components

{{fileName}} - Add a port to the external bridge that connects to the physical external network interface:
  cmd.run:
    - name: "ovs-vsctl add-port br-ex eth2"
    - unless: "ovs-vsctl list-ports br-ex | grep eth2"
    - require:
      - pkg: {{fileName}} - Install necessary networking components
      - cmd: {{fileName}} - Add the external bridge
{% endif %}

{% if 'compute' in openstackRole %}
{{fileName}} - Set 'network_api_class' to 'nova.network.neutronv2.api.API' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT network_api_class) = nova.network.neutronv2.api.API ]"

{{fileName}} - Set 'neutron_url' to 'http://{{controllerHost}}:9696' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://{{controllerHost}}:9696"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_url) = http://{{controllerHost}}:9696 ]"

{{fileName}} - Set 'neutron_auth_strategy' to 'keystone' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_auth_strategy) = keystone ]"

{{fileName}} - Set 'neutron_admin_tenant_name' to 'service' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name) = service ]"

{{fileName}} - Set 'neutron_admin_username' to '{{neutronUser}}' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username {{neutronUser}}"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_admin_username) = {{neutronUser}} ]"

{{fileName}} - Set 'neutron_admin_password' to '{{neutronPass}}' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password {{neutronPass}}"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_admin_password) = {{neutronPass}} ]"

{{fileName}} - Set 'neutron_admin_auth_url' to '{{endpointURL}}' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url {{endpointURL}}"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT neutron_admin_auth_url) = {{endpointURL}} ]"

{{fileName}} - Set 'linuxnet_interface_driver' to 'nova.network.linux_net.LinuxOVSInterfaceDriver' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT linuxnet_interface_driver) = nova.network.linux_net.LinuxOVSInterfaceDriver ]"

{{fileName}} - Set 'firewall_driver' to 'nova.virt.firewall.NoopFirewallDriver' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT firewall_driver) = nova.virt.firewall.NoopFirewallDriver ]"

{{fileName}} - Set 'security_group_api' to 'neutron' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT security_group_api) = neutron ]"
{% endif %}

{{fileName}} - Create symlink from '/etc/neutron/plugin.ini' to '/etc/neutron/plugins/ml2/ml2_conf.ini':
  file.symlink:
    - name: '/etc/neutron/plugin.ini'
    - target: '/etc/neutron/plugins/ml2/ml2_conf.ini'
    - require:
      - pkg: {{fileName}} - Install necessary networking components

{{fileName}} - Replace location of plugin.ini file in /etc/init.d/neutron-openvswitch-agent:
  file.replace:
    - name: "/etc/init.d/neutron-openvswitch-agent"
    - pattern: "plugins/openvswitch/ovs_neutron_plugin.ini"
    - repl: "plugin.ini"
    - require:
      - pkg: {{fileName}} - Install necessary networking components

{% if 'compute' in openstackRole %}
{{fileName}} - Restart openstack-nova-compute service:
  service.running:
    - name: openstack-nova-compute
    - enable: True
    - watch:
      - cmd: {{fileName}} - Set 'network_api_class' to 'nova.network.neutronv2.api.API' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_url' to 'http://{{controllerHost}}:9696' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_auth_strategy' to 'keystone' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_admin_tenant_name' to 'service' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_admin_username' to '{{neutronUser}}' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_admin_password' to '{{neutronPass}}' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'neutron_admin_auth_url' to '{{endpointURL}}' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'linuxnet_interface_driver' to 'nova.network.linux_net.LinuxOVSInterfaceDriver' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'firewall_driver' to 'nova.virt.firewall.NoopFirewallDriver' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'security_group_api' to 'neutron' in /etc/nova/nova.conf
{% endif %}

{{fileName}} - Start neutron-openvswitch-agent service and enable it to start at boot:
  service.running:
    - name: neutron-openvswitch-agent
    - enable: True
    - require:
      - pkg: {{fileName}} - Install necessary networking components

{% if 'network' in openstackRole %}
{% for service in ['neutron-l3-agent', 'neutron-dhcp-agent', 'neutron-metadata-agent'] %}
{{fileName}} - Start {{service}} service and enable it to start at boot:
  service.running:
    - name: {{service}}
    - enable: True
    - require:
      - pkg: {{fileName}} - Install necessary networking components
{% endfor %}
{% endif %}
{% endif %}

{% endif %}
