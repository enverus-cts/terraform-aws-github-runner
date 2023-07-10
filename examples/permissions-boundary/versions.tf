terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 4.41"
      ## https://github.com/hashicorp/terraform-provider-aws/issues/31633
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 1"
}
