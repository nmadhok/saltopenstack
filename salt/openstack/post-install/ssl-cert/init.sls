##
# Author: Nitin Madhok
# Date Created: Sunday, June 26, 2015
# Date Last Modified: Tuesday, June 30, 2015
##


{%- set baseFolder = "openstack/post-install/ssl-cert" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}
{%- set dashFQDN = salt['grains.get']('fqdn') %}


{%- if osFamily == 'RedHat' %}

{%- if 'dashboard' in openstackRole %}
{{fileName}} - Make sure desired packages are installed:
  pkg.installed:
    - pkgs:
      - openssl
      - mod_ssl

{{fileName}} - Create a self-signed certificate and a key:
  module.run:
    - name: tls.create_self_signed_cert
    - CN: {{dashFQDN}}
    - bits: 2048
    - ST: "South Carolina"
    - L: "Clemson"
    - O: "Clemson University"
    - OU: "CCIT"
    - emailAddress: "CCIT_ISO_CIS@LISTS.CLEMSON.EDU"
    - unless: "test -f /etc/pki/tls/certs/{{dashFQDN}}.crt"
    - require:
      - pkg: {{fileName}} - Make sure desired packages are installed

{{fileName}} - Move the generated private key from /etc/pki/tls/certs/ to /etc/pki/tls/private/:
  file.rename:
    - name: /etc/pki/tls/private/{{dashFQDN}}.key
    - source: /etc/pki/tls/certs/{{dashFQDN}}.key
    - makedirs: True
    - require:
      - module: {{fileName}} - Create a self-signed certificate and a key

{{fileName}} - Set 'USE_SSL' to 'True' in /etc/openstack-dashboard/local_settings:
  file.replace:
    - name: /etc/openstack-dashboard/local_settings
    - pattern: ^(#*\s*)USE_SSL.* 
    - repl: "USE_SSL = True"
    - append_if_not_found: True

{{fileName}} - Set 'CSRF_COOKIE_SECURE' to 'True' in /etc/openstack-dashboard/local_settings:
  file.replace:
    - name: /etc/openstack-dashboard/local_settings
    - pattern: ^(#*\s*)CSRF_COOKIE_SECURE.* 
    - repl: "CSRF_COOKIE_SECURE = True"
    - append_if_not_found: True

{{fileName}} - Set 'SESSION_COOKIE_SECURE' to 'True' in /etc/openstack-dashboard/local_settings:
  file.replace:
    - name: /etc/openstack-dashboard/local_settings
    - pattern: ^(#*\s*)SESSION_COOKIE_SECURE.* 
    - repl: "SESSION_COOKIE_SECURE = True"
    - append_if_not_found: True

{{fileName}} - Set 'SESSION_COOKIE_HTTPONLY' to 'True' in /etc/openstack-dashboard/local_settings:
  file.replace:
    - name: /etc/openstack-dashboard/local_settings
    - pattern: ^(#*\s*)SESSION_COOKIE_HTTPONLY.* 
    - repl: "SESSION_COOKIE_HTTPONLY = True"
    - append_if_not_found: True

{{fileName}} - Manage file /etc/httpd/conf.d/openstack-dashboard.conf:
  file.managed:
    - name: /etc/httpd/conf.d/openstack-dashboard.conf
    - source: {{baseURL}}/openstack-dashboard.conf
    - template: jinja
    - defaults:
        dashFQDN: {{dashFQDN}}
    - require:
      - pkg: {{fileName}} - Make sure desired packages are installed
      - module: {{fileName}} - Create a self-signed certificate and a key
      - file: {{fileName}} - Move the generated private key from /etc/pki/tls/certs/ to /etc/pki/tls/private/

{{fileName}} - Manage file /etc/httpd/conf.d/ssl.conf:
  file.managed:
    - name: /etc/httpd/conf.d/ssl.conf
    - source: {{baseURL}}/ssl.conf

{{fileName}} - Create file /etc/httpd/conf.d/sslonly.conf to handle http to https redirects:
  file.managed:
    - name: /etc/httpd/conf.d/sslonly.conf
    - contents: |
        <Location />
        SSLRequireSSL on
        </Location>

        RewriteEngine On
        RewriteCond %{HTTPS} off
        RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
        RedirectMatch ^$ https://{{dashFQDN}}/dashboard/
        RedirectMatch ^/$ https://{{dashFQDN}}/dashboard/

{% for service in ['httpd', 'memcached'] %}
{{fileName}} - Restart {{service}}:
  service.running:
    - name: {{service}}
    - enable: True
    - watch:
      - file: {{fileName}} - Set 'USE_SSL' to 'True' in /etc/openstack-dashboard/local_settings
      - file: {{fileName}} - Set 'CSRF_COOKIE_SECURE' to 'True' in /etc/openstack-dashboard/local_settings
      - file: {{fileName}} - Set 'SESSION_COOKIE_SECURE' to 'True' in /etc/openstack-dashboard/local_settings
      - file: {{fileName}} - Set 'SESSION_COOKIE_HTTPONLY' to 'True' in /etc/openstack-dashboard/local_settings
      - file: {{fileName}} - Manage file /etc/httpd/conf.d/openstack-dashboard.conf
      - file: {{fileName}} - Manage file /etc/httpd/conf.d/ssl.conf
      - file: {{fileName}} - Create file /etc/httpd/conf.d/sslonly.conf to handle http to https redirects
{% endfor %}
{% endif %}

{% endif %}
