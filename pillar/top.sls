{% set openstackCluster = salt['grains.get']('openstack:CLUSTER', '') %}

base:
  'openstack:CLUSTER:{{openstackCluster}}':
    - match: grain
    - openstack.{{openstackCluster}}
