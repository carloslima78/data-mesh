

# Declara um User Pool (Grupo de Usuários) para armazenamento de usuários que vão se autentciar via Cognito 
resource "aws_cognito_user_pool" "my-pool" {

  name = var.service_name
  tags = local.common_tags
}

# Declara um User Pool Client para autenticar os usuários no User Pool atuando como uma camada intermediária
resource "aws_cognito_user_pool_client" "my-client" {

  name            = var.service_name
  user_pool_id    = aws_cognito_user_pool.my-pool.id
  generate_secret = false

  allowed_oauth_flows                  = ["implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid"]
  callback_urls                        = ["http://localhost:3000"]
  supported_identity_providers         = ["COGNITO"]
}

# Declara um usuário e senha para acesso via Cognito
# Query String to JSON -> https://www.convertonline.io/convert/query-string-to-json
resource "aws_cognito_user" "teste" {

  username     = "teste"
  password     = "Teste@123"
  user_pool_id = aws_cognito_user_pool.my-pool.id
  depends_on   = [aws_cognito_user_pool_client.my-client]
}

# Declara um User Pool Domain para personalizar um domínio para o AWS Cognito

/* 
  
    A utilização do User Pool Domain é opcional, ele personalizará um domínio mais amigável, porém, se não for
    declarado, o AWS Cognito atribuirá um nome de domínio padrão de forma automática.

  */
resource "aws_cognito_user_pool_domain" "my-domain" {

  domain       = var.service_domain
  user_pool_id = aws_cognito_user_pool.my-pool.id
}


