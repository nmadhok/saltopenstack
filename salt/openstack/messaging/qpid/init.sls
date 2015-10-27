##
# Author: Nitin Madhok
# Date Created: Sunday, June 21, 2015
# Date Last Modified: Monday, July 13, 2015
##


{%- set baseFolder = "openstack/messaging/qpid" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}
{%- set qpidUser = salt['pillar.get']('openstack:MESSAGING_USER', 'qpid') %}
{%- set qpidPass = salt['pillar.get']('openstack:MESSAGING_PASS', 'qpidPass') %}
{%- set qpidRealm = salt['pillar.get']('openstack:MESSAGING_REALM', 'QPID') %}


{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Install qpid server package and start service:
  pkg.installed:
    - name: qpid-cpp-server

{{fileName}} - Install cyrus-sasl packages for SASL authentication:
  pkg.installed:
    - pkgs:
      - cyrus-sasl-plain
      - cyrus-sasl-md5

{{fileName}} - Create '{{qpidUser}}' user having '{{qpidPass}}' password in '{{qpidRealm}}' realm:
  cmd.run:
    - name: 'echo -e {{qpidPass}} | saslpasswd2 -f /var/lib/qpidd/qpidd.sasldb -u {{qpidRealm}} {{qpidUser}}'
    - unless: 'sasldblistusers2 -f /var/lib/qpidd/qpidd.sasldb | grep {{qpidUser}}@{{qpidRealm}}'
    - require:
      - pkg: {{fileName}} - Install qpid server package and start service

{{fileName}} - Enable SASL authentication for messaging broker in /etc/qpidd.conf:
  file.replace:
    - name: /etc/qpidd.conf
    - pattern: ^auth=.*
    - repl: "auth=yes"
    - append_if_not_found: True
    - onlyif: test -f /etc/qpidd.conf
    - require:
      - pkg: {{fileName}} - Install qpid server package and start service

{{fileName}} - Set the realm to be used to 'QPID' in /etc/qpidd.conf:
  file.replace:
    - name: /etc/qpidd.conf
    - pattern: ^realm=.*
    - repl: "realm=QPID"
    - append_if_not_found: True
    - onlyif: test -f /etc/qpidd.conf
    - require:
      - pkg: {{fileName}} - Install qpid server package and start service
      - file: {{fileName}} - Enable SASL authentication for messaging broker in /etc/qpidd.conf

{{fileName}} - Set 'mech_list' to 'DIGEST-MD5' in /etc/sasl2/qpidd.conf:
  file.replace:
    - name: /etc/sasl2/qpidd.conf
    - pattern: ^mech_list:.*
    - repl: "mech_list: DIGEST-MD5"
    - append_if_not_found: True
    - onlyif: test -f /etc/sasl2/qpidd.conf
    - require:
      - pkg: {{fileName}} - Install qpid server package and start service
      - pkg: {{fileName}} - Install cyrus-sasl packages for SASL authentication

{{fileName}} - Start qpidd service and enable it to automatically start at boot:
  service.running:
    - name: qpidd
    - enable: True
    - require:
      - pkg: {{fileName}} - Install qpid server package and start service
    - watch:
      - file: {{fileName}} - Enable SASL authentication for messaging broker in /etc/qpidd.conf
      - file: {{fileName}} - Set the realm to be used to 'QPID' in /etc/qpidd.conf
      - file: {{fileName}} - Set 'mech_list' to 'DIGEST-MD5' in /etc/sasl2/qpidd.conf
{% endif %}

{% endif %}
