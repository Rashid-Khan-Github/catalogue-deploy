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
      Name = "${var.common_tags.Component}-${var.env}-AMI"
    },
    var.common_tags
  )
}


resource "null_resource" "null_res" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.catalogue_instance.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    type = "ssh"
    user = "centos"
    password = "DevOps321"
    host = module.catalogue_instance.private_ip
  }

  # copy the file
  provisioner "file" {
    source = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
        "chmod +x /tmp/catalogue.sh",
        "sudo sh /tmp.catalogue.sh ${var.app_version}"
    ]
  }
}

output "app_version" {
  value = var.app_version
}

