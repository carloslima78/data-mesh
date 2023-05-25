
variable "aws_region" {
  type        = string
  description = ""
  default     = "us-east-1"
}

variable "aws_account_id" {
  type        = number
  description = ""
  default     = 303315406913
}

variable "service_name" {
  type        = string
  description = ""
  default     = "pedidos"
}

variable "service_domain" {
  type        = string
  description = ""
  default     = "api-gateway-pedidos"
}