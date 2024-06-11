locals {
  private_subnet_id = element(split(",", data.aws_ssm_parameter.private_subnet_ids.value), 0)
}

locals {
  current_time = formatdate("YYYY-MM-DD-hh:mm:ss", timestamp())
}