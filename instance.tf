# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Data lookups
# --------------------------------------------------------------------------------
data aws_ami lab {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20200917.0-x86_64-gp2"]
  }
}

# --------------------------------------------------------------------------------
# instance(s)
# --------------------------------------------------------------------------------
data template_file bootstrap {
  template = file("provisioning/bootstrap.tmpl")
  vars = {
    neptune_url  = aws_neptune_cluster.example.endpoint
    neptune_port = 8182
  }
}

data template_cloudinit_config main {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.bootstrap.rendered
  }
}

resource aws_instance lab {
  ami           = data.aws_ami.lab.id
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnet_id[1]

  vpc_security_group_ids = [aws_security_group.lab.id]

  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile = aws_iam_instance_profile.ssm.name
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags        = merge({ "Name" = var.vpc_name }, var.tags)
  volume_tags = merge({ "Name" = var.vpc_name }, var.tags)

  user_data = data.template_cloudinit_config.main.rendered
}

# --------------------------------------------------------------------------------
# IP for the instance(s)
# --------------------------------------------------------------------------------
resource aws_eip lab {
  vpc      = true
  instance = aws_instance.lab.id
  tags     = merge({ "Name" = var.vpc_name }, var.tags)
}

# --------------------------------------------------------------------------------
#  security groups for use on ec2 instances
# --------------------------------------------------------------------------------
resource aws_security_group lab {
  name        = "${var.vpc_name}-lab"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for instances in terraform subnets"
  tags        = merge({ "Name" = "${var.vpc_name} instance" }, var.tags)
}

resource aws_security_group_rule lab_ssh_in {
  security_group_id = aws_security_group.lab.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_inbound
}

resource aws_security_group_rule lab_http_out {
  security_group_id = aws_security_group.lab.id
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource aws_security_group_rule lab_https_out {
  security_group_id = aws_security_group.lab.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource aws_security_group_rule lab_neptune_out {
  security_group_id = aws_security_group.lab.id
  type              = "egress"
  from_port         = 8182
  to_port           = 8182
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

# --------------------------------------------------------------------------------
# SSM Role for the instance
# --------------------------------------------------------------------------------
resource aws_iam_role ssm {
  name        = "${var.vpc_name}-ssm"
  description = "Role to be assumed by instances to allow access via SSM"
  tags        = merge({ "Name" = var.vpc_name }, var.tags)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource aws_iam_role_policy_attachment ssm {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource aws_iam_role_policy_attachment s3 {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource aws_iam_instance_profile ssm {
  name = "${var.vpc_name}-lab"
  role = aws_iam_role.ssm.name
}
