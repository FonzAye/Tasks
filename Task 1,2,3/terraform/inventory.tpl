[all]
%{ for name in node_names ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]}
%{ endfor }

[bastion]
%{ for name in node_names ~}
%{ if startswith(name, "bastion") ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]}
%{ endif ~}
%{ endfor ~}

[elasticsearch]
%{ for name in node_names ~}
%{ if startswith(name, "es-") ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]} ansible_ssh_common_args='-o ProxyJump=ec2-user@${bastion_ip}'
%{ endif ~}
%{ endfor ~}

[kibana]
%{ for name in node_names ~}
%{ if startswith(name, "kibana") ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]} ansible_ssh_common_args='-o ProxyJump=ec2-user@${bastion_ip}'
%{ endif ~}
%{ endfor ~}

[logstash]
%{ for name in node_names ~}
%{ if startswith(name, "logstash") ~}
${name} ansible_host=${public_dns_names[name]} private_ip=${private_ips[name]} ansible_ssh_common_args='-o ProxyJump=ec2-user@${bastion_ip}'
%{ endif ~}
%{ endfor ~}

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
