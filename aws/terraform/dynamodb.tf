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

# Declara um item a que será inserido na tabela do DynamoDB
resource "aws_dynamodb_table_item" "todo" {
  table_name = aws_dynamodb_table.this.name
  hash_key   = aws_dynamodb_table.this.hash_key

  item = <<ITEM
{
  "idpedido": {"S": "10"},
  "idcliente": {"S": "1"},
  "nome": {"S": "João Silva"},
  "email": {"S": "joao.silva@gmail.com"},
  "telefone": {"S": "+55 11 99999-9999"},
  "total": {"S": "4000.00"}
}
ITEM

}