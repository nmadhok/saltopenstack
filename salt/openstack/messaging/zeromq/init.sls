##
# Author: Nitin Madhok
# Date Created: Tuesday, June 23, 2015
# Date Last Modified: Tuesday, June 23, 2015
##


{%- set baseFolder = "openstack/messaging/zeromq" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}

{%- if osFamily == 'RedHat' %}
{%- if 'controller' in openstackRole %}
{% endif %}
{% endif %}
