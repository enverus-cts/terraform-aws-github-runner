terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
      ## https://github.com/hashicorp/terraform-provider-aws/issues/31633
    }
  }
}
