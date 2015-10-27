##
# Author: Nitin Madhok
# Date Created: Wednesday, June 24, 2015
# Date Last Modified: Tuesday, June 30, 2015
##


{%- set baseFolder = "openstack/networking/legacy" %}
{%- set baseURL = "salt://" ~ baseFolder %}
{%- set fileName = baseFolder ~ "/init.sls" %}
{%- set openstackRole = salt['grains.get']('openstack:ROLE', []) %}
{%- set osFamily = salt['grains.get']('os_family', '') %}


{%- if osFamily == 'RedHat' %}

{%- if 'controller' in openstackRole %}
{{fileName}} - Set 'network_api_class' to 'nova.network.api.API' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.api.API"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT network_api_class) = nova.network.api.API ]"

{{fileName}} - Set 'security_group_api' to 'nova' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api nova"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT security_group_api) = nova ]"

{% for service in ['openstack-nova-api', 'openstack-nova-scheduler', 'openstack-nova-conductor'] %}
{{fileName}} - Restart {{service}}:
  service.running:
    - name: {{service}}
    - enable: True
    - watch:
      - cmd: {{fileName}} - Set 'network_api_class' to 'nova.network.api.API' in /etc/nova/nova.conf
      - cmd: {{fileName}} - Set 'security_group_api' to 'nova' in /etc/nova/nova.conf
{% endfor %}
{% endif %}

{% if 'compute' in openstackRole %}
{{fileName}} - Install legacy networking components:
  pkg.installed:
    - pkgs:
      - openstack-nova-network
      - openstack-nova-api

{{fileName}} - Set 'network_api_class' to 'nova.network.api.API' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.api.API"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT network_api_class) = nova.network.api.API ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'security_group_api' to 'nova' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api nova"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT security_group_api) = nova ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'network_manager' to 'nova.network.manager.FlatDHCPManager' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT network_manager nova.network.manager.FlatDHCPManager"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT network_manager) = nova.network.manager.FlatDHCPManager ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'firewall_driver' to '' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.libvirt.firewall.IptablesFirewallDriver"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT firewall_driver) = nova.virt.libvirt.firewall.IptablesFirewallDriver ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'network_size' to '254' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT network_size 254"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT network_size) = 254 ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'allow_same_net_traffic' to 'False' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT allow_same_net_traffic False"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT allow_same_net_traffic) = False ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'multi_host' to 'True' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT multi_host True"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT multi_host) = True ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'send_arp_for_ha' to 'True' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT send_arp_for_ha True"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT send_arp_for_ha) = True ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'share_dhcp_address' to 'True' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT share_dhcp_address True"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT share_dhcp_address) = True ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'force_dhcp_release' to 'True' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT force_dhcp_release True"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT force_dhcp_release) = True ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'flat_network_bridge' to 'br100' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT flat_network_bridge br100"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT flat_network_bridge) = br100 ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'flat_interface' to 'eth2' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT flat_interface eth2"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT flat_interface) = eth2 ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{{fileName}} - Set 'public_interface' to 'eth2' in /etc/nova/nova.conf:
  cmd.run:
    - name: "openstack-config --set /etc/nova/nova.conf DEFAULT public_interface eth2"
    - unless: "[ $(openstack-config --get /etc/nova/nova.conf DEFAULT public_interface) = eth2 ]"
    - watch_in:
      - service: {{fileName}} - Make sure openstack-nova-network service is running and enable it to start at boot
      - service: {{fileName}} - Make sure openstack-nova-metadata-api service is running and enable it to start at boot

{% for service in ['openstack-nova-network', 'openstack-nova-metadata-api'] %}
{{fileName}} - Make sure {{service}} service is running and enable it to start at boot:
  service.running:
    - name: {{service}}
    - enable: True
{% endfor %}
{% endif %}

{% endif %}
