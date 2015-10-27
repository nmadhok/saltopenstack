##
# Author: Nitin Madhok
# Date Created: Sunday, June 21, 2015
# Date Last Modified: Tuesday, June 30, 2015
##


{%- set baseFolder = "openstack/messaging/rabbitmq" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}

{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Install rabbitmq-server package and start service:
  pkg.installed:
    - name: rabbitmq-server
  service.running:
    - name: rabbitmq-server
    - enable: True
    - require:
      - pkg: {{fileName}} - Install rabbitmq-server package and start service
{% endif %}

{% endif %}
