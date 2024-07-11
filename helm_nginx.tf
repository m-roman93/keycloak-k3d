resource "kubectl_manifest" "nginx_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:  
  name: ingress-nginx
YAML 
}

resource "null_resource" "nginx_cert" {
  provisioner "local-exec" {
    command     = "tls-secret.sh"
    interpreter = ["/bin/bash"]
    working_dir = path.module

    environment = {
      NAMESPACE = "ingress-nginx"
      SECRETNAME = "tls-secret"
    }
  }

  triggers = {
    always_run = "1"
  }

  depends_on = [kubectl_manifest.nginx_namespace]
}

resource "kubectl_manifest" "nginx-tcp-services" {
  yaml_body  = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-services
  namespace: ingress-nginx
data:
  5432: "postgresql/postgresql:5432"
YAML
  depends_on = [kubectl_manifest.nginx_namespace]
}


resource "helm_release" "nginx" {
  name             = "ingress-nginx"
  chart            = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = false

  values = [
    "${file("./templates/nginx/values.yml")}"
  ]

  depends_on = [
    kubectl_manifest.nginx_namespace
  ]
}

resource "kubectl_manifest" "nginx-svc" {
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
    - name: https
      port: 443
      targetPort: 443
      protocol: TCP
    - name: tcp-postgres
      port: 5432
      targetPort: 5432
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
YAML
  depends_on = [
    helm_release.nginx
  ]
}