##
# Author: Nitin Madhok
# Date Created: Thursday, June 25, 2015
# Date Last Modified: Thursday, June 25, 2015
##


{%- set baseFolder = "openstack/post-install" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set role = salt['grains.get']('openstack', '') %}

{%- if role %}

include:
  - .ssl-cert
#  - .ldap-plugin
  - .create-users

{% endif %}
