
# Nomeará o bucket S3
resource "random_pet" "bucket" {}

# Declara o bucket S3
resource "aws_s3_bucket" "todo" {
  bucket = "${var.service_domain}-${random_pet.bucket.id}"
  tags   = local.common_tags

  force_destroy = true
}

# Declara uma notificação do bucket S3 invocando a função Lambda.
resource "aws_s3_bucket_notification" "lambda" {
  bucket = aws_s3_bucket.todo.id


  lambda_function {

    # Função Lambda que será notificada
    lambda_function_arn = aws_lambda_function.s3.arn

    # Notificará a Lambda para qualquer tipo de arquivo que for incluído no bucket. É possível filtrar (.jpg, .json, etc.)
    events = ["s3:ObjectCreated:*"]
  }
}

