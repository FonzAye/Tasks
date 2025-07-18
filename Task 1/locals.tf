locals {
  config = jsondecode(file("${path.root}/config/config.json"))
}