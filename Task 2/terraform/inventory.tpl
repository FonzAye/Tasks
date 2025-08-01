[all]
%{ for name in node_names ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]}
%{ endfor }

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
