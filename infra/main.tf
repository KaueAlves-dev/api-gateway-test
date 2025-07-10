provider "aws" {
  region = "us-east-1"
}

# cria e define quem pode usar a role (servico ou user)
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Atrela uma policy na minha role criada anteriormente
resource "aws_iam_role_policy_attachment" "attach_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Criando minha lambda chamada "consulta-cep-func"
resource "aws_lambda_function" "consulta_cep" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = var.lambda_filename   # ajuste o caminho conforme sua estrutura

  source_code_hash = filebase64sha256(var.lambda_filename)

}

# Criando o api-gateway
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_name
  protocol_type = "HTTP"
}

# Criando integracao entre lambda e api-gtw
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.consulta_cep.invoke_arn
  payload_format_version = "2.0"
}

# Criando uma rota GET
resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = var.route_key_cep
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Lambda permitindo ser invokada pelo api-gtw
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"  # nome único e descritivo da permissão
  action        = "lambda:InvokeFunction"  # ação permitida
  function_name = aws_lambda_function.consulta_cep.function_name
  principal     = "apigateway.amazonaws.com"  # quem está autorizado (API Gateway)
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"  # de onde pode invocar
}


resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Ajustando o tempo de retencao dos logs no cloudwatch para essa lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/consulta-cep-func"
  retention_in_days = var.logs_retention  # opcoes: 1, 3, 7, 30, 90, etx
}

