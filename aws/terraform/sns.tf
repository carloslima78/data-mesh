
# Declara um tópico SNS
resource "aws_sns_topic" "this" {
  name = var.service_name
}

# Declara um assintante para o tópico SNS, neste caso a função Lambda.
resource "aws_sns_topic_subscription" "lambda" {
  endpoint  = aws_lambda_function.dynamo.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.this.arn
}