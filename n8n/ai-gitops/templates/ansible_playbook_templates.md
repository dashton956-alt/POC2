# Example Ansible Playbook Templates for AI Generation

## 1. VLAN Creation Playbook Template

```yaml
---
- name: "AI-Generated VLAN Configuration - {{ tfs_number }}"
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  vars:
    backup_location: "/opt/backups"
    rollback_enabled: true
    
  tasks:
    # Pre-deployment tasks
    - name: "Create backup directory"
      file:
        path: "{{ backup_location }}/{{ tfs_number }}"
        state: directory
      delegate_to: localhost
      
    - name: "Backup current configuration"
      ios_config:
        backup: yes
        backup_options:
          filename: "{{ inventory_hostname }}-{{ tfs_number }}-{{ ansible_date_time.epoch }}.cfg"
          dir_path: "{{ backup_location }}/{{ tfs_number }}"
      register: config_backup
      
    - name: "Validate VLAN ID is not in use"
      ios_command:
        commands: "show vlan id {{ vlan_id }}"
      register: vlan_check
      failed_when: "'VLAN Name' in vlan_check.stdout[0]"
      
    # Main configuration tasks
    - name: "Create VLAN {{ vlan_id }}"
      ios_config:
        lines:
          - "name {{ vlan_name }}"
        parents: "vlan {{ vlan_id }}"
        save_when: changed
      register: vlan_creation
      
    - name: "Configure VLAN interface"
      ios_config:
        lines:
          - "description {{ vlan_description }}"
          - "ip address {{ vlan_ip }} {{ vlan_subnet_mask }}"
          - "no shutdown"
        parents: "interface Vlan{{ vlan_id }}"
        save_when: changed
      when: vlan_ip is defined
      
    # Verification tasks
    - name: "Verify VLAN creation"
      ios_command:
        commands: "show vlan id {{ vlan_id }}"
      register: vlan_verify
      
    - name: "Verify VLAN interface status"
      ios_command:
        commands: "show interface Vlan{{ vlan_id }}"
      register: vlan_interface_verify
      when: vlan_ip is defined
      
    # Post-deployment validation
    - name: "Test VLAN connectivity"
      ios_command:
        commands: "ping {{ vlan_gateway | default(vlan_ip) }}"
      register: connectivity_test
      when: vlan_ip is defined
      ignore_errors: yes
      
  handlers:
    - name: "Rollback configuration"
      ios_config:
        src: "{{ config_backup.backup_path }}"
      when: rollback_enabled and vlan_creation.failed
```

## 2. Routing Configuration Playbook Template

```yaml
---
- name: "AI-Generated Routing Configuration - {{ tfs_number }}"
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  vars:
    backup_location: "/opt/backups"
    
  tasks:
    - name: "Backup configuration"
      ios_config:
        backup: yes
        backup_options:
          filename: "{{ inventory_hostname }}-{{ tfs_number }}-routing.cfg"
          dir_path: "{{ backup_location }}/{{ tfs_number }}"
      register: routing_backup
      
    - name: "Configure static routes"
      ios_config:
        lines:
          - "ip route {{ item.network }} {{ item.mask }} {{ item.next_hop }}"
        save_when: changed
      loop: "{{ static_routes }}"
      when: static_routes is defined
      
    - name: "Configure OSPF"
      ios_config:
        lines:
          - "router-id {{ router_id }}"
          - "network {{ item.network }} {{ item.wildcard }} area {{ item.area }}"
        parents: "router ospf {{ ospf_process_id }}"
        save_when: changed
      loop: "{{ ospf_networks }}"
      when: ospf_networks is defined
      
    - name: "Verify routing table"
      ios_command:
        commands: "show ip route"
      register: routing_table
      
    - name: "Test connectivity to destinations"
      ios_command:
        commands: "ping {{ item }}"
      loop: "{{ test_destinations | default([]) }}"
      register: connectivity_tests
      ignore_errors: yes
```

## 3. ACL Configuration Playbook Template

```yaml
---
- name: "AI-Generated ACL Configuration - {{ tfs_number }}"
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  tasks:
    - name: "Backup current ACL configuration"
      ios_command:
        commands: "show access-lists"
      register: current_acls
      
    - name: "Save ACL backup"
      copy:
        content: "{{ current_acls.stdout[0] }}"
        dest: "{{ backup_location }}/{{ tfs_number }}/{{ inventory_hostname }}-acls.txt"
      delegate_to: localhost
      
    - name: "Configure standard ACL"
      ios_config:
        lines: "{{ acl_entries }}"
        parents: "ip access-list standard {{ acl_name }}"
        replace: block
        save_when: changed
      when: acl_type == "standard"
      
    - name: "Configure extended ACL"
      ios_config:
        lines: "{{ acl_entries }}"
        parents: "ip access-list extended {{ acl_name }}"
        replace: block
        save_when: changed
      when: acl_type == "extended"
      
    - name: "Apply ACL to interface"
      ios_config:
        lines: "ip access-group {{ acl_name }} {{ acl_direction }}"
        parents: "interface {{ interface }}"
        save_when: changed
      when: interface is defined and acl_direction is defined
      
    - name: "Verify ACL configuration"
      ios_command:
        commands: 
          - "show access-lists {{ acl_name }}"
          - "show interface {{ interface | default('') }} | include access list"
      register: acl_verification
```

