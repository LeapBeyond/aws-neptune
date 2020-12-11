# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
# create a VPC to contain everything
# --------------------------------------------------------------------------------
module vpc {
  source = "github.com/TheBellman/module-vpc"

  tags = var.tags

  vpc_cidr    = var.vpc_cidr
  vpc_name    = var.vpc_name
  ssh_inbound = var.ssh_inbound
}
