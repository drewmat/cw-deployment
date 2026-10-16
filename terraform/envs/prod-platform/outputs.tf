output "argocd_port_forward" {
  value = "aws eks update-kubeconfig --name ${local.cluster_name} --region ${var.region} && kubectl -n argocd port-forward svc/argocd-server 8080:80"
}
