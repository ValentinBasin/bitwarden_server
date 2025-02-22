terraform {
  backend "s3" {
    bucket       = "my-blog-terraform-state-7f2a377158c"
    key          = "bw-terraform-state/terraform.tfstate"
    region       = "il-central-1"
    encrypt      = true
    use_lockfile = true
  }
  required_version = "~> 1.2"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "hcloud_primary_ip" "ipv4" {
  name          = "primary_ipv4"
  datacenter    = var.datacenter
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false
}

resource "hcloud_primary_ip" "ipv6" {
  name          = "primary_ipv6"
  datacenter    = var.datacenter
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false
}

resource "hcloud_ssh_key" "github_actions" {
  name       = "github-actions"
  public_key = file("./ssh_keys/github-actions.pub")
}

resource "hcloud_server" "server" {
  name        = var.server_name
  image       = var.image
  server_type = var.server_type
  datacenter  = var.datacenter
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.ipv4.id
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.ipv6.id
  }
  ssh_keys = [hcloud_ssh_key.github_actions.id]
}

resource "cloudflare_dns_record" "dns_a" {
  zone_id = var.zone_id
  name    = var.server_name
  type    = "A"
  content = hcloud_server.server.ipv4_address
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "dns_aaaa" {
  zone_id = var.zone_id
  name    = var.server_name
  type    = "AAAA"
  content = hcloud_server.server.ipv6_address
  proxied = false
  ttl     = 3600
}
