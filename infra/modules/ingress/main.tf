# ---------------------------------------------------------------------------
# Deliverable C — Public Ingress Layer
# HTTP API Gateway con Lambda proxy integration
# ---------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "sportspace" {
  name          = "${var.project_name}-${var.environment}-${var.api_name}"
  protocol_type = "HTTP"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.sportspace.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
}

# E3 — rutas específicas (POC, se mantienen para backward-compat)
resource "aws_apigatewayv2_route" "get_reservations" {
  api_id    = aws_apigatewayv2_api.sportspace.id
  route_key = "GET /reservations"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "post_vouchers" {
  api_id    = aws_apigatewayv2_api.sportspace.id
  route_key = "POST /vouchers"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.sportspace.id
  route_key = "GET ${var.health_check_path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# E4 — catch-all: cualquier ruta no definida arriba va a FastAPI/mangum
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.sportspace.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.sportspace.id
  name        = var.stage_name
  auto_deploy = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
