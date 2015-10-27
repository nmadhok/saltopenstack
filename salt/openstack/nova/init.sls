##
# Author: Nitin Madhok
# Date Created: Monday, June 22, 2015
# Date Last Modified: Monday, July 13, 2015
##


{%- set baseFolder = "openstack/nova" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set controllerHost = salt['pillar.get']('openstack:CONTROLLER_HOST', '') %}
{%- set domain = salt['grains.get']('domain', 'domain.com') %}
{%- set dbRootPass = salt['pillar.get']('openstack:DB_PASS', 'dbPass') %}
{%- set adminToken = salt['pillar.get']('openstack:ADMIN_TOKEN', 'ADMIN') %}
{%- set adminUser = salt['pillar.get']('openstack:ADMIN_USER', 'admin') %}
{%- set novaDbName = salt['pillar.get']('openstack:NOVA_DBNAME', 'nova') %}
{%- set novaDbUser = salt['pillar.get']('openstack:NOVA_DBUSER', 'nova') %}
{%- set novaDbPass = salt['pillar.get']('openstack:NOVA_DBPASS', 'novaDbPass') %}
{%- set novaUser = salt['pillar.get']('openstack:NOVA_USER', 'nova') %}
{%- set novaPass = salt['pillar.get']('openstack:NOVA_PASS', 'novaPass') %}
{%- set novaEmail = salt['pillar.get']('openstack:NOVA_EMAIL', novaUser ~ '@' ~ domain) %}
{%- set endpointURL = "http://" ~ controllerHost ~ ":35357/v2.0" %}
{%- set messagingType = salt['pillar.get']('openstack:MESSAGING_TYPE', 'rabbitmq') %}
{%- set messagingUser = salt['pillar.get']('openstack:MESSAGING_USER', messagingType) %}
{%- set messagingPass = salt['pillar.get']('openstack:MESSAGING_PASS', messagingType ~ 'Pass') %}
{%- set managementIP = salt['grains.get']('ip4_interfaces:eth1')[0] %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Install necessary nova packages:
  pkg.installed:
    - pkgs:
      - openstack-nova-api
      - openstack-nova-cert
      - openstack-nova-conductor
      - openstack-nova-console
      - openstack-nova-novncproxy
      - openstack-nova-scheduler
      - python-novaclient

{{fileName}} - Manage nova config file /etc/nova/nova.conf:
  file.managed:
    - name: /etc/nova/nova.conf
    - source: {{baseURL}}/nova.conf
    - makedirs: True
    - template: jinja
    - defaults:
        novaDbUser: {{novaDbUser}}
        novaDbPass: {{novaDbPass}}
        novaDbName: {{novaDbName}}
        novaUser: {{novaUser}}
        novaPass: {{novaPass}}
        controllerHost: {{controllerHost}}
        messagingType: {{messagingType}}
        messagingUser: {{messagingUser}}
        messagingPass: {{messagingPass}}
        managementIP: {{managementIP}}
        openstackRole: 'controller'
    - require:
      - pkg: {{fileName}} - Install necessary nova packages

{{fileName}} - Create database for nova service:
  mysql_database.present:
    - name: "{{novaDbName}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - connection_charset: utf8
    - require:
      - pkg: {{fileName}} - Install necessary nova packages

{% for host in ['localhost', '%'] %}
{{fileName}} - Create user {{novaDbUser}}@{{host}} for nova service:
  mysql_user.present:
    - name: "{{novaDbUser}}"
    - password: "{{novaDbPass}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - host: "{{host}}"
    - connection_charset: utf8
    - require:
      - mysql_database: {{fileName}} - Create database for nova service

{{fileName}} - Grant all privileges on {{novaDbName}}.* to {{novaDbUser}}@{{host}}:
  mysql_grants.present:
    - name: "Grant all privileges on {{novaDbName}}.* to {{novaDbUser}}@{{host}}" 
    - grant: "all privileges"
    - database: "{{novaDbName}}.*"
    - user: "{{novaDbUser}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - host: "{{host}}"
    - connection_charset: utf8
    - require:
      - mysql_database: {{fileName}} - Create database for nova service
      - mysql_user: {{fileName}} - Create user {{novaDbUser}}@{{host}} for nova service
{% endfor %}

{{fileName}} - Create database tables for the Compute service:
  cmd.run:
    - name: 'su -s /bin/sh -c "nova-manage db sync" "{{novaDbName}}"'
    - require:
      - pkg: {{fileName}} - Install necessary nova packages
      - mysql_database: {{fileName}} - Create database for nova service

{{fileName}} - Create {{novaUser}} account:
  keystone.user_present:
    - name: "{{novaUser}}"
    - password: "{{novaPass}}"
    - email: "{{novaEmail}}"
    - roles:
        service:
          - {{adminUser}}
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install necessary nova packages

{{fileName}} - Create service entry for Compute Service:
  keystone.service_present:
    - name: "nova"
    - service_type: "compute"
    - description: "OpenStack Compute Service"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install necessary nova packages

{{fileName}} - Create an API endpoint for the Compute Service:
  keystone.endpoint_present:
    - name: "nova"
    - publicurl: 'http://{{controllerHost}}:8774/v2/%(tenant_id)s'
    - internalurl: 'http://{{controllerHost}}:8774/v2/%(tenant_id)s'
    - adminurl: 'http://{{controllerHost}}:8774/v2/%(tenant_id)s'
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install necessary nova packages
      - keystone: {{fileName}} - Create service entry for Compute Service

{{fileName}} - Include /etc/sudoers.d for sudoers:
  file.append:
    - name: /etc/sudoers
    - text: "#includedir /etc/sudoers.d"

{% for service in ['openstack-nova-api', 'openstack-nova-cert', 'openstack-nova-consoleauth', 'openstack-nova-scheduler', 'openstack-nova-conductor', 'openstack-nova-novncproxy'] %}
{{fileName}} - Start {{service}} and enable it to start at boot:
  service.running:
    - name: {{service}}
    - enable: True
    - watch:
      - file: {{fileName}} - Manage nova config file /etc/nova/nova.conf
{% endfor %}
{% endif %}

{% if 'compute' in openstackRole %}
{{fileName}} - Install nova-compute package:
  pkg.installed:
    - name: openstack-nova-compute

{{fileName}} - Manage nova config file /etc/nova/nova.conf:
  file.managed:
    - name: /etc/nova/nova.conf
    - source: {{baseURL}}/nova.conf
    - makedirs: True
    - template: jinja
    - defaults:
        novaDbUser: {{novaDbUser}}
        novaDbPass: {{novaDbPass}}
        novaDbName: {{novaDbName}}
        novaUser: {{novaUser}}
        novaPass: {{novaPass}}
        controllerHost: {{controllerHost}}
        messagingType: {{messagingType}}
        messagingUser: {{messagingUser}}
        messagingPass: {{messagingPass}}
        managementIP: {{managementIP}}
        openstackRole: 'compute'
    - require:
      - pkg: {{fileName}} - Install nova-compute package

{% if salt['cmd.run']("egrep -c '(vmx|svm)' /proc/cpuinfo") == '0' %}
{{fileName}} - Add SELinux rule to set 'virt_use_execmem' to 'on':
  cmd.run:
    - name: 'setsebool -P virt_use_execmem on'
    - unless: 'getsebool virt_use_execmem | grep "virt_use_execmem --> on"'
    - watch_in:
      - service: {{fileName}} - Start libvirtd and enable it to start at boot

{{fileName}} - Create symlink from '/usr/bin/qemu-system-x86_64' to '/usr/libexec/qemu-kvm':
  file.symlink:
    - name: '/usr/bin/qemu-system-x86_64'
    - target: '/usr/libexec/qemu-kvm'
    - watch_in:
      - service: {{fileName}} - Start libvirtd and enable it to start at boot
{% endif %}

{{fileName}} - Include /etc/sudoers.d for sudoers:
  file.append:
    - name: /etc/sudoers
    - text: "#includedir /etc/sudoers.d"

{% for service in ['libvirtd', 'messagebus', 'openstack-nova-compute'] %}
{{fileName}} - Start {{service}} and enable it to start at boot:
  service.running:
    - name: {{service}}
    - enable: True
    - watch:
      - file: {{fileName}} - Manage nova config file /etc/nova/nova.conf
{% endfor %}
{% endif %}

{% endif %}
