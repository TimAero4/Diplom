variable "flow" {
  type    = string
  default = "43"
}

variable "cloud_id" {
  type    = string
  default = "b1gd6celtrq48rqlhekt"
}
variable "folder_id" {
  type    = string
  default = "b1g5f4m0at0vmefjddka"
}

variable "test" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
}

