# mostra a url da api ao dar terraform apply
output "api_endpoint" {
  description = "URL pública da API"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/cep/{cep}"
}
