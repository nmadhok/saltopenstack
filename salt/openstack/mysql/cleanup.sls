##
# Author: Nitin Madhok
# Date Created: Saturday, June 20, 2015
# Date Last Modified: Tuesday, June 30, 2015
##


{%- set baseFolder = "openstack/mysql" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/cleanup.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Stop mysqld service:
  service.dead:
    - name: mysqld
    - enable: False

{{fileName}} - Remove MySQL client, server packages and it's dependencies:
  pkg.purged:
    - pkgs:
      - mysql
      - mysql-server
      - MySQL-python
      - perl-DBD-MySQL
      - perl-DBI

{{fileName}} - Remove /etc/my.cnf:
  file.absent:
    - name: /etc/my.cnf
    - require:
      - pkg: {{fileName}} - Remove MySQL client, server packages and it's dependencies 

{{fileName}} - Remove /var/lib/mysql:
  file.absent:
    - name: /var/lib/mysql
    - require:
      - pkg: {{fileName}} - Remove MySQL client, server packages and it's dependencies 

{{fileName}} - Remove /etc/cloud-build/openstack/mysql*.done:
  cmd.run:
    - name: rm -f /etc/cloud-build/openstack/mysql*.done
    - onlyif: ls /etc/cloud-build/openstack | grep mysql
    - require:
      - pkg: {{fileName}} - Remove MySQL client, server packages and it's dependencies
{% endif %}

{% if 'compute' in openstackRole or 'network' in openstackRole %}
{{fileName}} - Remove MySQL-python:
  pkg.purged:
    - name: MySQL-python
{% endif %}

{% endif %}
