# provider.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
        }
    }
  }
  
provider "aws" {
  region = "eu-north-1" # Use your AWS region here
}
