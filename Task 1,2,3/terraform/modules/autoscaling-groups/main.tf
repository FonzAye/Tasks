locals {
  asgs = { for name, asg in var.asg : name => asg }

  db_creds = { for name, db in var.db_creds : name => db }
}

resource "aws_launch_template" "this" {
  for_each = local.asgs

  name          = each.value.launch_template.name
  image_id      = "ami-0af9b40b1a16fe700"
  instance_type = each.value.launch_template.instance_type
  vpc_security_group_ids = [
    for k in each.value.launch_template.security_groups : var.sg_ids_by_name[k]
  ]
  user_data = base64encode(templatefile("${path.root}/scripts/user_data.sh.tmpl", {
    RDS_ENDPOINT = split(":", var.db_creds[each.value.launch_template.db_name].endpoint)[0],
    DB_NAME      = var.db_creds[each.value.launch_template.db_name].db_name,
    DB_USER      = var.db_creds[each.value.launch_template.db_name].username,
    DB_PASSWORD  = var.db_creds[each.value.launch_template.db_name].password,
    efs_id       = var.efs_ids_by_name[each.value.launch_template.efs_name],

    es_1_ip      = var.vms_private_ips["es-1"],
    es_1_dns     = var.vms_public_dns_names["es-1"],
    es_2_ip      = var.vms_private_ips["es-2"],
    es_2_dns     = var.vms_public_dns_names["es-2"],
    kibana_ip    = var.vms_private_ips["kibana"],
    kibana_dns   = var.vms_public_dns_names["kibana"],
    logstash_ip  = var.vms_private_ips["logstash"],
    logstash_dns = var.vms_public_dns_names["logstash"],
  }))
  iam_instance_profile {
    name = "ec2-instance-profile"
  }
  key_name = "pipi"
}

resource "aws_autoscaling_group" "this" {
  for_each = local.asgs

  name             = each.value.name
  desired_capacity = each.value.desired_capacity
  max_size         = each.value.max_size
  min_size         = each.value.min_size
  force_delete     = each.value.force_delete
  target_group_arns = [
    for k in each.value.target_groups : var.tg_arns_by_name[k]
  ]
  vpc_zone_identifier = [
    for k in each.value.subnets : var.subnets[k]
  ]

  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
}


# ----------------------------------------
# IAM Role for EC2 Instances
# ----------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"

  # Trust policy: allow EC2 to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  description = "IAM role assumed by EC2 instances with EC2 and EFS access"
}

# ----------------------------------------
# Attach AWS Managed Policies to the Role
# ----------------------------------------

# Full EC2 Access
resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Full EFS Client Access
resource "aws_iam_role_policy_attachment" "efs_client_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}

# ----------------------------------------
# IAM Instance Profile
# ----------------------------------------
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
