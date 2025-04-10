variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit access"
  type        = string
}

variable "zone_name" {
  default = ""
}

variable "subdomain_name" {
  default = ""
}

variable "ip_address" {
  default = ""
}