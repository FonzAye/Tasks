terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-central-1"
}

module "network" {
  source = "./modules/network"

  region = "eu-central-1"
  vpcs   = local.config.network
}

module "database" {
  source = "./modules/database"

  dbs = local.config.databases
  subnets = module.network.subnets
}

module "security_groups" {
  source           = "./modules/security-groups"
  security_groups  = local.config.security_groups
  networks_by_name = local.networks_by_name
  vpc_ids_by_name  = module.network.vpc_ids_by_name
}