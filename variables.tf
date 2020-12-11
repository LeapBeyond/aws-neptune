# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# variables to inject from terraform.tfvars or commandline
# --------------------------------------------------------------------------------
variable aws_region {
  type        = string
  description = "target region to deploy into"
  default     = "eu-west-2"
}

variable aws_account_id {
  type        = string
  description = "target account - this probably should not change"
  default     = "422515236307"
}

variable aws_profile {
  type        = string
  description = "role to access the account with"
  default     = "lba_role"
}

variable tags {
  type        = map(string)
  description = "base set of tags to apply to assets"
  default = {
    "Owner"   = "Leap Beyond"
    "Project" = "test"
    "Client"  = "internal"
  }
}

variable vpc_name {
  type        = string
  description = "base of names for the deployed VPC assets"
  default     = "neptune"
}

variable ssh_inbound {
  type        = list(string)
  description = "set of CIDR which are allowed SSH access in"
  default     = ["89.36.68.26/32", "18.202.216.48/29", "3.8.37.24/29", "35.180.112.80/29"]
}

variable vpc_cidr {
  type        = string
  description = "CIDR block used for the generated VPC"
  default     = "172.18.0.0/16"
}
