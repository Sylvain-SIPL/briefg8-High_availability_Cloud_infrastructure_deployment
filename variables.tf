variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "resource_group_name" {

  description = "ressource group"
  default     = "HKS-Group"

}

variable "location" {
  description = "location"
  default     = "northeurope"
}


variable "packer_image_name" {
  description = "image packer nginx"
  default     = "Nginx"
}


variable "packer_image_bus" {
  description = "image packer debian"
  default     = "Debian-business"
}

