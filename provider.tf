terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }

  }
}

provider "aws" {
  region = var.region
}
provider "local" {}
