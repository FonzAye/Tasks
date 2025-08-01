locals {
  vms = { for vm in var.vms : vm.name => vm }

  sbs = { for k, sb in var.subnets : k => sb }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "vm" {
  for_each = local.vms

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  subnet_id                   = local.sbs[each.value.subnet]
  associate_public_ip_address = true
  vpc_security_group_ids      = [for sg_name in each.value.security_groups : var.sg_ids_by_name[sg_name]]
  key_name                    = aws_key_pair.ssh-key.key_name
  # iam_instance_profile        = each.value.iam_instance_profile_name != null ? each.value.iam_instance_profile_name : null // not used in new cfg
  tags = {
    Name = each.value.name
  }

  # user_data = file("${path.root}/scripts/${each.value.user_data}")
}
