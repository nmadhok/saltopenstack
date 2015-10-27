##
# Author: Nitin Madhok
# Date Created: Thursday, June 18, 2015
# Date Last Modified: Friday, July 03, 2015
##


{%- set baseFolder = "openstack/common" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set role = salt['grains.get']('openstack', '') %}


{%- if role %}

include:
  - .libvirt-fix
  - .utilities
  - .ntp
  - .selinux
  - .network-manager
  - .iptables

{% endif %}
