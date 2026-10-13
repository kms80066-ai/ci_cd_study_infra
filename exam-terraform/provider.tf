terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Owner   = local.owner
      Project = "terraform-exam"
      Managed = "Terraform"
    }
  }
}

