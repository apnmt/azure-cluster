variable "location" {
  default     = "germanywestcentral"
  description = "Azure Location"
}

variable "client-id" {
  default     = "72dddf73-cc68-41af-b688-e7890045e72d"
  description = "Azure AD B2C Application Client Id"
}

variable "open-id-url" {
  default     = "https://apntmb2c.b2clogin.com/apntmb2c.onmicrosoft.com/v2.0/.well-known/openid-configuration?p=B2C_1_signupsignin"
  description = "Azure APIM Open Id Url"
}

variable "issuer" {
  default     = "https://apntmb2c.b2clogin.com/d8e1390b-3103-4104-8237-628e88e6f47e/v2.0/"
  description = "Azure APIM Issuer"
}