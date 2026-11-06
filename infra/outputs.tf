output "load_balancer_dns_name" {
  description = "ALB DNS name; use your certificate's domain name when HTTPS is enabled."
  value       = aws_lb.app.dns_name
}

output "http_test_url" {
  description = "HTTP test endpoint. With a certificate configured, this redirects to HTTPS; use your matching custom DNS name."
  value       = "http://${aws_lb.app.dns_name}/simple"
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.app.name
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "resolved_ami_id" {
  description = "Record this regional AMI ID in ami_id to pin the OS image for later runs."
  value       = local.ami_id
}

output "application_port" {
  value = local.app_port
}
