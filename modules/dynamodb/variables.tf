variable "environment" {
  type = string 
  description = "Environment name for: prod, dev and test"
}

variable "ttl_hours" {
  type = number
  description = "Time to live for the dynamodb table"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
}