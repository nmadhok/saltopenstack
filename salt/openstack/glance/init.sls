##
# Author: Nitin Madhok
# Date Created: Sunday, June 21, 2015
# Date Last Modified: Monday, July 13, 2015
##


{%- set baseFolder = "openstack/glance" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set controllerHost = salt['grains.get']('fqdn', salt['grains.get']('ip4_interfaces:eth1')[0]) %}
{%- set domain = salt['grains.get']('domain', 'domain.com') %}
{%- set dbRootPass = salt['pillar.get']('openstack:DB_PASS', 'dbPass') %}
{%- set adminUser = salt['pillar.get']('openstack:ADMIN_USER', 'admin') %}
{%- set adminPass = salt['pillar.get']('openstack:ADMIN_PASS', 'adminPass') %}
{%- set adminToken = salt['pillar.get']('openstack:ADMIN_TOKEN', 'ADMIN') %}
{%- set glanceDbName = salt['pillar.get']('openstack:GLANCE_DBNAME', 'glance') %}
{%- set glanceDbUser = salt['pillar.get']('openstack:GLANCE_DBUSER', 'glance') %}
{%- set glanceDbPass = salt['pillar.get']('openstack:GLANCE_DBPASS', 'glanceDbPass') %}
{%- set glanceUser = salt['pillar.get']('openstack:GLANCE_USER', 'glance') %}
{%- set glancePass = salt['pillar.get']('openstack:GLANCE_PASS', 'glancePass') %}
{%- set glanceEmail = salt['pillar.get']('openstack:GLANCE_EMAIL', glanceUser ~ '@' ~ domain) %}
{%- set endpointURL = "http://" ~ controllerHost ~ ":35357/v2.0" %}
{%- set messagingType = salt['pillar.get']('openstack:MESSAGING_TYPE', 'rabbitmq') %}
{%- set messagingUser = salt['pillar.get']('openstack:MESSAGING_USER', messagingType) %}
{%- set messagingPass = salt['pillar.get']('openstack:MESSAGING_PASS', messagingType ~ 'Pass') %}
{%- set osFamily = salt['grains.get']('os_family', '') %}

