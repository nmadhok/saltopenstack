##
# Author: Nitin Madhok
# Date Created: Sunday, June 21, 2015
# Date Last Modified: Tuesday, June 23, 2015
##


{%- set baseFolder = "openstack/common" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/utilities.sls" %}
{%- set role = salt['grains.get']('openstack', '') %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == 'RedHat' and role %}

{{fileName}} - Install OpenStack utilities and command line clients:
  pkg.installed:
    - pkgs:
      - openstack-utils
      - openstack-selinux
      - python-novaclient
      - python-keystoneclient
      - python-glanceclient
      - python-neutronclient

{% endif %}
