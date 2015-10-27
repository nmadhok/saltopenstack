##
# Author: Nitin Madhok
# Date Created: Thursday, June 25, 2015
# Date Last Modified: Tuesday, July 07, 2015
##


{%- set baseFolder = "openstack/post-install/create-users" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set adminToken = salt['pillar.get']('openstack:ADMIN_TOKEN', 'ADMIN') %}
{%- set adminUser = salt['pillar.get']('openstack:ADMIN_USER', 'admin') %}
{%- set adminPass = salt['pillar.get']('openstack:ADMIN_PASS', 'adminPass') %}
{%- set controllerHost = salt['pillar.get']('openstack:CONTROLLER_HOST', '') %}
{%- set endpointURL = "http://" ~ controllerHost ~ ":35357/v2.0" %}
{%- set osFamily = salt['grains.get']('os_family', '') %}
{%- set domain = 'local' %}
{%- set adminDomain = 'admin.' ~ domain %}
{%- from baseFolder ~ "/map.jinja" import adminList, userList with context %}

{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{% for admin in adminList %}
{{fileName}} - Create account '{{admin}}@{{adminDomain}}':
  keystone.user_present:
    - name: "{{admin}}@{{adminDomain}}"
    - password: "{{admin}}"
    - email: "{{admin}}@{{adminDomain}}"
    - roles:
        {{adminUser}}:
          - {{adminUser}}
          - _member_
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - unless: "keystone --os-token={{adminToken}} --os-endpoint={{endpointURL}} user-get {{admin}}@{{adminDomain}}"
{% endfor %}

{{fileName}} - Create sandbox tenant if not already present:
  keystone.tenant_present:
    - name: "sandbox"
    - description: "Sandbox Testing Tenant"
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"

{{fileName}} - Create superuser account if not already present:
  keystone.user_present:
    - name: "superuser"
    - password: {{adminPass}}
    - email: "superuser@{{domain}}"
    - roles:
        sandbox:
          - _member_
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - unless: "keystone --os-token={{adminToken}} --os-endpoint={{endpointURL}} user-get superuser"
    - require:
      - keystone: {{fileName}} - Create sandbox tenant if not already present

{{fileName}} - Create /root/sandbox-openrc.sh:
  file.managed:
    - name: /root/sandbox-openrc.sh
    - contents: |
        export OS_USERNAME=superuser
        export OS_PASSWORD={{adminPass}}
        export OS_TENANT_NAME=sandbox
        export OS_AUTH_URL={{endpointURL}}
        export PS1='[\u@\h \W(keystone_superuser)]\$ '
    - user: root
    - group: root
    - require:
      - keystone: {{fileName}} - Create sandbox tenant if not already present
      - keystone: {{fileName}} - Create superuser account if not already present

{% for user in userList %}
{{fileName}} - Create account '{{user}}@{{domain}}':
  keystone.user_present:
    - name: "{{user}}@{{domain}}"
    - password: "{{user}}"
    - email: "{{user}}@{{domain}}"
    - roles:
        sandbox:
          - _member_
    - connection_token: "{{adminToken}}"
    - connection_endpoint: "{{endpointURL}}"
    - unless: "keystone --os-token={{adminToken}} --os-endpoint={{endpointURL}} user-get {{user}}@{{domain}}"
    - require:
      - keystone: {{fileName}} - Create sandbox tenant if not already present
{% endfor %}
{% endif %}

{% endif %}
