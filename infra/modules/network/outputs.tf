output "domain_name" {
  description = "Custom domain name registered in API Gateway."
  value       = aws_apigatewayv2_domain_name.api.domain_name
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID."
  value       = aws_route53_zone.main.zone_id
}

output "hosted_zone_name_servers" {
  description = "Name servers for the Route 53 hosted zone. Set these at your domain registrar."
  value       = aws_route53_zone.main.name_servers
}

output "api_custom_endpoint" {
  description = "Public URL reachable via the custom domain (HTTPS)."
  value       = "https://${var.domain_name}"
}

output "certificate_arn" {
  description = "ARN of the ACM certificate issued for the custom domain."
  value       = aws_acm_certificate_validation.api.certificate_arn
}
