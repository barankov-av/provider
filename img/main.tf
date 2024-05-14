# Задание 1

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
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "my_bucket" {
  access_key = yandex_iam_service_account_static_access_key.service-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.service-key.secret_key
  bucket = "anton-14052024"
  acl  = "public-read"
}

resource "yandex_storage_object" "image" {
  access_key = yandex_iam_service_account_static_access_key.service-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.service-key.secret_key
  bucket = yandex_storage_bucket.my_bucket.bucket
  key    = "111.jpg"
  source = "~/terraform/111.jpg"
}

# Задание 2

resource "yandex_vpc_network" "my-vpc" {
  name = "my-vpc"
}

#resource "yandex_vpc_address" "addr" {
#  external_ipv4_address {
#    zone_id = var.yandex_zone
#  }
#}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance_group" "group1" {
  name                = "my-ig"
  folder_id           = var.yandex_folder_id
  service_account_id  = yandex_iam_service_account.bucket-service.id
  instance_template {
    platform_id = "standard-v1"
    resources {
      memory = 1
      cores  = 2
      core_fraction = 20
    }
    boot_disk {
      initialize_params {
        image_id = var.image_id
        size     = 4
      }
    }
    network_interface {
      network_id = yandex_vpc_network.my-vpc.id
      subnet_ids = [yandex_vpc_subnet.public_subnet.id]
      nat        = true
    }
    scheduling_policy {
            preemptible = true
    }
    metadata = {
      ssh-keys = "ubuntu:${file(var.ssh_root_key)}"
      user-data  = <<EOF
#!/bin/bash
cd /var/www/html
echo '<html><img src="http://storage.yandexcloud.net/${yandex_storage_bucket.my_bucket.bucket}/${yandex_storage_object.image.key}"/></html>' > index.html
sudo systemctl restart apache2
EOF
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.yandex_zone]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 3
    max_expansion   = 1
    max_deleting    = 2
  }
  
  load_balancer {
    target_group_name        = "target-group"
    target_group_description = "Network Load Balancer"
  }
  
  health_check {
    http_options {
      port    = 80
      path    = "/"
    }
  }
}

# Задание 3

resource "yandex_lb_network_load_balancer" "balancer" {
  name = "balancer"

  listener {
    name = "web-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.group1.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/index.html"
      }
    }
  }
}