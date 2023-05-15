locals {

  # Caminho físico da pasta que contém o código fonte das lambdas
  lambdas_path = "${path.module}/../app/lambdas"

  # Caminho físico da pasta que contém o arquivo com a dependência do Joi para armazenar na lambda layer
  layers_path = "${path.module}/../app/layers/nodejs"

  # Nome que será atribuído a lambda layer
  layer_name = "joi.zip"

  # Tags comuns
  common_tags = {
    Project   = "TODO Serverless App"
    CreatedAt = "2023-04-18"
    ManagedBy = "Terraform"
    Owner     = "Carlos Fabiano Lima"
    Service   = var.service_name
  }
}