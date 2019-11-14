variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Type of the envirornment"
  type        = string
  default     = "DEV"
}

variable "availability_zone_names" {
  description = "Type Avalibility Zone for subnets. Select one for specific subnet. i.e. ["us-east-1a","us-east-1b","us-east-1c"]"
  type    = list(string)
  default = ["us-east-1a"]
}