resource "kubectl_manifest" "rabbitmq_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:  
  name: rabbitmq
YAML
  depends_on = [
    helm_release.nginx
  ]
}

resource "null_resource" "rabbitmq-certificate" {
  provisioner "local-exec" {
    command     = "tls-secret.sh"
    interpreter = ["/bin/bash"]
    working_dir = path.module

    environment = {
      NAMESPACE = "rabbitmq"
      SECRETNAME = "tls-secret"
    }
  }


  triggers = {
    always_run = "1"
  }

  depends_on = [kubectl_manifest.rabbitmq_namespace]
}

resource "kubectl_manifest" "pv_rabbitmq" {
  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolume
metadata:  
  name: pv-rabbitmq
spec:
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-path
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/rabbitmq"
YAML
  depends_on = [
    kubectl_manifest.rabbitmq_namespace
  ]
}

resource "kubectl_manifest" "pvc_rabbitmq" {
  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app.kubernetes.io/instance: rabbitmq
    app.kubernetes.io/name: rabbitmq
  name: pvc-rabbitmq
  namespace: rabbitmq
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: local-path
  volumeMode: Filesystem
  volumeName: pv-rabbitmq
YAML
  depends_on = [
    kubectl_manifest.pv_rabbitmq
  ]
}

resource "helm_release" "rabbitmq" {
  name             = "rabbitmq"
  chart            = "rabbitmq"
  repository       = "https://charts.bitnami.com/bitnami"
  namespace        = "rabbitmq"
  version          = "12.1.4"
  create_namespace = false

  values = [
    "${file("./templates/rabbitmq/values.yml")}"
  ]

  set {
    name  = "auth.username"
    value = "admin"
  }

  set {
    name  = "auth.password"
    value = "admin"
  }

  set {
    name  = "persistence.existingClaim"
    value = "pvc-rabbitmq"
  }

  depends_on = [
    kubectl_manifest.pvc_rabbitmq
  ]
}

resource "kubectl_manifest" "rabbitmq_ingress" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rabbitmq
  namespace: rabbitmq
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - rabbitmq.${var.base_dns}
    secretName: tls-secret
  rules:
  - host: rabbitmq.${var.base_dns}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: rabbitmq
            port:
              number: 15672
YAML
  depends_on = [
    kubectl_manifest.pv_rabbitmq
  ]
}