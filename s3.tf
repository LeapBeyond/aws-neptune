# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------
# bucket for testing load into neptune
# ------------------------------------------------------------------------------------------------
# TODO rename this asset
resource aws_s3_bucket build {
  bucket_prefix = var.vpc_name
  acl           = "private"

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = merge({ "Name" = var.vpc_name }, var.tags)
}

# TODO rename this asset
resource aws_s3_bucket_public_access_block build {
  bucket = aws_s3_bucket.build.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource aws_s3_bucket_object example {
  for_each     = toset(["air-routes-latest-nodes.csv", "air-routes-latest-edges.csv"])
  bucket       = aws_s3_bucket.build.id
  key          = each.key
  source       = "data/${each.key}"
  content_type = "text/csv"
  etag         = filemd5("data/${each.key}")
}

# --------------------------------------------------------------------------------
# vpc endpoint that will allow neptune to read from S3
# --------------------------------------------------------------------------------
data aws_route_tables example {
  vpc_id = module.vpc.vpc_id
}

resource aws_vpc_endpoint s3 {
  vpc_id            = module.vpc.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  tags              = merge({ "Name" = var.vpc_name }, var.tags)

  route_table_ids = data.aws_route_tables.example.ids
}
