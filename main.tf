terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider for TF
provider "aws" {
  region     = "us-east-1"
  access_key = var.mis_access_key
  secret_key = var.mis_secret_key
}

#Create the CETech ansible key pair in new account if it doesn't exist
module "ansible_key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0.3"

  key_name   = "ansible"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCTD8HrwW7d5xvgs0o0dXkyNFdgZwab4G9Ok2Irh7uuk0OOW/U9QyePpfHzDboSsyfSGjwG3qzn6zKncq1vg2YmaR2oOm555T5D3/faGdJ1UJbx5hqiogkfw4hXMreg/u9Ah9CuucDUKwRxQC/MhpVrGb1MAEuDd5ZKPT6QF99ssgno/ibrHdraENMsZu+FxmJZ/Ukmi6ik8eJYRlSvAEZXw2hQIEcEaYejWMnNmE06ys5xjQe30pmV2a/Wxg4NN2MrDFzCssSDARAMak5v0vGkLGTsJYx56NaKLqnOudkKnPkXK/AvvEB26L1F1kaZLyR0jrzjTuKKEuqUJReKf/MV"
}



#Create a base VPC for MISFirm Account (255820308257)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "mis-prod-vpc"
  cidr = "10.33.0.0/20"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.33.0.0/24", "10.33.2.0/24"]
  public_subnets  = ["10.33.1.0/24", "10.33.3.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "Prod"
  }

  enable_vpn_gateway                 = true
  propagate_private_route_tables_vgw = true

  customer_gateways = {
    tierpoint = {
      bgp_asn    = 65534
      ip_address = "66.203.72.213"
    }
  }
}

#Enable and create a VPN gate with 2 Tunnels for usage with Fortinet VPN configuration
module "vpn_gateway" {
  source  = "terraform-aws-modules/vpn-gateway/aws"
  version = "~> 3.7"

  vpc_id              = module.vpc.vpc_id
  vpn_gateway_id      = module.vpc.vgw_id
  customer_gateway_id = module.vpc.cgw_ids[0]

  vpc_subnet_route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Terraform   = "true"
    Environment = "Prod"
    Name        = "misfirm-tierpoint-vpn"
  }
}

#Outputs for Fortinet VPN Configuration

output "vpn_tunnel1_psk" {
  value     = nonsensitive(module.vpn_gateway.tunnel1_preshared_key)
  sensitive = true
}

output "tunnel1_address" {
  value = module.vpn_gateway.vpn_connection_tunnel1_address
}

#Create default security group for MIS Firm that can be used to tie back to the lab
module "default_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.1"

  use_name_prefix = false
  name            = "Allow-all-from-Tierpoint"
  description     = "Security group for all traffic open within VPC and TierPoint lab"
  vpc_id          = module.vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "TierPoint lab network"
      cidr_blocks = "10.227.0.0/16"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "Norwood lab network"
      cidr_blocks = "10.220.0.0/20"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "Azure MPN network"
      cidr_blocks = "10.253.0.0/20"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "AWS cetech-shared network"
      cidr_blocks = "10.254.0.0/20"
    }
  ]
}














###########################################################################################################################

#Use the aws_ami data source to get the ID of the Ubuntu public image
#data "aws_ami" "ubuntu" {
#  most_recent = true
#
#  filter {
#    name   = "name"
#    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#  }
#
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }                               
#
#  owners = ["099720109477"] # Canonical
#}

#output "ami_arn" {
#  value = data.aws_ami.ubuntu.arn
#}

###########################################################################################################################

#Query the aws_subnet ID based upon the vpc_id in MIS account to then use as an input to creating an EC2 resource below
#data "aws_subnet" "misvpc_subnet" {
#  vpc_id = "vpc-5b9dd923"
#}


#Create EC2 instance with aws_ami datasource ID
#resource "aws_instance" "misec2" {
#  ami           = data.aws_ami.ubuntu.id
#  instance_type = "t3.micro"
#
#  tags = {
#    Name = "HelloWorld"
#  }
#  
#  key_name = data.aws_key_pair.ansible.key_name
#  subnet_id     = data.aws_subnet.misvpc_subnet.id
#}

#Use aws_key_pair data source to get the key pair info for ansible to be used in EC2 instance creation
#data "aws_key_pair" "ansible" {
#  key_name           = "ansible"
#  include_public_key = true
#}

#output "fingerprint" {
#  value = data.aws_key_pair.ansible.fingerprint
#}

#output "name" {
#  value = data.aws_key_pair.ansible.key_name
#}

#output "id" {
#  value = data.aws_key_pair.ansible.id
#}

###########################################################################################################################

# Create S3 bucket with the s3-bucket aws module 
#module "mis-test-bucket1" {
#  source  = "terraform-aws-modules/s3-bucket/aws"
#  version = "4.1.0"
#  bucket  = "mis-test-bucket1"
#  tags = {
#   "Environment" = "Production"
#   "Owner"       = "MIS"
#  }
#} 

#Importing s3 bucket with the s3-bucket module. Bucket was created manually and imported into the s3-bucket module
#module "mis-test-bucket3" {
#  source  = "terraform-aws-modules/s3-bucket/aws"
#  version = "4.1.0"
#  bucket  = "mis-test-bucket3"
#} 


#Importing s3 bucket as a Terraform resource. Bucket was created manually and imported as a resource
#resource "aws_s3_bucket" "mis-test-bucket2" {
#  bucket = "mis-test-bucket2"
#}

