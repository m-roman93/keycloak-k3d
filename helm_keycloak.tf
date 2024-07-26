resource "kubectl_manifest" "keycloak_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:  
  name: keycloak
YAML

  depends_on = [
    helm_release.postgresql
  ]
}

resource "null_resource" "keycloak-certificate" {
  provisioner "local-exec" {
    command     = "tls-secret.sh"
    interpreter = ["/bin/bash"]
    environment = {
      NAMESPACE = "keycloak"
      SECRETNAME ="tls-secret"
    }
    working_dir = path.module
  }

  triggers = {
    always_run = "1"
  }

  depends_on = [kubectl_manifest.keycloak_namespace]
}


resource "kubectl_manifest" "keycloak-realm" {
  
  yaml_body = file("./templates/keycloak/realm.yml")

  depends_on = [
    kubectl_manifest.keycloak_namespace
  ]
}

resource "helm_release" "keycloak" {
  name             = "keycloak"
  chart            = "keycloak"
  repository       = "https://charts.bitnami.com/bitnami"
  namespace        = "keycloak"
  version          = "21.6.0"
  create_namespace = false

  values = [
    templatefile("./templates/keycloak/values.yml", {
      keycloak_admin_user     = var.keycloak_admin_user
      keycloak_admin_password = var.keycloak_admin_password
      keycloak_db_password    = var.keycloak_db_password
      keycloak_hostname       = "auth.${var.base_dns}"
      keycloak_admin_hostname = "auth-admin.${var.base_dns}"
    })
  ]

  depends_on = [
    kubectl_manifest.keycloak-realm
  ]
}
