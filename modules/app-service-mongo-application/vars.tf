variable "location" {
  type        = string
  description = "Azure location"
}
variable "resource_group" {
  type        = string
  description = "Azure resource group"
}
variable "application_name" {
  type = string
}
variable "tier" {
  type    = string
  default = "Basic"
}
variable "tier_size" {
  type        = string
  default     = "B1"
  description = "AppService tier size"
}
variable "max_size" {
  type    = number
  default = 2
}