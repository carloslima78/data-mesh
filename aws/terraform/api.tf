
# Declara uma API no AWS API Gateway, que será o proxy de acesso para a função Lambda (Back-End)
resource "aws_api_gateway_rest_api" "pedidos-api" {
  name = var.service_name
}

# Declara um "Resource Path" para compor a URL da API - "nossa-api/v1"
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.pedidos-api.id
  parent_id   = aws_api_gateway_rest_api.pedidos-api.root_resource_id
  path_part   = "v1"
}

# Declara um segundo "Resource Path" para compor a URL da API - "nossa-api/v1/todos"
resource "aws_api_gateway_resource" "pedidos" {
  rest_api_id = aws_api_gateway_rest_api.pedidos-api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "pedidos"
}

# Declara o Authorizer (Autorizador) de acesso externo a API, que neste caso, será o AWS Cognito
resource "aws_api_gateway_authorizer" "api-authorizer" {
  rest_api_id   = aws_api_gateway_rest_api.pedidos-api.id
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.my-pool.arn]
}

# Declara os métodos HTTP aos quais a API vai responder (GET, PUT, POST, DELETE, PATCH)
resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.pedidos-api.id
  resource_id   = aws_api_gateway_resource.pedidos.id
  authorization = "COGNITO_USER_POOLS"
  http_method   = "ANY"
  authorizer_id = aws_api_gateway_authorizer.api-authorizer.id
}

# Declara a integração de comunicação do AWS API Gateway para processar as requisições recebidas
  /*
      Observação:

      A integração define o protocolo de comunicação (HTTP, HTTPS, Lambda, etc), a URL do backend, 
      o formato dos dados (JSON, XML, etc), os parâmetros da requisição, os headers, os tipos de 
      respostas esperadas e outras configurações relacionadas à comunicação entre o API Gateway e o backend.
  */
resource "aws_api_gateway_integration" "api-integration" {
  rest_api_id             = aws_api_gateway_rest_api.pedidos-api.id
  resource_id             = aws_api_gateway_resource.pedidos.id
  http_method             = aws_api_gateway_method.any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.dynamo.invoke_arn
}

# Declara um deployment para publicar uma nova versão da API, neste caso, criaremos no Stage "dev"
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.pedidos-api.id
  stage_name  = "dev"

  depends_on = [aws_api_gateway_integration.api-integration]
}