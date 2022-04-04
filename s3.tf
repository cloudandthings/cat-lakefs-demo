resource "aws_s3_bucket" "lakefs" {
  bucket        = var.lakefs_s3_bucket
  force_destroy = true
  tags = {
    Name = "lakefs-bucket"
  }
}

resource "aws_s3_bucket_object" "scripts" {
  for_each = fileset("${path.module}", "scripts/glue_jobs/*.py")
  # Use the reference provider, default provder
  # has more than 10 tags
  provider = aws.reference

  bucket = aws_s3_bucket.lakefs.bucket
  key    = each.key
  source = "${path.module}/${each.key}"
  etag   = filemd5("${path.module}/${each.key}")
}

data "archive_file" "utils" {
  type        = "zip"
  source_dir  = "${path.module}/scripts/glue_jobs/utils"
  output_path = "${path.module}/scripts/utils.zip"
}

resource "aws_s3_bucket_object" "utils" {
  for_each = fileset("${path.module}", "/scripts/utils.zip")
  # Use the reference provider, default provder
  # has more than 10 tags
  provider = aws.reference

  bucket = aws_s3_bucket.lakefs.bucket
  key    = each.key
  source = "${path.module}/${each.key}"
  etag   = filemd5("${path.module}/${each.key}")
}