variable "db_name" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "allocated_storage" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "parameter_group_name" {
  type = string
}

variable "skip_final_snapshot" {
  type = bool
}

variable "multi_az" {
  type = bool
}

variable "publicly_accessible" {
  type = bool
}

variable "ttl_expiry_time" {
  type = number 
  
}

variable "environment" {
  type = string
  
}