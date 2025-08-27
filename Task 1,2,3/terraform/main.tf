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

module "security_groups" {
  source = "./modules/security-groups"

  security_groups  = local.config.security_groups
  networks_by_name = local.networks_by_name
  vpc_ids_by_name  = module.network.vpc_ids_by_name
}

module "database" {
  source = "./modules/database"

  dbs            = local.config.databases
  subnets        = module.network.subnets
  sg_ids_by_name = module.security_groups.sg_ids_by_name

  depends_on = [module.network, module.security_groups]
}

module "efs" {
  source = "./modules/efs"

  efs            = local.config.efs
  subnets        = module.network.subnets
  sg_ids_by_name = module.security_groups.sg_ids_by_name

  depends_on = [module.network, module.security_groups]
}

module "asg" {
  source = "./modules/autoscaling-groups"

  sg_ids_by_name  = module.security_groups.sg_ids_by_name
  efs_ids_by_name = module.efs.efs_ids_by_name
  asg             = local.config.asg
  subnets         = module.network.subnets
  db_creds        = module.database.db_creds
  tg_arns_by_name = module.load_balancer.tg_arns_by_name

  depends_on = [module.database, module.efs, module.network, module.security_groups, module.load_balancer]
}

module "load_balancer" {
  source = "./modules/load-balancer"

  sg_ids_by_name  = module.security_groups.sg_ids_by_name
  subnets         = module.network.subnets
  load_balancers  = local.config.load_balancer
  vpc_ids_by_name = module.network.vpc_ids_by_name
  listeners       = local.config.listener
  target_groups   = local.config.target_group

  depends_on = [module.network, module.security_groups]
}

module "vms" {
  source = "./modules/vms"

  vms             = local.config.vms
  sg_ids_by_name  = module.security_groups.sg_ids_by_name
  subnets         = module.network.subnets
  tg_arns_by_name = module.load_balancer.tg_arns_by_name
}