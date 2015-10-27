##
# Author: Nitin Madhok
# Date Created: Monday, June 8, 2015
# Date Last Modified: Tuesday, June 23, 2015
##


{%- set baseFolder = "openstack/common/ntp" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set role = salt['grains.get']('openstack', '') %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == "RedHat" and role %}

{{fileName}} - Install ntp package:
  pkg.installed:
    - name: ntp
  service.running:
    - name: ntpd
    - enable: True
    - watch:
      - pkg: {{fileName}} - Install ntp package
      - file: {{fileName}} - Replace /etc/sysconfig/ntpd

{{fileName}} - Replace /etc/sysconfig/ntpd:
  file.managed:
    - name: /etc/sysconfig/ntpd
    - contents: |
        #20091021 /etc/sysconfig/ntpd
        OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid -g"
        SYNC_HWCLOCK=no
        NTPDATE_OPTIONS=""

{% endif %} 
