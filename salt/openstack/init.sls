##
# Author: Nitin Madhok
# Date Created: Sunday, June 21, 2015
# Date Last Modified: Thursday, June 25, 2015
##


{%- set baseFolder = "openstack" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set role = salt['grains.get']('openstack', '') %}

{%- if role %}

include:
  - .common
  - .mysql
  - .messaging
  - .keystone
  - .glance
  - .nova
  - .networking
  - .dashboard
  - .post-install

{% endif %}
