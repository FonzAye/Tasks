variable "vpcs" {}

variable "region" {}

variable "create_nat_gateway" {
  description = "Weather to create nat gateway"
  type = bool
  default = false
}