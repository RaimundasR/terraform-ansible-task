terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0" # or the latest you want to use
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}


data "cloudflare_zone" "zone" {
  name = var.zone_name
}

resource "cloudflare_record" "subdomain_a" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "${var.subdomain_name}.${var.zone_name}"
  type    = "A"
  content   = var.ip_address
  ttl     = 1              # Auto TTL
  proxied = true          # Set to true if you want Cloudflare proxying
}
