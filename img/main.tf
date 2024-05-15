resource "yandex_iam_service_account" "bucket-service" {
  folder_id = var.yandex_folder_id
  name      = "bucket-service"
}

resource "yandex_resourcemanager_folder_iam_member" "service-editor" {
  folder_id = var.yandex_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.bucket-service.id}"
}

resource "yandex_iam_service_account_static_access_key" "service-key" {
  service_account_id = yandex_iam_service_account.bucket-service.id
}

resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket_key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h"
  lifecycle {
    prevent_destroy = true
  }
}

resource "yandex_storage_bucket" "my_bucket" {
  access_key = yandex_iam_service_account_static_access_key.service-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.service-key.secret_key
  bucket = "anton-14052024"
  acl  = "public-read"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "image" {
  access_key = yandex_iam_service_account_static_access_key.service-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.service-key.secret_key
  bucket = yandex_storage_bucket.my_bucket.bucket
  key    = "111.jpg"
  source = "~/terraform/111.jpg"
}