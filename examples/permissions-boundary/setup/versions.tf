terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
      ## https://github.com/hashicorp/terraform-provider-aws/issues/31633
    }
  }
  required_version = ">= 1"
}
