variable "aws_region" {
	default = "us-west-1"
}

variable "vpc_cidr" {
	default = "10.0.0.0/16"
}

variable "subnets_cidr_public" {
	type = list
	default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "subnets_cidr_private" {
  type = list
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "azs" {
	type = list
	default = ["us-west-1a", "us-west-1c"]
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ingress_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [22, 443, 8080, 5000, 2375, 80, 9200, 5601]
}

variable "ops_remote_state_bucket" {
  description = "The name of the S3 bucket for the webserver remote state"
  default = "instafreight-ops-state"
  type        = string
}

variable "ops_remote_state_key" {
  description = "The path for the webserver remote state in S3"
  default = "stage/terraform.tfstate"
  type        = string
}

variable "consul_version" {
  description = "The version of Consul to install (server and client)."
  default     = "1.7.1"
}
