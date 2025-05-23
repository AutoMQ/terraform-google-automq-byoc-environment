provider "google" {
  project = var.cloud_project_id
  region  = var.cloud_provider_region
}

locals {
  automq_byoc_vpc_name                       = var.create_new_vpc ? google_compute_network.automq_network[0].name : var.existing_vpc_name
  automq_byoc_env_console_public_subnet_name = var.create_new_vpc ? google_compute_subnetwork.automq_subnetwork[0].name : var.existing_subnet_name
  automq_ops_bucket                          = var.automq_byoc_ops_bucket_name == "" ? google_storage_bucket.automq_byoc_ops_bucket[0].name : var.automq_byoc_ops_bucket_name

  automq_vendor_tag_key   = "automqVendor"
  automq_vendor_tag_value = "automq"

  automq_env_tag_key   = "automqEnvironmentId"
  automq_env_tag_value = var.automq_byoc_env_id
}

data "google_project" "project" {
  project_id = var.cloud_project_id
}

resource "random_id" "deployment_id" {
  keepers = {
    # Generate a new id each time we switch to a new deployment name
    deployment_name = var.automq_byoc_env_id
  }
  byte_length = 8
}

resource "google_tags_tag_key" "automqVendorKey" {
  parent     = "projects/${var.cloud_project_id}"
  short_name = "${local.automq_vendor_tag_key}-${random_id.deployment_id.hex}"
}

resource "google_tags_tag_value" "automqVendorValue" {
  parent     = "tagKeys/${google_tags_tag_key.automqVendorKey.name}"
  short_name = local.automq_vendor_tag_value
}

resource "google_tags_tag_key" "automqEnvKey" {
  parent     = "projects/${var.cloud_project_id}"
  short_name = "${local.automq_env_tag_key}-${random_id.deployment_id.hex}"
}

resource "google_tags_tag_value" "automqEnvValue" {
  parent     = "tagKeys/${google_tags_tag_key.automqEnvKey.name}"
  short_name = local.automq_env_tag_value
}


resource "google_storage_bucket" "automq_byoc_ops_bucket" {
  count = var.automq_byoc_ops_bucket_name == "" ? 1 : 0

  name          = "automq-ops-${var.automq_byoc_env_id}"
  location      = var.cloud_provider_region
  force_destroy = true

  uniform_bucket_level_access = true

  soft_delete_policy {
    retention_duration_seconds = 0
  }

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = var.automq_byoc_env_id
  }
}

data "google_storage_bucket" "ops_bucket" {
  depends_on = [google_storage_bucket.automq_byoc_ops_bucket]
  name       = local.automq_ops_bucket
}

