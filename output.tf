##################################
# Server
##################################

output "server_public_ip" {
  value = aws_instance.server.public_ip
}

# Example. Will only work if SSH pub key was added to server-cloud-init.yaml
output "connect_to_instance" {
  value = "ssh ec2-user@`terraform output --raw server_public_ip`"
}

output "lakefs_server_ui" {
  value = "http://${aws_instance.server.public_ip}:8000"
}