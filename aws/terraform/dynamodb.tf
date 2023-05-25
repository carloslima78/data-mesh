# Declara uma tabela no DynamoDB
resource "aws_dynamodb_table" "this" {
  hash_key       = "idpedido"
  name           = var.service_name
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "idpedido"
    type = "S"
  }

  tags = local.common_tags
}