{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Install OpenStack Image Service:
  pkg.installed:
    - pkgs:
      - openstack-glance
      - python-glanceclient

{{fileName}} - Manage glance-api config file /etc/glance/glance-api.conf:
  file.managed:
    - name: /etc/glance/glance-api.conf
    - source: {{baseURL}}/glance-api.conf
    - makedirs: True
    - template: jinja
    - defaults:
        glanceDbUser: {{glanceDbUser}}
        glanceDbPass: {{glanceDbPass}}
        glanceDbName: {{glanceDbName}}
        glanceUser: {{glanceUser}}
        glancePass: {{glancePass}}
        messagingType: {{messagingType}}
        messagingUser: {{messagingUser}}
        messagingPass: {{messagingPass}}
        controllerHost: {{controllerHost}}
    - require:
      - pkg: {{fileName}} - Install OpenStack Image Service

{{fileName}} - Manage glance-registry config file /etc/glance/glance-registry.conf:
  file.managed:
    - name: /etc/glance/glance-registry.conf
    - source: {{baseURL}}/glance-registry.conf
    - makedirs: True
    - template: jinja
    - defaults:
        glanceDbUser: {{glanceDbUser}}
        glanceDbPass: {{glanceDbPass}}
        glanceDbName: {{glanceDbName}}
        glanceUser: {{glanceUser}}
        glancePass: {{glancePass}}
        messagingType: {{messagingType}}
        messagingUser: {{messagingUser}}
        messagingPass: {{messagingPass}}
        controllerHost: {{controllerHost}}
    - require:
      - pkg: {{fileName}} - Install OpenStack Image Service

{{fileName}} - Create database for image service:
  mysql_database.present:
    - name: "{{glanceDbName}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - connection_charset: utf8
    - require:
      - pkg: {{fileName}} - Install OpenStack Image Service

{% for host in ['localhost', '%'] %}
{{fileName}} - Create user {{glanceDbUser}}@{{host}} for image service:
  mysql_user.present:
    - name: "{{glanceDbUser}}"
    - password: "{{glanceDbPass}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - host: "{{host}}"
    - connection_charset: utf8
    - require:
      - mysql_database: {{fileName}} - Create database for image service

{{fileName}} - Grant all privileges on {{glanceDbName}}.* to {{glanceDbUser}}@{{host}}:
  mysql_grants.present:
    - name: "Grant all privileges on {{glanceDbName}}.* to {{glanceDbUser}}@{{host}}" 
    - grant: "all privileges"
    - database: "{{glanceDbName}}.*"
    - user: "{{glanceDbUser}}"
    - connection_user: "root"
    - connection_pass: "{{dbRootPass}}"
    - host: "{{host}}"
    - connection_charset: utf8
    - require:
      - mysql_database: {{fileName}} - Create database for image service
      - mysql_user: {{fileName}} - Create user {{glanceDbUser}}@{{host}} for image service
{% endfor %}

{{fileName}} - Create database tables for the Image service:
  cmd.run:
    - name: 'su -s /bin/sh -c "glance-manage db_sync" "{{glanceDbName}}"'
    - require:
      - pkg: {{fileName}} - Install OpenStack Image Service
      - mysql_database: {{fileName}} - Create database for image service

{{fileName}} - Create {{glanceUser}} account:
  keystone.user_present:
    - name: "{{glanceUser}}"
    - password: "{{glancePass}}"
    - email: "{{glanceEmail}}"
    - roles:
        service:
          - {{adminUser}}
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack Image Service

{{fileName}} - Create service entry for Image Service:
  keystone.service_present:
    - name: "glance"
    - service_type: "image"
    - description: "OpenStack Image Service"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack Image Service

{{fileName}} - Create an API endpoint for the Image Service:
  keystone.endpoint_present:
    - name: "glance"
    - publicurl: "http://{{controllerHost}}:9292/v2.0"
    - internalurl: "http://{{controllerHost}}:9292/v2.0"
    - adminurl: "http://{{controllerHost}}:9292/v2.0"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - require:
      - pkg: {{fileName}} - Install OpenStack Image Service
      - keystone: {{fileName}} - Create service entry for Image Service

{{fileName}} - Start openstack-glance-api and enable it to start at boot:
  service.running:
    - name: openstack-glance-api
    - enable: True
    - watch:
      - file: {{fileName}} - Manage glance-api config file /etc/glance/glance-api.conf

{{fileName}} - Start openstack-glance-registry and enable it to start at boot:
  service.running:
    - name: openstack-glance-registry
    - enable: True
    - watch:
      - file: {{fileName}} - Manage glance-registry config file /etc/glance/glance-registry.conf

{% for imageName, imageExtension, diskFormat in [['cirros-0.3.2-x86_64', 'img', 'qcow2']] %}
{{fileName}} - Put {{imageName}}.{{imageExtension}} under /tmp/images/:
  file.managed:
    - name: /tmp/images/{{imageName}}.{{imageExtension}}
    - source: {{baseURL}}/images/{{imageName}}.{{imageExtension}}
    - makedirs: True
    - unless: 'glance --os-username={{adminUser}} --os-password="{{adminPass}}" --os-tenant-name={{adminUser}} --os-auth-url="{{endpointURL}}" image-show "{{imageName}}"'

{{fileName}} - Upload {{imageName}} to the Image service:
  cmd.run:
    - name: 'glance --os-username={{adminUser}} --os-password="{{adminPass}}" --os-tenant-name={{adminUser}} --os-auth-url="{{endpointURL}}" image-create --name "{{imageName}}" --disk-format {{diskFormat}} --container-format bare --is-public True < /tmp/images/{{imageName}}.{{imageExtension}}'
    - unless: 'glance --os-username={{adminUser}} --os-password="{{adminPass}}" --os-tenant-name={{adminUser}} --os-auth-url="{{endpointURL}}" image-show "{{imageName}}"'
    - require:
      - file: {{fileName}} - Put {{imageName}}.{{imageExtension}} under /tmp/images/

{{fileName}} - Remove {{imageName}}.{{imageExtension}} from /tmp/images/:
  file.absent:
    - name: /tmp/images/{{imageName}}.{{imageExtension}}
    - require:
      - cmd: {{fileName}} - Upload {{imageName}} to the Image service
{% endfor %}
{% endif %}

{% endif %}
