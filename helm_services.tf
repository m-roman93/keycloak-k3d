resource "kubectl_manifest" "services_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:  
  name: services
YAML
  depends_on = [
    helm_release.nginx
  ]
}

resource "null_resource" "services-certificate" {
  provisioner "local-exec" {
    command     = "tls-secret.sh"
    interpreter = ["/bin/bash"]
    working_dir = path.module

    environment = {
      NAMESPACE = "services"
      SECRETNAME = "tls-secret"
    }
  }

  triggers = {
    always_run = "1"
  }

  depends_on = [kubectl_manifest.services_namespace]
}


resource "helm_release" "frontend" {
  name             = "frontend"
  chart            = "./templates/frontend"
  namespace        = "services"
  create_namespace = false

  values = [
    "${file("./templates/frontend/values.yaml")}"
  ]

  
  depends_on = [
    helm_release.backend
  ]
}



resource "helm_release" "backend" {
  name             = "backend"
  chart            = "./templates/backend"
  namespace        = "services"
  create_namespace = false

  values = [
    "${file("./templates/backend/values.yaml")}"
  ]

  
  depends_on = [
    null_resource.services-certificate
  ]
}
