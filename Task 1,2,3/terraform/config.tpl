# ansible.cfg
[defaults]
host_key_checking = False
inventory = inventory/inventory.ini

[ssh_connection]
ssh_args = -o ProxyJump=ec2-user@${bastion_ip}