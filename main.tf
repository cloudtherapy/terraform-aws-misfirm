terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = var.mis_access_key
  secret_key = var.mis_secret_key
}

resource "aws_s3_bucket" "mis-test" {
  bucket = "misfirm-test-bucket"

  tags = {
    Environment = "Production"
    Name        = "MISBucketName"
  }
}

resource "aws_s3_bucket" "mis-test2" {
  bucket = "misfirm-test-bucket2"

  tags = {
    Environment = "Production"
  }
}
