variable "yandex_token" {
  default = ""
}

variable "yandex_cloud_id" {
  default = ""
}

variable "yandex_folder_id" {
  default = ""
}

variable "yandex_zone" {
  default = "ru-central1-a"
}

variable "nat_image_id" {
  default = "fd8e09l2blguqbdk5eej"
}

variable "public_private_image_id" {
  default = "fd8igkjhaas0ssv7qqmv"
}

variable "ssh_root_key" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "nat-instance-ip" {
  default = "192.168.10.254"
}