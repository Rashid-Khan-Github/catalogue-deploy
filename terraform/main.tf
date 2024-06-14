module "catalogue_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  ami                    = data.aws_ami.devops_ami.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  # It should be in Private Subnet
  subnet_id = local.private_subnet_id
  # user_data = file("catalogue.sh")

  tags = merge(
    {
      Name = "${var.common_tags.Component}-${var.env}"
    },
    var.common_tags
  )
}


resource "null_resource" "provision_script" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.catalogue_instance.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    type     = "ssh"
    user     = "centos"
    password = "DevOps321"
    host     = module.catalogue_instance.private_ip
  }

  # copy the file
  provisioner "file" {
    source      = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "sudo chmod +x /tmp/catalogue.sh",
      "sudo sh /tmp/catalogue.sh ${var.app_version}"
    ]
  }
}


resource "aws_ec2_instance_state" "ec2_stopped_state" {
  instance_id = module.catalogue_instance.id
  state       = "stopped"
  depends_on  = [ null_resource.provision_script ]
}


resource "aws_ami_from_instance" "catalogue_ami" {
  name               = "${var.common_tags.Component}-${var.env}-${local.current_time}"
  source_instance_id = module.catalogue_instance.id
  depends_on         = [ aws_ec2_instance_state.ec2_stopped_state ]
}


resource "null_resource" "delete_instance" {
  triggers = {
    ami_id = aws_ami_from_instance.catalogue_ami.id
  }
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${module.catalogue_instance.id}"
  }

  depends_on = [ aws_ami_from_instance.catalogue_ami ]
}


resource "aws_lb_target_group" "catalogue_tg" {
  name                 = "${var.project_name}-${var.common_tags.Component}-${var.env}-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = data.aws_ssm_parameter.vpc_id.value
  #deregistration_delay = 60

  health_check {
    enabled             = true
    healthy_threshold   = 2 # consider as healthy if 2 health checks are success
    interval            = 15  # Required amount of time bw healthcheck of individual target
    matcher             = "200-299"
    path                = "/health"
    port                = 8080
    protocol            = "HTTP"
    timeout             = 5  # Amount of time during which no reposnse from a target means failed health check
    unhealthy_threshold = 5 # consider unhealthy if 3 health check fails

  }
}

resource "aws_launch_template" "catalogue_lt" {
  name                                 = "${var.project_name}-${var.common_tags.Component}-${var.env}"
  image_id                             = aws_ami_from_instance.catalogue_ami.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t2.micro"
  vpc_security_group_ids               = [data.aws_ssm_parameter.catalogue_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "catalogue"
    }
  }

  # user_data = filebase64("${path.module}/catalogue.sh")
}

resource "aws_autoscaling_group" "catalogue_asg" {
  name                      = "${var.project_name}-${var.common_tags.Component}-${var.env}-asg-${local.current_time}"
  max_size                  = 4
  min_size                  = 1
  health_check_grace_period = 300 # Time after instance comes into service before checking health.
  health_check_type         = "ELB"
  desired_capacity          = 2
  target_group_arns         = [aws_lb_target_group.catalogue_tg.arn]

  launch_template {
    id      = aws_launch_template.catalogue_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  timeouts {
    delete = "15m"
  }

  #  lifecycle {
  #   create_before_destroy = true
  # }

  tag {
    key                 = "Name"
    value               = "Catalogue"
    propagate_at_launch = false
  }

}

resource "aws_autoscaling_policy" "catalogue_asg_policy" {
  autoscaling_group_name = aws_autoscaling_group.catalogue_asg.name
  name                   = "cpu"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }

}

resource "aws_lb_listener_rule" "catalogue_listner_rule" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue_tg.arn
  }

  # for dev instances, it should be app-dev, and for prod, it must be app-prod
  condition {
    host_header {
      values = ["${var.common_tags.Component}.app-${var.env}.${var.domain_name}"]
    }
  }

}


output "app_version" {
  value = var.app_version
}