# VPC Network
resource "google_compute_network" "automq_network" {
  count = var.create_new_vpc ? 1 : 0

  name    = lower(replace("automq_byoc_vpc_${var.automq_byoc_env_id}", "_", "-"))
  project = var.cloud_project_id

  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "automq_subnetwork" {
  count = var.create_new_vpc ? 1 : 0

  name = "console-subnet-${var.automq_byoc_env_id}"

  ip_cidr_range = "10.0.0.0/20"
  region        = var.cloud_provider_region

  stack_type = "IPV4_ONLY"

  network = google_compute_network.automq_network[0].id
}

resource "google_compute_subnetwork" "gke_subnetwork" {
  count = var.create_new_vpc ? 1 : 0

  name = "gke-subnet-${var.automq_byoc_env_id}"

  ip_cidr_range = "10.1.0.0/20"
  region        = var.cloud_provider_region

  stack_type = "IPV4_ONLY"

  network = google_compute_network.automq_network[0].id
}

# Service Account
resource "google_service_account" "automq_byoc_sa" {
  account_id   = "automq-byoc-sa-${var.automq_byoc_env_id}"
  display_name = "AutoMQ BYOC ${var.automq_byoc_env_id} Service Account"
  project      = var.cloud_project_id
}

resource "google_project_iam_custom_role" "automq_byoc_storage_role" {
  role_id     = replace("automq_byoc_storage_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} Storage Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} Storage Role"
  permissions = [
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.setRetention",
    "storage.objects.update",
    "storage.multipartUploads.create",
  ]
}

resource "google_project_iam_custom_role" "automq_byoc_compute_role" {
  role_id     = replace("automq_byoc_compute_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} Compute Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} Compute Role"
  permissions = [
    "compute.instances.get",
    "compute.disks.get",
    "compute.instances.list",
    "compute.networks.get",
    "compute.networks.list",
    "compute.subnetworks.get"
  ]
}

resource "google_project_iam_custom_role" "automq_byoc_dns_role" {
  role_id     = replace("automq_byoc_dns_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} DNS Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} DNS Role"
  permissions = [
    "dns.changes.create",
    "dns.managedZones.get",
    "dns.resourceRecordSets.create",
    "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.update",
  ]
}

resource "google_project_iam_custom_role" "automq_byoc_resource_role" {
  role_id     = replace("automq_byoc_resource_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} ResourceManager Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} ResourceManager Role"
  permissions = [
    "resourcemanager.projects.get",
  ]
}


resource "google_project_iam_custom_role" "automq_byoc_gke_role" {
  role_id     = replace("automq_byoc_gke_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} GKE Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} GKE Role"
  permissions = [
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
    "container.nodes.list",
    "container.networkPolicies.get",
    "container.networkPolicies.create",
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
    "container.statefulSets.updateStatus",
    "container.storageClasses.create",
    "container.storageClasses.get",
    "container.storageClasses.list",
    "container.storageClasses.update",
    "container.deployments.get",
    "container.deployments.create",
    "container.deployments.delete", 
    "container.deployments.list",
    "container.deployments.getScale",
    "container.deployments.getStatus",
    "container.priorityClasses.create",
    "container.priorityClasses.delete",
    "container.priorityClasses.get",
    "container.priorityClasses.list",
    "container.priorityClasses.update",
    "container.clusterRoleBindings.create",
    "container.clusterRoleBindings.delete",
    "container.clusterRoleBindings.get",
    "container.clusterRoleBindings.list",
    "container.clusterRoles.bind",
    "container.clusterRoles.create",
    "container.clusterRoles.delete",
    "container.clusterRoles.get",
    "container.clusterRoles.list"
  ]
}

resource "google_project_iam_binding" "automq_byoc_dns_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_dns_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

resource "google_project_iam_binding" "automq_byoc_resource_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_resource_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

resource "google_project_iam_binding" "automq_byoc_compute_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_compute_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

resource "google_project_iam_binding" "automq_byoc_gke_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_gke_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
  condition {
    title      = "AutoMQ BYOC ${var.automq_byoc_env_id} GKE Role Condition"
    expression = "resource.matchTag(\"${var.cloud_project_id}/automqAssigned\", \"automq\")"
  }
}

resource "google_project_iam_binding" "automq_byoc_storage_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_storage_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

resource "google_project_iam_binding" "gke_permission_binding0" {
  project = var.cloud_project_id
  role    = "roles/container.admin"

  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}",
  ]
}

# Firewall rules
resource "google_compute_firewall" "automq_byoc_console_sg" {
  name    = "automq-byoc-console-${var.automq_byoc_env_id}"
  network = local.automq_byoc_vpc_name
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


locals {
  console_image_name = var.use_custom_image ? var.automq_byoc_env_console_image : "Automq-control-center-Prod-${var.automq_byoc_env_version}-x86_64"
}
data "google_compute_image" "console_image" {
  name = lower(
    replace(replace(local.console_image_name,
      "_", "-"),
  ".", "-"))
}

data "google_compute_network" "vpc" {
  depends_on = [google_compute_network.automq_network]
  name       = local.automq_byoc_vpc_name
}

resource "google_compute_route" "route_ipv4_googleapi" {
  count = var.create_new_vpc ? 1 : 0
  name             = "route-to-gapis-ipv4-${var.automq_byoc_env_id}"
  network          = data.google_compute_network.vpc.name
  dest_range       = "199.36.153.8/30"
  next_hop_gateway = "https://www.googleapis.com/compute/v1/projects/${var.cloud_project_id}/global/gateways/default-internet-gateway"

  priority = 90
}

resource "google_compute_route" "route_ipv4_googleapi_additional" {
  count = var.create_new_vpc ? 1 : 0
  name             = "route-to-gapis-ipv4-additional-${var.automq_byoc_env_id}"
  network          = data.google_compute_network.vpc.name
  dest_range       = "34.126.0.0/18"
  next_hop_gateway = "https://www.googleapis.com/compute/v1/projects/${var.cloud_project_id}/global/gateways/default-internet-gateway"

  priority = 90
}

resource "google_compute_firewall" "subnet_allow-internal" {
  count   = var.create_new_vpc ? 1 : 0
  name    = "allow-internal-firewall-${var.automq_byoc_env_id}"
  network = data.google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65534"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65534"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    "10.128.0.0/9"
  ]

  direction = "INGRESS"
}

resource "google_compute_firewall" "allow_googleapis_ipv4" {
  count = var.create_new_vpc ? 1 : 0
  name    = "allow-out-gapis-ipv4-${var.automq_byoc_env_id}"
  network = data.google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  destination_ranges = [
    "199.36.153.8/30",
    "34.126.0.0/18"
  ]

  direction = "EGRESS"
}

