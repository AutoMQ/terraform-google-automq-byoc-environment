provider "google" {
  project = var.cloud_project_id
  region  = var.cloud_provider_region
}

locals {
  automq_byoc_vpc_name                       = var.create_new_vpc ? module.automq_byoc_vpc[0].network_name : var.existing_vpc_name
  automq_byoc_env_console_public_subnet_name = var.create_new_vpc ? module.automq_byoc_vpc[0].subnets_names[0] : var.existing_subnet_name
  automq_data_bucket                         = var.automq_byoc_data_bucket_name == "" ? module.automq_byoc_data_bucket[0].name : var.automq_byoc_data_bucket_name
  automq_ops_bucket                          = var.automq_byoc_ops_bucket_name == "" ? module.automq_byoc_ops_bucket[0].name : var.automq_byoc_ops_bucket_name
}

# GCS bucket instead of S3
module "automq_byoc_data_bucket" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 3.4"

  count = var.automq_byoc_data_bucket_name == "" ? 1 : 0

  prefix     = ""
  names      = ["automq-data-${var.automq_byoc_env_id}"]
  project_id = var.cloud_project_id

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = var.automq_byoc_env_id
  }
}

# GCS ops bucket
module "automq_byoc_ops_bucket" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 3.4"

  count = var.automq_byoc_ops_bucket_name == "" ? 1 : 0

  prefix     = ""
  names      = ["automq-ops-${var.automq_byoc_env_id}"]
  project_id = var.cloud_project_id

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = var.automq_byoc_env_id
  }
}

# VPC Network
module "automq_byoc_vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 7.0"

  count        = var.create_new_vpc ? 1 : 0
  project_id   = var.cloud_project_id
  network_name = lower(replace("automq_byoc_vpc_${var.automq_byoc_env_id}", "_", "-"))

  subnets = [
    {
      subnet_name           = "public-subnet"
      subnet_ip             = "10.0.0.0/20"
      subnet_region         = var.cloud_provider_region
      subnet_private_access = true
    },
    {
      subnet_name           = "private-subnet-1"
      subnet_ip             = "10.0.128.0/20"
      subnet_region         = var.cloud_provider_region
      subnet_private_access = true
    },
    {
      subnet_name           = "private-subnet-2"
      subnet_ip             = "10.0.144.0/20"
      subnet_region         = var.cloud_provider_region
      subnet_private_access = true
    }
  ]
}

# Service Account
resource "google_service_account" "automq_byoc_sa" {
  account_id   = "automq-byoc-sa-${var.automq_byoc_env_id}"
  display_name = "AutoMQ BYOC Service Account"
  project      = var.cloud_project_id
}

resource "google_project_iam_custom_role" "automq_byoc_role" {
  role_id     = replace("automq_byoc_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC Service Account Role"
  description = "AutoMQ BYOC Service Account Role"
  permissions = [
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.setRetention",
    "storage.objects.update",
    "container.apiServices.create",
    "container.apiServices.delete",
    "container.apiServices.get",
    "container.apiServices.getStatus",
    "container.apiServices.list",
    "container.apiServices.update",
    "container.apiServices.updateStatus",
    "container.auditSinks.create",
    "container.auditSinks.delete",
    "container.auditSinks.get",
    "container.clusters.connect",
    "container.clusters.create",
    "container.clusters.createTagBinding",
    "container.clusters.delete",
    "container.clusters.deleteTagBinding",
    "container.clusters.get",
    "container.clusters.getCredentials",
    "container.clusters.list",
    "container.clusters.listEffectiveTags",
    "container.clusters.listTagBindings",
    "container.clusters.update",
    "container.configMaps.create",
    "container.configMaps.delete",
    "container.configMaps.get",
    "container.configMaps.list",
    "container.configMaps.update",
    "container.namespaces.create",
    "container.namespaces.delete",
    "container.namespaces.finalize",
    "container.namespaces.get",
    "container.namespaces.getStatus",
    "container.namespaces.list",
    "container.namespaces.update",
    "container.namespaces.updateStatus",
    "container.pods.attach",
    "container.pods.create",
    "container.pods.delete",
    "container.pods.evict",
    "container.pods.exec",
    "container.pods.get",
    "container.pods.getLogs",
    "container.pods.getStatus",
    "container.pods.list",
    "container.pods.portForward",
    "container.pods.proxy",
    "container.pods.update",
    "container.pods.updateStatus",
    "container.secrets.create",
    "container.secrets.delete",
    "container.secrets.get",
    "container.secrets.list",
    "container.secrets.update",
    "container.services.create",
    "container.services.delete",
    "container.services.get",
    "container.services.getStatus",
    "container.services.list",
    "container.services.proxy",
    "container.services.update",
    "container.services.updateStatus",
    "container.statefulSets.create",
    "container.statefulSets.delete",
    "container.statefulSets.get",
    "container.statefulSets.getScale",
    "container.statefulSets.getStatus",
    "container.statefulSets.list",
    "container.statefulSets.update",
    "container.statefulSets.updateScale",
    "container.statefulSets.updateStatus"
  ]
}

resource "google_project_iam_binding" "automq_byoc_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

# Firewall rules
resource "google_compute_firewall" "automq_byoc_console_sg" {
  name    = "automq-byoc-console-${var.automq_byoc_env_id}"
  network = var.create_new_vpc ? module.automq_byoc_vpc[0].network_name : var.existing_vpc_name
  project = var.cloud_project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  source_ranges = [var.automq_byoc_env_console_cidr]
}

# Static IP
resource "google_compute_address" "web_ip" {
  name    = lower(replace("automq_web_ip_${var.automq_byoc_env_id}", "_", "-"))
  project = var.cloud_project_id
  region  = var.cloud_provider_region
}

data "google_compute_image" "console_image" {
  name = "automq-control-center-test-0-0-1-snapshot-20241105-05-23-x86-64"
}

data "google_compute_network" "vpc" {
  name = local.automq_byoc_vpc_name
}

resource "google_dns_managed_zone" "private_dns_zone" {
  name     = "automq-byoc-private-zone-${var.automq_byoc_env_id}"
  dns_name = "${var.automq_byoc_env_id}.automq.private."

  private_visibility_config {
    networks {
      network_url = var.create_new_vpc ? module.automq_byoc_vpc[0].network_name : data.google_compute_network.vpc.self_link
    }
  }

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = var.automq_byoc_env_id
  }

  lifecycle {
    create_before_destroy = true
  }
}
