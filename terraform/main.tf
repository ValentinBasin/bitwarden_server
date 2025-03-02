terraform {
  backend "s3" {
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
      version = "~> 5.1"
    }
  }
}
