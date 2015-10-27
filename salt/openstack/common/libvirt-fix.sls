##
# Author: Nitin Madhok
# Date Created: Friday, July 03, 2015
# Date Last Modified: Friday, July 03, 2015
##


{%- set baseFolder = "openstack/common" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/libvirt-fix.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == "RedHat" and 'compute' in openstackRole %}

{{fileName}} - Exclude libvirt-*1.1.3* in /etc/yum.conf:
  file.append:
    - name: /etc/yum.conf
    - text: "exclude=libvirt-*1.1.3*"

{{fileName}} - Install libvirt packages:
  pkg.installed:
    - pkgs:
      - libvirt
      - libvirt-client
      - python-libguestfs
      - libguestfs
      - libvirt-python
    - require:
      - file: {{fileName}} - Exclude libvirt-*1.1.3* in /etc/yum.conf

{% endif %}
