locals {
  db_name = "maindb" # Default database name

  inventory = templatefile("${path.root}/inventory.tpl", {
    node_names       = module.vms.node_names
    private_ips      = module.vms.private_ips
    public_dns_names = module.vms.public_dns_names
    private_key_path = "~/.ssh/id_rsa"
    bastion_ip       = module.vms.public_dns_names["bastion"]
  })
}

resource "local_file" "ansible_inventory" {
  content  = local.inventory
  filename = "${path.root}/../ansible/inventory/inventory.ini"
}
