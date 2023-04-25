terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "4.117.0"
    }
  }
}

provider "oci" {
  region       = var.region
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
}

variable tenancy_ocid {}
variable user_ocid {}
variable fingerprint {}
variable private_key {}
variable compartment_ocid {}
variable region {}
