# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
# role to allow notebook access to S3
# --------------------------------------------------------------------------------
resource aws_iam_role notebook {
  name               = "${var.vpc_name}-notebook"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sagemaker.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge({ "Name" = "${var.vpc_name}-notebook" }, var.tags)
}

data aws_iam_policy_document notebook {
  statement {
    sid    = "accessS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::aws-neptune-notebook",
      "arn:aws:s3:::aws-neptune-notebook/*"
    ]
  }

  statement {
    sid    = "connect"
    effect = "Allow"
    actions = [
      "neptune-db:connect"
    ]
    resources = [
      aws_neptune_cluster.example.arn
    ]
  }
}

resource aws_iam_policy notebook {
  name   = "${var.vpc_name}-notebook"
  path   = "/"
  policy = data.aws_iam_policy_document.notebook.json
}

resource aws_iam_role_policy_attachment notebook {
  role       = aws_iam_role.notebook.name
  policy_arn = aws_iam_policy.notebook.arn
}

# --------------------------------------------------------------------------------
# note book instance
# --------------------------------------------------------------------------------
data template_file onstart {
  template = file("${path.root}/provisioning/notebook.tmpl")
  vars = {
    neptune_url  = aws_neptune_cluster.example.endpoint
    neptune_port = 8182
    role_arn     = aws_iam_role.example.arn
    aws_region   = var.aws_region
  }
}

resource aws_sagemaker_notebook_instance_lifecycle_configuration notebook {
  name      = "${var.vpc_name}-notebook"
  on_start  = base64encode(data.template_file.onstart.rendered)
}

resource aws_sagemaker_notebook_instance notebook {
  name                   = "${var.vpc_name}-notebook"
  role_arn               = aws_iam_role.notebook.arn
  instance_type          = "ml.t3.medium"
  direct_internet_access = "Enabled"
  root_access            = "Disabled"
  lifecycle_config_name  = aws_sagemaker_notebook_instance_lifecycle_configuration.notebook.name
  volume_size            = 5

  security_groups = [
    aws_security_group.example.id
  ]

  subnet_id = module.vpc.public_subnet_id[0]

  tags = merge({ "Name" = "${var.vpc_name}-notebook", "aws-neptune-cluster-id" = aws_neptune_cluster.example.id, "aws-neptune-resource-id" = aws_neptune_cluster.example.cluster_resource_id }, var.tags)
}
