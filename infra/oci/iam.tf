resource "oci_identity_policy" "oke_workloads" {
  count = var.create_workload_identity_policy ? 1 : 0

  compartment_id = var.compartment_id
  name           = "${var.project_name}-oke-workloads"
  description    = "Least-privilege access from ToggleMaster OKE service accounts to OCI Queue and NoSQL."
  freeform_tags  = local.common_tags

  statements = [
    "Allow any-user to use queue-push in compartment id ${var.compartment_id} where all {request.principal.type = 'workload', request.principal.namespace = '${var.kubernetes_namespace}', request.principal.service_account = 'evaluation-service', request.principal.cluster_id = '${oci_containerengine_cluster.main.id}', target.queue.id = '${oci_queue_queue.evaluations.id}'}",
    "Allow any-user to use queue-pull in compartment id ${var.compartment_id} where all {request.principal.type = 'workload', request.principal.namespace = '${var.kubernetes_namespace}', request.principal.service_account = 'analytics-service', request.principal.cluster_id = '${oci_containerengine_cluster.main.id}', target.queue.id = '${oci_queue_queue.evaluations.id}'}",
    "Allow any-user to read nosql-tables in compartment id ${var.compartment_id} where all {request.principal.type = 'workload', request.principal.namespace = '${var.kubernetes_namespace}', request.principal.service_account = 'analytics-service', request.principal.cluster_id = '${oci_containerengine_cluster.main.id}', target.nosql-table.id = '${oci_nosql_table.analytics.id}'}",
    "Allow any-user to use nosql-rows in compartment id ${var.compartment_id} where all {request.principal.type = 'workload', request.principal.namespace = '${var.kubernetes_namespace}', request.principal.service_account = 'analytics-service', request.principal.cluster_id = '${oci_containerengine_cluster.main.id}', target.nosql-table.id = '${oci_nosql_table.analytics.id}'}",
  ]
}
