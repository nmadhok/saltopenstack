##
# Author: Nitin Madhok
# Date Created: Monday, June 22, 2015
# Date Last Modified: Tuesday, June 30, 2015
##


{%- set baseFolder = "openstack/messaging" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set messagingType = salt['pillar.get']('openstack:MESSAGING_TYPE', 'rabbitmq') %}


{%- if 'controller' in openstackRole %}

include:
{% if messagingType == 'qpid' %}
  - .qpid
{% elif messagingType == 'zeromq' %}
  - .zeromq
{% else %}
  - .rabbitmq
{% endif %}

{% endif %}
