variable "project_name" {
  default = "roboshop"
}

variable "common_tags" {
  default = {
    Project     = "Roboshop"
    Component = "catalogue"
    Environment = "DEV"
    Terraform   = true
  }
}

variable "env" {
  default = "dev"
}

variable "domain_name" {
  default = "bsebregistration.com"
}


variable "app_version" {
  default = "100.100.100.101"
}



