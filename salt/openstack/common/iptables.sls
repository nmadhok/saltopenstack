##
# Author: Nitin Madhok
# Date Created: Sunday, June 21, 2015
# Date Last Modified: Tuesday, June 23, 2015
##


{%- set baseFolder = "openstack/common" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/iptables.sls" %}
{%- set role = salt['grains.get']('openstack', '') %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == "RedHat" and role %}

{{fileName}} - Make sure firewalld service is not running:
  service.dead:
    - name: firewalld
    - enable: False

{{fileName}} - Make sure iptables is installed and running:
  pkg.installed:
    - name: iptables
  service.running:
    - name: iptables
    - enable: True
    - require:
      - pkg: {{fileName}} - Make sure iptables is installed and running
      - service: {{fileName}} - Make sure firewalld service is not running

{% endif %} 