## 4. Interface Configuration Playbook Template

```yaml
---
- name: "AI-Generated Interface Configuration - {{ tfs_number }}"
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  tasks:
    - name: "Backup interface configuration"
      ios_command:
        commands: "show running-config interface {{ interface_name }}"
      register: interface_backup
      
    - name: "Configure interface settings"
      ios_config:
        lines:
          - "description {{ interface_description | default('AI-configured interface') }}"
          - "{% if interface_ip %}ip address {{ interface_ip }} {{ interface_mask }}{% endif %}"
          - "{% if interface_duplex %}duplex {{ interface_duplex }}{% endif %}"
          - "{% if interface_speed %}speed {{ interface_speed }}{% endif %}"
          - "{% if not interface_shutdown %}no shutdown{% else %}shutdown{% endif %}"
        parents: "interface {{ interface_name }}"
        save_when: changed
      register: interface_config
      
    - name: "Configure switchport settings"
      ios_config:
        lines:
          - "switchport mode {{ switchport_mode | default('access') }}"
          - "{% if access_vlan %}switchport access vlan {{ access_vlan }}{% endif %}"
          - "{% if trunk_vlans %}switchport trunk allowed vlan {{ trunk_vlans }}{% endif %}"
        parents: "interface {{ interface_name }}"
        save_when: changed
      when: switchport_enabled | default(false)
      
    - name: "Verify interface status"
      ios_command:
        commands: 
          - "show interface {{ interface_name }}"
          - "show interface {{ interface_name }} status"
      register: interface_status
      
    - name: "Test interface connectivity"
      ios_command:
        commands: "ping {{ test_ip }}"
      when: test_ip is defined and interface_ip is defined
      register: connectivity_test
      ignore_errors: yes
```

## 5. QoS Configuration Playbook Template

```yaml
---
- name: "AI-Generated QoS Configuration - {{ tfs_number }}"
  hosts: network_devices
  gather_facts: no
  connection: network_cli
  
  tasks:
    - name: "Backup current QoS configuration"
      ios_command:
        commands: 
          - "show policy-map"
          - "show class-map"
      register: qos_backup
      
    - name: "Create class-map for traffic classification"
      ios_config:
        lines: "{{ class_map_config }}"
        parents: "class-map {{ class_map_name }}"
        save_when: changed
      loop: "{{ class_maps }}"
      loop_control:
        loop_var: class_map
      vars:
        class_map_name: "{{ class_map.name }}"
        class_map_config: "{{ class_map.match_criteria }}"
      
    - name: "Create policy-map for QoS actions"
      ios_config:
        lines: "{{ policy_config }}"
        parents: "policy-map {{ policy_name }}"
        save_when: changed
      vars:
        policy_name: "{{ qos_policy.name }}"
        policy_config: "{{ qos_policy.classes }}"
      
    - name: "Apply service-policy to interface"
      ios_config:
        lines: "service-policy {{ policy_direction }} {{ policy_name }}"
        parents: "interface {{ interface }}"
        save_when: changed
      loop: "{{ qos_interfaces }}"
      vars:
        interface: "{{ item.interface }}"
        policy_name: "{{ item.policy }}"
        policy_direction: "{{ item.direction }}"
        
    - name: "Verify QoS configuration"
      ios_command:
        commands:
          - "show policy-map interface {{ interface }}"
          - "show qos interface {{ interface }}"
      register: qos_verification
      loop: "{{ qos_interfaces }}"
```

## AI Prompt Engineering Guidelines

When generating these playbooks, the AI should follow these patterns:

1. **Always include backup tasks** before making changes
2. **Add verification tasks** after configuration changes  
3. **Include rollback handlers** for error scenarios
4. **Use proper variable substitution** from NetBox data
5. **Add connectivity tests** where applicable
6. **Follow Ansible best practices** (idempotency, error handling)
7. **Include proper task naming** with TFS numbers
8. **Add conditional logic** based on device types/capabilities

## Variable Files Structure

The AI should generate variable files in this format:

```yaml
# group_vars/all.yml
tfs_number: "{{ tfs_number }}"
environment: "{{ environment }}"
backup_enabled: true
rollback_enabled: true

# Network-specific variables from NetBox
devices: "{{ netbox_devices }}"
sites: "{{ netbox_sites }}"
vlans: "{{ netbox_vlans }}"

# Change-specific variables
change_type: "{{ change_type }}"
change_priority: "{{ change_priority }}"
requested_by: "{{ requested_by }}"

# Safety settings
max_concurrent_changes: 3
change_window_start: "02:00"
change_window_end: "06:00"
require_maintenance_window: true
```

This comprehensive template library ensures consistent, safe, and reliable network automation across all AI-generated playbooks.
