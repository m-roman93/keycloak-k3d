resource "kubectl_manifest" "postgresql_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:  
  name: postgresql
YAML
  depends_on = [
    kubectl_manifest.nginx-svc
  ]
}

resource "kubectl_manifest" "pv_postgresql" {
  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolume
metadata:  
  name: pv-postgresql
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
    path: "/data/postgresql"
YAML
  depends_on = [
    kubectl_manifest.postgresql_namespace
  ]
}

resource "kubectl_manifest" "pvc_postgresql" {
  yaml_body = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app.kubernetes.io/instance: postgresql
    app.kubernetes.io/name: postgresql
  name: pvc-postgresql
  namespace: postgresql
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: local-path
  volumeMode: Filesystem
  volumeName: pv-postgresql
YAML
  depends_on = [
    kubectl_manifest.pv_postgresql
  ]
}

resource "helm_release" "postgresql" {
  name             = "postgresql"
  chart            = "postgresql"
  repository       = "https://charts.bitnami.com/bitnami"
  namespace        = "postgresql"
  version          = "12.11.1"
  create_namespace = false

  values = [
    templatefile("./templates/postgresql/values.yml", {
      keycloak_db_password   = var.keycloak_db_password
      postgres_root_password = var.postgres_root_password
    })
  ]

  depends_on = [
    kubectl_manifest.pvc_postgresql
  ]
}

