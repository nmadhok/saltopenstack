##
# Author: Nitin Madhok
# Date Created: Sunday, June 21, 2015
# Date Last Modified: Monday, June 23, 2015
##


{%- set baseFolder = "openstack/common" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/network-manager.sls" %}
{%- set role = salt['grains.get']('openstack', '') %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == "RedHat" and role %}

{{fileName}} - Make sure NetworkManager service is not running:
  service.dead:
    - name: NetworkManager
    - enable: False

{{fileName}} - Make sure network service is running instead:
  service.running:
    - name: network
    - enable: True
    - require:
      - service: {{fileName}} - Make sure NetworkManager service is not running

{% endif %} 
