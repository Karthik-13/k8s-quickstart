output "k8s-master" {
  value       = aws_instance.k8s-master.public_dns
  description = "K8s Cluster Master DNS"
}

output "k8s-nodes" {
  value       = aws_instance.k8s-nodes.*.public_dns
  description = "K8s Cluster Worker Nodes DNS"
}
