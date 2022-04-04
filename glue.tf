resource "aws_glue_job" "lakefs" {
  for_each = fileset("${path.module}/scripts/glue_jobs", "*.py")
  name     = "${var.naming_prefix}-lakefs-${each.key}"
  role_arn = aws_iam_role.lakefs_glue.arn

  glue_version = "2.0"
  # Spark 2.4.3, Python 3.7

  number_of_workers = 2 # TODO https://github.com/hashicorp/terraform-provider-aws/issues/23372
  worker_type       = "Standard"

  timeout = 5

  command {
    # Select a script to run from the list in s3.tf
    script_location = "s3://${aws_s3_bucket.lakefs.bucket}/scripts/glue_jobs/${each.key}"
  }

  default_arguments = {
    "--enable-glue-datacatalog" = ""

    # Common uitilities used by all jobs
    "--extra-files" = "s3://${aws_s3_bucket.lakefs.bucket}/scripts/utils.zip"

    # Only used when writing directly to S3 using the LakeFS filesystem format
    # Istead of the S3 gateway running on the LakeFS server
    "--extra-jars" = "s3://${var.hadoop_lakefs_assembly_jar_bucket}/${var.hadoop_lakefs_assembly_jar_object_key}"

    # Only used when creating branches & committing stuff
    # See https://github.com/treeverse/lakeFS/tree/master/clients/python
    "--additional-python-modules" = "lakefs-client"

    "--lakefs-s3-bucket"   = aws_s3_bucket.lakefs.id
    "--lakefs-repo-name"   = var.lakefs_repo_name
    "--lakefs-branch-name" = var.lakefs_branch_name

    "--lakefs-catalog-db-name" = "lakefs_db"

    "--lakefs-url"          = "http://${aws_instance.server.public_ip}:8000"
    "--lakefs-api-endpoint" = "http://${aws_instance.server.public_ip}:8000/api/v1"

    "--s3-region-endpoint" = var.s3_region_endpoint
    "--region"             = var.region
  }

  tags = {
    Name = "${var.naming_prefix}-lakefs-${each.key}"
  }
}
