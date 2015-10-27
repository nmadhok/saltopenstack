##
# Author: Nitin Madhok
# Date Created: Wednesday, June 24, 2015
# Date Last Modified: Tuesday, June 30, 2015
##


{%- set baseFolder = "openstack/post-install/ldap-plugin" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Add custom ldap integration plugin:
  file.managed:
    - name: /usr/lib/python2.6/site-packages/keystone/identity/backends/custom.py
    - source: {{baseURL}}/custom.py

{{fileName}} - Set the keystone identity backend driver to 'keystone.identity.backends.custom.Identity' in /etc/keystone/keystone.conf:
  cmd.run:
    - name: "openstack-config --set /etc/keystone/keystone.conf identity driver keystone.identity.backends.custom.Identity"
    - unless: "[ $(openstack-config --get /etc/keystone/keystone.conf identity driver) = keystone.identity.backends.custom.Identity ]"
    - require:
      - file: {{fileName}} - Add custom ldap integration plugin

{{fileName}} - Restart keystone service:
  service.running:
    - name: openstack-keystone
    - enable: True
    - watch:
      - cmd: {{fileName}} - Set the keystone identity backend driver to 'keystone.identity.backends.custom.Identity' in /etc/keystone/keystone.conf
{% endif %}

{% endif %}
