terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "network" {
  source = "./modules/network"

  region             = "eu-central-1"
  vpcs               = local.config.network
  create_nat_gateway = false
}

module "database" {
  source = "./modules/database"

  dbs            = local.config.databases
  subnets        = module.network.subnets
  sg_ids_by_name = module.security_groups.sg_ids_by_name
  depends_on     = [module.network, module.security_groups]
}

module "security_groups" {
  source = "./modules/security-groups"

  security_groups  = local.config.security_groups
  networks_by_name = local.networks_by_name
  vpc_ids_by_name  = module.network.vpc_ids_by_name
}

module "efs" {
  source = "./modules/efs"

  efs            = local.config.efs
  subnets        = module.network.subnets
  sg_ids_by_name = module.security_groups.sg_ids_by_name
  depends_on     = [module.network, module.security_groups]
}

module "asg" {
  source = "./modules/autoscaling-groups"

  sg_ids_by_name  = module.security_groups.sg_ids_by_name
  efs_ids_by_name = module.efs.efs_ids_by_name
  asg             = local.config.asg
  subnets         = module.network.subnets
  depends_on      = [module.database, module.efs, module.network, module.security_groups]
}
