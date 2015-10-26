{%- set baseFolder = "openstack" %}
{%- set openstackCluster = salt['grains.get']('openstack:CLUSTER', '') %}
{%- set baseURL = baseFolder ~ "." ~ openstackCluster %}

include:
  - {{baseURL}}.password
