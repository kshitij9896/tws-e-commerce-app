terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.79.0"
    }
  }
}

locals {
  region = "ap-south-1"
}

provider "aws" {
  region = local.region
}