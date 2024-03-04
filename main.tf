terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "mis-test-bucket1" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"
  bucket  = "mis-test-bucket1"
  tags = {
    "Environment" = "Prod"
    "Owner"       = "Carlos"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true

      apply_server_side_encryption_by_default = {
        kms_master_key_id = "arn:aws:kms:us-east-1:255820308257:alias/aws/s3"
        sse_algorithm     = "aws:kms"
      }
    }
  }
} 

module "mis-test-bucket2" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"
  bucket  = "mis-test-bucket2"
  tags = {
    "Environment" = "Dev"
    "Owner"       = "Keith"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true

      apply_server_side_encryption_by_default = {
        kms_master_key_id = "arn:aws:kms:us-east-1:255820308257:alias/aws/s3"
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

#Importing s3 bucket
#resource "aws_s3_bucket" "mis-bucket2" {
#  bucket = "mis-test-bucket2"
#}

#module "vpc" {
#  source  = "terraform-aws-modules/vpc/aws"
#  version = "5.5.2"
#
#}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = var.mis_access_key
  secret_key = var.mis_secret_key
}
