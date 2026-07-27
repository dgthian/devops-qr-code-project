terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
      source  = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
