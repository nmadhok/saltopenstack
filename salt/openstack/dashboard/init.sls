##
# Author: Nitin Madhok
# Date Created: Wednesday, June 24, 2015
# Date Last Modified: Tuesday, June 30, 2015
##

{%- set baseFolder = "openstack/dashboard" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}
{%- set controllerHost = salt['pillar.get']('openstack:CONTROLLER_HOST', '') %}
{%- set dashFQDN = salt['grains.get']('fqdn') %}
{%- set dashIP = salt['grains.get']('ip4_interfaces:eth1')[0] %}


{%- if osFamily == 'RedHat' %}

{%- if 'dashboard' in openstackRole %}
{{fileName}} - Install Openstack Dashboard packages and memcached:
  pkg.installed:
    - pkgs:
      - memcached
      - python-memcached
      - mod_wsgi
      - openstack-dashboard

{{fileName}} - Manage file /etc/sysconfig/memcached:
  file.managed:
    - name: /etc/sysconfig/memcached
    - contents: |
        PORT="11211"
        USER="memcached"
        MAXCONN="1024"
        CACHESIZE="256"
        OPTIONS="-k -l 127.0.0.1"
    - require:
      - pkg: {{fileName}} - Install Openstack Dashboard packages and memcached

{{fileName}} - Manage file /etc/openstack-dashboard/local_settings:
  file.managed:
    - name: /etc/openstack-dashboard/local_settings
    - source: {{baseURL}}/local_settings
    - makedirs: True
    - template: jinja
    - defaults:
        controllerHost: {{controllerHost}}
        dashFQDN: {{dashFQDN}}
        dashIP: {{dashIP}}
    - require:
      - pkg: {{fileName}} - Install Openstack Dashboard packages and memcached
      - file: {{fileName}} - Manage file /etc/sysconfig/memcached

{{fileName}} - Manage file /etc/ld.so.conf:
  file.managed:
    - name: /etc/ld.so.conf
    - contents: "include ld.so.conf.d/*.conf"

{{fileName}} - Run ldconfig:
  cmd.wait:
    - name: "ldconfig"
    - watch:
      - file: {{fileName}} - Manage file /etc/ld.so.conf

{{fileName}} - Ensure SELinux policy allows network connections to the HTTP server:
  cmd.run:
    - name: "setsebool -P httpd_can_network_connect on"
    - unless: 'getsebool httpd_can_network_connect | grep "httpd_can_network_connect --> on"'

{{fileName}} - Start httpd service:
  service.running:
    - name: httpd
    - enable: True
    - watch:
      - file: {{fileName}} - Manage file /etc/sysconfig/memcached
      - file: {{fileName}} - Manage file /etc/openstack-dashboard/local_settings
      - cmd: {{fileName}} - Run ldconfig
    - require:
      - pkg: {{fileName}} - Install Openstack Dashboard packages and memcached

{{fileName}} - Start memcached service:
  service.running:
    - name: memcached
    - enable: True
    - watch:
      - file: {{fileName}} - Manage file /etc/sysconfig/memcached
      - service: {{fileName}} - Start httpd service
    - require:
      - pkg: {{fileName}} - Install Openstack Dashboard packages and memcached
{% endif %}

{% endif %}
