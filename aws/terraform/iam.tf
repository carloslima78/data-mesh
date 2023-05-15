
# Data Source para declarar as permissões que tornarão as Lambdas capazes de se integrar a outros serviços da AWS
data "aws_iam_policy_document" "lambda-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --------------- S3 Role --------------------

# Data Source para declarar as permissões específicas abaixo:
data "aws_iam_policy_document" "s3" {

  # Permite que Lambda possa interagir com S3 e SNS
  statement {
    sid       = "AllowS3AndSNSActions"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:*",
      "sns:*",
    ]
  }

  # Permite que Lambda invoque outras Lambdas
  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["arn:aws:lambda:*:*:function:*"]
    actions   = ["lambda:InvokeFunction"]
  }

  # Permite que Lambda crie grupo de logs no AWS CloudWatch
  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
    actions   = ["logs:CreateLogGroup"]
  }

  # Permite que Lambda escreva logs no grupo de logs no AWS CloudWatch
  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

# Declara a IAM Role para especificar as permissões da função Lambda
resource "aws_iam_role" "s3" {
  name               = "${var.service_domain}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role.json
}

# Declara a IAM Policy
resource "aws_iam_policy" "s3" {
  name   = "${aws_lambda_function.s3.function_name}-lambda-execute-policy"
  policy = data.aws_iam_policy_document.s3.json
}

# Declara que a IAM Policy está sendo anexada na IAM Role
resource "aws_iam_role_policy_attachment" "s3-execute" {
  policy_arn = aws_iam_policy.s3.arn
  role       = aws_iam_role.s3.name
}

# --------------- Dynamo Role --------------------

# Data Source para declarar as permissões específicas abaixo:
data "aws_iam_policy_document" "dynamo" {

  # Permite que Lambda execute operaçoes CRUD na tabela DynamoDB
  statement {
    sid       = "AllowDynamoPermissions"
    effect    = "Allow"
    resources = ["*"]

    actions = ["dynamodb:*"]
  }

  # Permite que Lambda invoque outras Lambdas
  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["arn:aws:lambda:*:*:function:*"]
    actions   = ["lambda:InvokeFunction"]
  }

  # Permite que Lambda crie grupo de logs no AWS CloudWatch
  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
    actions   = ["logs:CreateLogGroup"]
  }

  # Permite que Lambda escreva logs no grupo de logs no AWS CloudWatch
  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

# Declara a IAM Role para especificar as permissões da função Lambda
resource "aws_iam_role" "dynamo" {
  name               = "dynamo-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role.json
}

# Declara a IAM Policy
resource "aws_iam_policy" "dynamo" {
  name   = "dynamo-lambda-execute-policy"
  policy = data.aws_iam_policy_document.dynamo.json
}

# Declara que a IAM Policy está sendo anexada na IAM Role
resource "aws_iam_role_policy_attachment" "dynamo" {
  policy_arn = aws_iam_policy.dynamo.arn
  role       = aws_iam_role.dynamo.name
}


