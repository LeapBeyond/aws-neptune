# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------

provider aws {
  version = ">= 3.20.0"
  region  = var.aws_region
  profile = var.aws_profile
}
