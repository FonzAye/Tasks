locals {
  config = jsondecode(file("${path.root}/config/config.json"))

  networks_by_name = { for n in local.config.networks : n.name => n.cidr }
}