
# TODO for now using the same policy for lakefs_server role, lakefs_glue role, and iam user.

resource "aws_iam_policy" "lakefs" {
  name = "${var.naming_prefix}-lakefs-demo"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.lakefs.arn,
          "${aws_s3_bucket.lakefs.arn}/*"
        ]
      },
      {
        Action = [
          "s3:List*",
          "s3:Get*"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.hadoop_lakefs_assembly_jar_bucket}",
          "arn:aws:s3:::${var.hadoop_lakefs_assembly_jar_bucket}/${var.hadoop_lakefs_assembly_jar_object_key}"
        ]
      },
      {
        # TODO cut these back a bit
        Action   = "glue:*"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:lakefs-??????"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:/aws-glue/*"
      }
    ]
  })
}

###########################################
## IAM user
###########################################

/*
data "aws_iam_user" "lakefs" {
  user_name = var.lakefs_iam_user
}

resource "aws_iam_user_policy_attachment" "lakefs" {
  user       = var.lakefs_iam_user
  policy_arn = aws_iam_policy.lakefs.arn
}*/

###########################################
## Glue role
###########################################

resource "aws_iam_role" "lakefs_glue" {
  name = "${var.naming_prefix}-lakefs-demo-glue"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.naming_prefix}-lakefs-demo-glue"
  }
}

resource "aws_iam_role_policy_attachment" "lakefs_glue" {
  role       = aws_iam_role.lakefs_glue.name
  policy_arn = aws_iam_policy.lakefs.arn
}

###########################################
## Server role
###########################################

resource "aws_iam_role" "lakefs_server" {
  name = "${var.naming_prefix}-lakefs-demo-server"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.naming_prefix}-lakefs-demo-server"
  }
}

resource "aws_iam_role_policy_attachment" "lakefs_server" {
  role       = aws_iam_role.lakefs_server.name
  policy_arn = aws_iam_policy.lakefs.arn
}

resource "aws_iam_instance_profile" "lakefs_server" {
  name = "${var.naming_prefix}-lakefs-demo-server"
  role = aws_iam_role.lakefs_server.name
}
