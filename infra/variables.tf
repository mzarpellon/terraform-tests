variable "project-name" {
  default = "risco-credito"
}

variable "region" {
  default = "us-east-1"
}

variable "bucket-prefix" {
  default = "risco"
  type = string 
  description = "Prefixo único para os buckets S3 para garantir unicidade global."
}