terraform {
  required_version = ">= 0.14.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 4.41"
      ## https://github.com/hashicorp/terraform-provider-aws/issues/31633
    }
  }
}
