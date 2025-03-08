variable "hcloud_token" {
  sensitive = true
  type      = string
}

variable "cloudflare_api_token" {
  sensitive = true
  type      = string
}

variable "server_type" {
  type    = string
  default = "cx22"
}

variable "image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "datacenter" {
  type    = string
  default = "fsn1-dc14"
}

variable "zone_id" {
  type = string
}

variable "server_name" {
  type    = string
  default = "bitwarden"
}

variable "aws_region" {
  type = string
}

variable "backup_bucket_name" {
  type = string
}
