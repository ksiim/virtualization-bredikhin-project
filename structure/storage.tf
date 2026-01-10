resource "random_id" "suffix" {
  byte_length = 4
}

resource "yandex_iam_service_account" "s3" {
  name = "${var.project}-s3-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "s3_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.s3.id}"
}

resource "yandex_iam_service_account_static_access_key" "s3_key" {
  service_account_id = yandex_iam_service_account.s3.id
  description        = "static key for object storage"
}

resource "yandex_storage_bucket" "bucket" {
  bucket = "${var.project}-bucket-${random_id.suffix.hex}"
}
