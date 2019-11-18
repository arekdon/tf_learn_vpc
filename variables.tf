variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "172.32.0.0/24"
}

variable "environment" {
  description = "Type of the envirornment"
  type        = string
  default     = "DEV"
}

variable "availability_zone_names" {
  description = "Type Avalibility Zone for subnets. Select one for specific subnet. i.e. [us-east-1a,us-east-1b,us-east-1c]"
  type    = list(string)
  default = ["us-east-1a"]
}

variable "private_subnets_cidr_block" {
  description = "Type CIDR blocks for private subnets."
  type        = list(string)
}

variable "public_subnets_cidr_block" {
  description = "Type CIDR blocks for public subnets."
  type        = list(string)
}