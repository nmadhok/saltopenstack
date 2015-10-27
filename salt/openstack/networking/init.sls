##
# Author: Nitin Madhok
# Date Created: Thursday, June 25, 2015
# Date Last Modified: Tuesday, June 30, 2015
##


{%- set baseFolder = "openstack/networking" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set networkingType = salt['pillar.get']('openstack:NETWORKING_TYPE', 'legacy') %}


include:
{% if networkingType == 'legacy' %}
  - .legacy
{% elif networkingType == 'neutron' %}
  - .neutron
{% endif %}
