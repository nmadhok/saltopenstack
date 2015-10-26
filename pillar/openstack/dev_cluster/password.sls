{%- set roleOpenstack = salt['grains.get']('openstack:ROLE', []) %}
{%- set hostName = salt['grains.get']('host') %}

{%- set messagingType = 'qpid' %}
{%- set messagingPass = '8bcd735a7c1d7bca7d2f' %}
{%- set networkingType = 'neutron' %}
{%- set tenantNetworkTypes = ['gre'] %}
{%- set controllerHost = 'dev-controller.mydomain.com' %}
{%- set adminEmail = 'admin@mydomain.com' %}
{%- set adminPass = '21d90a08a41ba4fbb59c' %}
{%- set adminToken = '5b51862412cd005c2da9' %}
{%- set dbRootPass = '8b1bb0fda2bc2a0939d4' %}
{%- set keystoneDbPass = '8bcd735a7c1d7bca7d2f' %}
{%- set glanceDbPass = '5b01c2d3aee51249894c' %}
{%- set glancePass = '1ba4edd4371ef8c47bcd' %}
{%- set novaDbPass = '5acb70686bfc9c987186' %}
{%- set novaPass = '55788928856b013ce1dc' %}
{%- set neutronDbPass = '9bf0b753b53af043ada0' %}
{%- set neutronPass = '794b943c1eefdb65a575' %}
{%- set metadataSecret = '9798da2805d73045cb1e' %}


openstack:
  MESSAGING_TYPE: {{messagingType}}
  MESSAGING_PASS: {{messagingPass}}
  NETWORKING_TYPE: {{networkingType}}
  CONTROLLER_HOST: {{controllerHost}}
  TENANT_NETWORK_TYPES: {{tenantNetworkTypes}}
{% if 'controller' in roleOpenstack %}
  ADMIN_EMAIL: {{adminEmail}}
  ADMIN_PASS: {{adminPass}}
  ADMIN_TOKEN: {{adminToken}}
  DB_PASS: {{dbRootPass}}
  KEYSTONE_DBPASS: {{keystoneDbPass}}
  GLANCE_DBPASS: {{glanceDbPass}}
  GLANCE_PASS: {{glancePass}}
  NOVA_DBPASS: {{novaDbPass}}
  NOVA_PASS: {{novaPass}}
  NEUTRON_DBPASS: {{neutronDbPass}}
  NEUTRON_PASS: {{neutronPass}}
  METADATA_SECRET: {{metadataSecret}}
{% endif %}

{% if 'compute' in roleOpenstack and 'network' in roleOpenstack %}
  NOVA_DBPASS: {{novaDbPass}}
  NOVA_PASS: {{novaPass}}
  NEUTRON_DBPASS: {{neutronDbPass}}
  NEUTRON_PASS: {{neutronPass}}
  METADATA_SECRET: {{metadataSecret}}
{% elif 'compute' in roleOpenstack %}
  NOVA_DBPASS: {{novaDbPass}}
  NOVA_PASS: {{novaPass}}
  NEUTRON_PASS: {{neutronPass}}
{% elif 'network' in roleOpenstack %}
  NEUTRON_DBPASS: {{neutronDbPass}}
  NEUTRON_PASS: {{neutronPass}}
  METADATA_SECRET: {{metadataSecret}}
{% endif %}
