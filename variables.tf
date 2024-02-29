# AWS Network Infrastructure
#variable "aws_profile" {
#  description = "AWS profile for cluster deployment"
#  type        = string
#}

variable "mis_access_key" {
  description = "AWS access key for the MIS AWS account"
  type        = string
}

variable "mis_secret_key" {
  description = "AWS secret key for the MIS AWS account"
  type        = string
}