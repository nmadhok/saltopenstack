##
# Author: Nitin Madhok
# Date Created: Sunday, June 21, 2015
# Date Last Modified: Monday, July 13, 2015
##


{%- set baseFolder = "openstack/keystone" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set controllerHost = salt['grains.get']('fqdn', salt['grains.get']('ip4_interfaces:eth1')[0]) %}
{%- set domain = salt['grains.get']('domain', 'domain.com') %}
{%- set dbRootPass = salt['pillar.get']('openstack:DB_PASS', 'dbPass') %}
{%- set adminToken = salt['pillar.get']('openstack:ADMIN_TOKEN', 'ADMIN') %}
{%- set adminUser = salt['pillar.get']('openstack:ADMIN_USER', 'admin') %}
{%- set adminPass = salt['pillar.get']('openstack:ADMIN_PASS', 'adminPass') %}
{%- set adminEmail = salt['pillar.get']('openstack:ADMIN_EMAIL', adminUser ~ '@' ~ domain) %}
{%- set keystoneDbName = salt['pillar.get']('openstack:KEYSTONE_DBNAME', 'keystone') %}
{%- set keystoneDbUser = salt['pillar.get']('openstack:KEYSTONE_DBUSER', 'keystone') %}
{%- set keystoneDbPass = salt['pillar.get']('openstack:KEYSTONE_DBPASS', 'keystoneDbPass') %}
{%- set endpointURL = "http://" ~ controllerHost ~ ":35357/v2.0" %}
{%- set messagingType = salt['pillar.get']('openstack:MESSAGING_TYPE', 'rabbitmq') %}
{%- set messagingUser = salt['pillar.get']('openstack:MESSAGING_USER', messagingType) %}
{%- set messagingPass = salt['pillar.get']('openstack:MESSAGING_PASS', messagingType ~ 'Pass') %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Install OpenStack identity service and it's dependencies:
  pkg.installed:
    - pkgs:
      - openstack-keystone
      - python-keystoneclient

{{fileName}} - Manage keystone config file /etc/keystone/keystone.conf:
  file.managed:
    - name: /etc/keystone/keystone.conf
    - source: {{baseURL}}/keystone.conf
    - makedirs: True
    - template: jinja
    - defaults:
        adminToken: {{adminToken}}
        keystoneDbUser: {{keystoneDbUser}}
        keystoneDbPass: {{keystoneDbPass}}
        keystoneDbName: {{keystoneDbName}}
        messagingType: {{messagingType}}
        messagingUser: {{messagingUser}}
        messagingPass: {{messagingPass}}
        controllerHost: {{controllerHost}}
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies

{{fileName}} - Create database for keystone service:
  mysql_database.present:
    - name: "{{keystoneDbName}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - connection_charset: utf8
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies

{% for host in ['localhost', '%'] %}
{{fileName}} - Create user {{keystoneDbUser}}@{{host}} for keystone service:
  mysql_user.present:
    - name: "{{keystoneDbUser}}"
    - password: "{{keystoneDbPass}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - host: "{{host}}"
    - connection_charset: utf8
    - require:
      - mysql_database: {{fileName}} - Create database for keystone service

{{fileName}} - Grant all privileges on {{keystoneDbName}}.* to {{keystoneDbUser}}@{{host}}:
  mysql_grants.present:
    - name: "Grant all privileges on {{keystoneDbName}}.* to {{keystoneDbUser}}@{{host}}" 
    - grant: "all privileges"
    - database: "{{keystoneDbName}}.*"
    - user: "{{keystoneDbUser}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - host: "{{host}}"
    - connection_charset: utf8
    - require:
      - mysql_database: {{fileName}} - Create database for keystone service
      - mysql_user: {{fileName}} - Create user {{keystoneDbUser}}@{{host}} for keystone service
{% endfor %}

{{fileName}} - Create database tables for the Identity service:
  cmd.run:
    - name: 'su -s /bin/sh -c "keystone-manage db_sync" "{{keystoneDbName}}"'
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies
      - mysql_database: {{fileName}} - Create database for keystone service

{{fileName}} - Create signing keys and certificates:
  cmd.run:
    - name: 'keystone-manage pki_setup --keystone-user keystone --keystone-group keystone'
    - unless: test -d /etc/keystone/ssl
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies

{{fileName}} - Change owner of /etc/keystone/ssl:
  cmd.run:
    - name: 'chown -R keystone:keystone /etc/keystone/ssl'
    - unless: '[ `stat -c %G /etc/keystone/ssl/` == `stat -c %U /etc/keystone/ssl/` -a `stat -c %U /etc/keystone/ssl/` == "keystone" ]'
    - require:
      - cmd: {{fileName}} - Create signing keys and certificates

{{fileName}} - Change permissions of /etc/keystone/ssl:
  cmd.run:
    - name: 'chmod -R o-rwx /etc/keystone/ssl'
    - unless: '[ `stat -c %a /etc/keystone/ssl/` == 750 ]'
    - require:
      - cmd: {{fileName}} - Create signing keys and certificates

{{fileName}} - Start keystone service and enable it to start at boot:
  service.running:
    - name: openstack-keystone
    - enable: True
    - watch:
      - file: {{fileName}} - Manage keystone config file /etc/keystone/keystone.conf

{{fileName}} - Create cron job to purge expired tokens every hour:
  cmd.run:
    - name: "(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone"
    - unless: "crontab -l -u keystone 2>&1 | grep -q token_flush"

{{fileName}} - Create service tenant for services:
  keystone.tenant_present:
    - name: "service"
    - description: "Service Tenant"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies

{{fileName}} - Create {{adminUser}} tenant:
  keystone.tenant_present:
    - name: "{{adminUser}}"
    - description: "Admin Tenant"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies

{{fileName}} - Create {{adminUser}} role:
  keystone.role_present:
    - name: "{{adminUser}}"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies

{{fileName}} - Create {{adminUser}} account:
  keystone.user_present:
    - name: "{{adminUser}}"
    - password: "{{adminPass}}"
    - email: "{{adminEmail}}"
    - roles:
        {{adminUser}}:
          - {{adminUser}}
          - _member_
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies

{{fileName}} - Create service entry for Identity Service:
  keystone.service_present:
    - name: "keystone"
    - service_type: "identity"
    - description: "OpenStack Identity"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies

{{fileName}} - Create an API endpoint for the Identity Service:
  keystone.endpoint_present:
    - name: "keystone"
    - publicurl: "http://{{controllerHost}}:5000/v2.0"
    - internalurl: "http://{{controllerHost}}:5000/v2.0"
    - adminurl: "{{endpointURL}}"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack identity service and it's dependencies
      - keystone: {{fileName}} - Create service entry for Identity Service

{{fileName}} - Create /root/{{adminUser}}-openrc.sh:
  file.managed:
    - name: /root/{{adminUser}}-openrc.sh
    - contents: |
        export OS_USERNAME={{adminUser}}
        export OS_PASSWORD={{adminPass}}
        export OS_TENANT_NAME={{adminUser}}
        export OS_AUTH_URL={{endpointURL}}
        export PS1='[\u@\h \W(keystone_{{adminUser}})]\$ '
    - user: root
    - group: root
{% endif %}

{% endif %}
