locals {

  # Caminho físico da pasta que contém o código fonte das lambdas
  lambdas_path = "${path.module}/../app/lambdas"

  # Caminho físico da pasta que contém o arquivo com a dependência do Joi para armazenar na lambda layer
  layers_path = "${path.module}/../app/layers/nodejs"

  # Nome que será atribuído a lambda layer
  layer_name = "joi.zip"

  # Tags comuns
  common_tags = {
    Projeto   = "Data Mesh - Dominio de Pedidos"
    Autor     = "Carlos Fabiano Lima"
  }
}