provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# data "cloudflare_zone" "dns_zone" {
#   filter = {
#     name = "vbasin.org"
#   }
# }
#
resource "cloudflare_dns_record" "dns_a" {
  # zone_id = data.cloudflare_zone.dns_zone.id
  zone_id = var.zone_id
  name    = var.server_name
  type    = "A"
  content = hcloud_server.server.ipv4_address
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "dns_aaaa" {
  # zone_id = data.cloudflare_zone.dns_zone.id
  zone_id = var.zone_id
  name    = var.server_name
  type    = "AAAA"
  content = hcloud_server.server.ipv6_address
  proxied = false
  ttl     = 3600
}
