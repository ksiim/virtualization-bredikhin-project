output "alb_public_ip" {
  value = yandex_alb_load_balancer.alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "app1_public_ip" {
  value = yandex_compute_instance.app1.network_interface[0].nat_ip_address
}

output "app2_public_ip" {
  value = yandex_compute_instance.app2.network_interface[0].nat_ip_address
}

output "db_public_ip" {
  value = yandex_compute_instance.db.network_interface[0].nat_ip_address
}

output "bucket_name" {
  value = yandex_storage_bucket.bucket.bucket
}

output "s3_access_key_id" {
  value     = yandex_iam_service_account_static_access_key.s3_key.access_key
  sensitive = true
}

output "s3_secret_access_key" {
  value     = yandex_iam_service_account_static_access_key.s3_key.secret_key
  sensitive = true
}
output "ymq_queue_url" {
  value = yandex_message_queue.task_notifications.id
}

output "ymq_access_key" {
  value     = yandex_iam_service_account_static_access_key.ymq_key.access_key
  sensitive = true
}

output "ymq_secret_key" {
  value     = yandex_iam_service_account_static_access_key.ymq_key.secret_key
  sensitive = true
}
