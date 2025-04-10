output "dns_record" {
  value = cloudflare_record.subdomain_a.hostname
}

