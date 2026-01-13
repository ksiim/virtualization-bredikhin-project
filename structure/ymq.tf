# Service Account для Message Queue
resource "yandex_iam_service_account" "ymq" {
  name = "${var.project}-ymq-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "ymq_admin" {
  folder_id = var.folder_id
  role      = "ymq.admin"
  member    = "serviceAccount:${yandex_iam_service_account.ymq.id}"
}

resource "yandex_iam_service_account_static_access_key" "ymq_key" {
  service_account_id = yandex_iam_service_account.ymq.id
  description        = "static key for message queue"
}

resource "yandex_message_queue" "task_notifications" {
  name                       = "${var.project}-task-notifications"
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 86400

  access_key = yandex_iam_service_account_static_access_key.ymq_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.ymq_key.secret_key
}
