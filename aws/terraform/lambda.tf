
# Declara a execução do comando NPM para compilar a Lambda Layer.
resource "null_resource" "build_lambda_layers" {

  # Quando houver alterações no arquivo package.json, será disparado uma trigger para o provisioner executar o comando npm de instalação.
  triggers = {
    layer_build = filemd5("${local.layers_path}/package.json")
  }

  provisioner "local-exec" {
    working_dir = local.layers_path
    command     = "npm install --production && cd ../ && zip -9 -r --quiet ${local.layer_name} *"
  }
}

# Declara a Lambda Layer contendo a dependência externa "Joi" para interpretar JSON
resource "aws_lambda_layer_version" "joi" {
  layer_name          = "joi-layer"
  description         = "joi: 17.3.0"
  filename            = "${local.layers_path}/../${local.layer_name}"
  compatible_runtimes = ["nodejs14.x"]

  depends_on = [null_resource.build_lambda_layers]
}

# Data Source para gerar o arquivo compactado contendo o código fonte da função Lambda que vai interagir com o S3
data "archive_file" "s3" {
  type        = "zip"
  source_file = "${local.lambdas_path}/s3/index.js"
  output_path = "files/s3-artefact.zip"
}

# Declara a função Lambda para interagir com o bucket S3
resource "aws_lambda_function" "s3" {
  function_name = "s3"
  handler       = "index.handler"

  # IAM Role para interação com o bucket S3
  role    = aws_iam_role.s3.arn
  runtime = "nodejs14.x"

  filename         = data.archive_file.s3.output_path
  source_code_hash = data.archive_file.s3.output_base64sha256

  # Atribui a Lambda Layer com a dependência do Joi (Obs: Suporta até 5 layers por função Lambda)
  layers = [aws_lambda_layer_version.joi.arn]

  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.this.arn
    }
  }

  tags = local.common_tags
}

# Declara a permissão para que o bucket s3 invoque a função Lambda
resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.todo.arn
}

# Data Source para gerar o arquivo compactado contendo o código fonte da função Lambda que vai interagir com o DynamoDB
data "archive_file" "dynamo" {
  type        = "zip"
  source_file = "${local.lambdas_path}/dynamo/index.js"
  output_path = "files/dynamo-artefact.zip"
}

# Declara a função Lambda para interagir com o DynamoDB
resource "aws_lambda_function" "dynamo" {
  function_name = "dynamo"
  handler       = "index.handler"
  role          = aws_iam_role.dynamo.arn
  runtime       = "nodejs14.x"

  filename         = data.archive_file.dynamo.output_path
  source_code_hash = data.archive_file.dynamo.output_base64sha256

  timeout     = 30
  memory_size = 128

  # Passa a tabela DynamoDB como uma variável de ambiente para a função Lambda.
  environment {
    variables = {
      TABLE = aws_dynamodb_table.this.name
    }
  }
}

# Declara a permissão para que o API Gateway invoque a função Lambda
resource "aws_lambda_permission" "dynamo" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dynamo.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# Declara a permissão para que o SNS invoque a função Lambda
resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dynamo.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this.arn
}

