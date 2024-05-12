resource "yandex_vpc_network" "my-vpc" {
  name = "my-vpc"
}

resource "yandex_vpc_address" "addr" {
  external_ipv4_address {
    zone_id = "${var.yandex_zone}"
  }
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public"
  network_id     = yandex_vpc_network.my-vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "nat_instance" {
  name         = "nat-instance"
  zone         = yandex_vpc_subnet.public_subnet.zone
  boot_disk {
    initialize_params {
      image_id = "${var.nat_image_id}"
    }
  }
  network_interface {
    subnet_id      = yandex_vpc_subnet.public_subnet.id
    ip_address     = "${var.nat-instance-ip}"
    nat = true
  }
  resources {
    cores = 2
    memory = 2
  }
  metadata = {
    ssh-keys = "debian:${file(var.ssh_root_key)}"
  }
}

resource "yandex_compute_instance" "public_vm" {
  name         = "public-vm"
  zone         = yandex_vpc_subnet.public_subnet.zone
  boot_disk {
    initialize_params {
      image_id = "${var.public_private_image_id}"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat = true
  }
  resources {
    cores = 2
    memory = 2
  }
  metadata = {
    ssh-keys = "debian:${file(var.ssh_root_key)}"
  }
}

resource "yandex_vpc_subnet" "private_subnet" {
  name           = "private"
  network_id     = yandex_vpc_network.my-vpc.id
  route_table_id = yandex_vpc_route_table.route-table.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_vpc_route_table" "route-table" {
  network_id = yandex_vpc_network.my-vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.nat-instance-ip
  }
}

resource "yandex_compute_instance" "private_vm" {
  name         = "private-vm"
  zone         = yandex_vpc_subnet.private_subnet.zone
  boot_disk {
    initialize_params {
      image_id = "${var.public_private_image_id}"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnet.id
    nat = false
  }
  resources {
    cores = 2
    memory = 2
  }
  metadata = {
    ssh-keys = "debian:${file(var.ssh_root_key)}"
  }
}