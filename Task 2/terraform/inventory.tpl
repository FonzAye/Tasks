[all]
%{ for name in node_names ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]}
%{ endfor }

[elasticsearch]
%{ for name in node_names ~}
%{ if startswith(name, "es-") ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]}
%{ endif ~}
%{ endfor ~}

[kibana]
%{ for name in node_names ~}
%{ if startswith(name, "kibana") ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]}
%{ endif ~}
%{ endfor ~}

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
