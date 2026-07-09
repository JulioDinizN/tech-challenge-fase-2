terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "8.21.0"
    }
  }
}

provider "oci" {
  region              = var.region
  config_file_profile = var.oci_config_profile
  auth                = var.oci_auth
}
