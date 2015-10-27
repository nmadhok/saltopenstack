##
# Author: Nitin Madhok
# Date Created: Thursday, June 18, 2015
# Date Last Modified: Tuesday, June 23, 2015
##


{%- set baseFolder = "openstack/common" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/selinux.sls" %}
{%- set role = salt['grains.get']('openstack', '') %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == "RedHat" and role %}

{{fileName}} - Disable SELinux:
  cmd.run:
    - name: "setenforce 0"
    - onlyif: getenforce | grep "Enforcing"
  file.replace:
    - name: /etc/sysconfig/selinux
    - pattern: "^SELINUX=enforcing"
    - repl: "SELINUX=permissive"

{% endif %}
