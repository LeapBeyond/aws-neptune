# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "lbagroup20191214122212241800000001"
    key            = "aws-neptune"
    region         = "eu-west-2"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:538526694679:key/dd0c2139-bc2a-43db-9f22-b94a033c7766"
    dynamodb_table = "terraform-state-lock"
    profile        = "lba_group"
  }
}
