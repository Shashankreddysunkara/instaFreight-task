terraform {
  backend "s3" {
    bucket         = "instafreight-ops-state"
    key            = "stage/terraform.tfstate"
    region         = "us-west-1"
  }
}

provider "aws" {
  region = "us-west-1"

}