terraform {
  required_version = ">= 0.12"
  required_providers {
	aws = {
		source = "hashicorp/aws"
		version = "~> 3.74"
	}
  }
}

provider "aws" {
	region = "${var.aws_region}"
}