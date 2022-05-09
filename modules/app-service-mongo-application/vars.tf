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
variable "min_size" {
  type    = number
  default = 1
}
variable "max_size" {
  type    = number
  default = 3
}
variable "cpu_less_threshold" {
  type    = number
  default = 20
}
variable "cpu_greater_threshold" {
  type    = number
  default = 80
}
variable "environment_variables" {
  type        = map(string)
  description = "Environment Variables"
}
variable "apim_ip_addresses" {
  type        = list(string)
  description = "The Ip Addresses of the APIM."
}