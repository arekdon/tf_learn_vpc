variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Type of the envirornment"
  type        = string
  default     = "DEV"
}