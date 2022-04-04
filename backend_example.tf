/* 
########################################
# An example of configuring your Terraform backend. 
# Copy/rename to backend.tf
# Update and uncomment this file
########################################
terraform {
  backend "s3" {
    bucket = "my-state-bucket"
    key    = "lakefs/terraform.tfstate"
    region = "eu-west-1"
  }
}
*/