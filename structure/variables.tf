variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "sa_key_file" {
  type = string
}

variable "project" {
  type    = string
  default = "alb-app"
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key_path" {
  type = string
}

variable "ssh_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "git_repo" {
  type    = string
  default = "https://github.com/ksiim/virtualization-bredikhin-project.git"
}

variable "git_branch" {
  type    = string
  default = "yc"
}

variable "db_user" {
  type    = string
  default = "app"
}

variable "db_pass" {
  type    = string
  default = "apppass"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "db_disk_gb" {
  type    = number
  default = 20
}
