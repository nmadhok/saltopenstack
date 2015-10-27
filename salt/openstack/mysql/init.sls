##
# Author: Nitin Madhok
# Date Created: Saturday, June 20, 2015
# Date Last Modified: Tuesday, June 30, 2015
##

{%- set baseFolder = "openstack/mysql" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}
{%- set dbRootPass = salt['pillar.get']('openstack:DB_PASS', 'dbPass') %}
{%- set bindAddress = salt['grains.get']('host', '0.0.0.0') %}


{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Install MySQL client, server and it's Python library:
  pkg.installed:
    - pkgs:
      - mysql
      - mysql-server
      - MySQL-python

{{fileName}} - Add required options to /etc/my.cnf:
  file.managed:
    - name: /etc/my.cnf
    - contents: |
        [mysqld]
        datadir=/var/lib/mysql
        socket=/var/lib/mysql/mysql.sock
        user=mysql
        # Disabling symbolic-links is recommended to prevent assorted security risks
        symbolic-links=0
        bind-address = {{ bindAddress }}
        default-storage-engine = innodb
        innodb_file_per_table
        collation-server = utf8_general_ci
        init-connect = 'SET NAMES utf8'
        character-set-server = utf8

        [mysqld_safe]
        log-error=/var/log/mysqld.log
        pid-file=/var/run/mysqld/mysqld.pid
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: {{fileName}} - Install MySQL client, server and it's Python library

{{fileName}} - Start MySQL database server and set it to automatically start at boot:
  service.running:
    - name: mysqld
    - enable: True
    - watch:
      - file: {{fileName}} - Add required options to /etc/my.cnf
    - require:
      - pkg: {{fileName}} - Install MySQL client, server and it's Python library

{{fileName}} - Create /etc/cloud-build/openstack directory if not already present:
  file.directory:
    - name: /etc/cloud-build/openstack
    - makedirs: True

{{fileName}} - Run mysql_install_db:
  cmd.run:
    - name: /usr/bin/mysql_install_db | tee /etc/cloud-build/openstack/mysql-install-db.done
    - unless: test -f /etc/cloud-build/openstack/mysql-install-db.done
    - require:
      - pkg: {{fileName}} - Install MySQL client, server and it's Python library

{{fileName}} - Run mysql_secure_installation:
  cmd.run:
    - name: echo -e "\n\n{{dbRootPass}}\n{{dbRootPass}}\n\n\n\n\n " | /usr/bin/mysql_secure_installation | tee /etc/cloud-build/openstack/mysql-secure.done
    - unless: test -f /etc/cloud-build/openstack/mysql-secure.done
    - require:
      - pkg: {{fileName}} - Install MySQL client, server and it's Python library
{% endif %}

{% if 'compute' in openstackRole or 'network' in openstackRole %}
{{fileName}} - Install MySQL-python:
  pkg.installed:
    - name: MySQL-python
{% endif %}

{% endif %}
