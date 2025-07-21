resource "aws_launch_template" "foobar" {
  name_prefix            = "foobar"
  image_id               = "ami-0af9b40b1a16fe700"
  instance_type          = "t2.micro"
  vpc_security_group_ids = values(var.sg_ids_by_name)
  user_data = base64encode(templatefile("${path.root}/scripts/user_data.sh.tmpl", {
    efs_id = module.efs.id
  }))
}

resource "aws_autoscaling_group" "bar" {
  name                = "foobar3-terraform-test"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  force_delete        = true
  vpc_zone_identifier = ["subnet-0bd41f3a69d62066c", "subnet-05271ab60a8358dde"]

  launch_template {
    id      = aws_launch_template.foobar.id
    version = "$Latest"
  }
}
