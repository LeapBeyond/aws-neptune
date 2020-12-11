# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
# neptune cluster
# --------------------------------------------------------------------------------
resource aws_security_group example {
  name        = var.vpc_name
  description = "Allow access to neptune from the VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow inbound access to neptune"
    from_port   = 8182
    to_port     = 8182
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "allow any-to-any outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" = var.vpc_name }, var.tags)
}

data aws_kms_key by_alias {
  key_id = "alias/aws/rds"
}

resource aws_neptune_subnet_group example {
  name_prefix = var.vpc_name
  description = "subnet group to mount neptune into"
  subnet_ids  = module.vpc.public_subnet_id
  tags        = merge({ "Name" = var.vpc_name }, var.tags)
}

resource aws_neptune_cluster example {
  cluster_identifier_prefix           = var.vpc_name
  backup_retention_period             = 1
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false
  apply_immediately                   = true
  deletion_protection                 = false
  neptune_subnet_group_name           = aws_neptune_subnet_group.example.id

  kms_key_arn       = data.aws_kms_key.by_alias.arn
  storage_encrypted = true

  iam_roles = [aws_iam_role.example.arn]

  tags = merge({ "Name" = var.vpc_name }, var.tags)

  vpc_security_group_ids = [
    aws_security_group.example.id
  ]
}

resource aws_neptune_cluster_instance example {
  count              = 2
  identifier_prefix  = var.vpc_name
  cluster_identifier = aws_neptune_cluster.example.id
  instance_class     = "db.t3.medium"
  apply_immediately  = true

  neptune_subnet_group_name = aws_neptune_cluster.example.neptune_subnet_group_name
  publicly_accessible       = false

  tags = merge({ "Name" = "${var.vpc_name}-${count.index}" }, var.tags)
}

# --------------------------------------------------------------------------------
# role to allow neptune to read from our bucket
# --------------------------------------------------------------------------------
resource aws_iam_role example {
  name               = var.vpc_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "rds.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge({ "Name" = var.vpc_name }, var.tags)
}

resource aws_iam_role_policy_attachment example {
  role       = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
