locals {
  # ECR base URI for this account and region — avoids repeating it across image references.
  ecr_base = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  # Full image URIs for each service, combining the ECR base with the configured tag.
  banking_image = "${local.ecr_base}/${var.project_name}-banking:${var.banking_image_tag}"
  trading_image = "${local.ecr_base}/${var.project_name}-trading:${var.trading_image_tag}"

  # Common labels applied to every resource for selection, observability, and GitOps tooling.
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = var.project_name
    environment                    = var.environment
  }
}

# ── Namespace ─────────────────────────────────────────────────────────────────

# Single namespace grouping all CNB workloads on the Pi cluster.
# Isolates CNB resources from any other workloads that may share the node.
resource "kubernetes_namespace" "cnb" {
  metadata {
    name   = var.project_name
    labels = local.common_labels
  }
}

# ── Secrets ───────────────────────────────────────────────────────────────────

# Kubernetes Secret storing the banking PostgreSQL credentials.
# The provider base64-encodes the values automatically; they are injected as
# environment variables into both the banking service and the database pods.
resource "kubernetes_secret" "banking_db" {
  metadata {
    name      = "${var.project_name}-banking-db-secret"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    POSTGRES_PASSWORD = var.banking_db_password
    POSTGRES_USER     = "banking"
    POSTGRES_DB       = "banking"
  }
}

# Kubernetes Secret storing the trading PostgreSQL credentials.
resource "kubernetes_secret" "trading_db" {
  metadata {
    name      = "${var.project_name}-trading-db-secret"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    POSTGRES_PASSWORD = var.trading_db_password
    POSTGRES_USER     = "trading"
    POSTGRES_DB       = "trading"
  }
}

# ── ConfigMaps ────────────────────────────────────────────────────────────────

# Non-sensitive runtime configuration for the banking service.
# DB_HOST uses Kubernetes DNS to resolve the banking-db headless Service.
resource "kubernetes_config_map" "banking" {
  metadata {
    name      = "${var.project_name}-banking-config"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    NODE_ENV = var.environment
    PORT     = "8080"
    DB_HOST  = "${var.project_name}-banking-db"
    DB_PORT  = "5432"
    DB_NAME  = "banking"
    DB_USER  = "banking"
  }
}

# Non-sensitive runtime configuration for the trading service.
resource "kubernetes_config_map" "trading" {
  metadata {
    name      = "${var.project_name}-trading-config"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    NODE_ENV = var.environment
    PORT     = "8081"
    DB_HOST  = "${var.project_name}-trading-db"
    DB_PORT  = "5432"
    DB_NAME  = "trading"
    DB_USER  = "trading"
  }
}

# ── PersistentVolumeClaims ────────────────────────────────────────────────────

# PVC requesting 5Gi of storage for the banking PostgreSQL data directory.
# On k3s the default StorageClass (local-path) provisions a hostPath volume on the Pi.
resource "kubernetes_persistent_volume_claim" "banking_db" {
  metadata {
    name      = "${var.project_name}-banking-db-pvc"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = { storage = "5Gi" }
    }
  }
}

# PVC requesting 5Gi of storage for the trading PostgreSQL data directory.
resource "kubernetes_persistent_volume_claim" "trading_db" {
  metadata {
    name      = "${var.project_name}-trading-db-pvc"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = { storage = "5Gi" }
    }
  }
}

# ── Database StatefulSets ─────────────────────────────────────────────────────

# StatefulSet running PostgreSQL 15 for the banking service.
# A StatefulSet is used (rather than a Deployment) for stable network identity
# and ordered pod management, which is important for database workloads.
resource "kubernetes_stateful_set" "banking_db" {
  metadata {
    name      = "${var.project_name}-banking-db"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "banking-db" })
  }

  spec {
    service_name = "${var.project_name}-banking-db"
    replicas     = 1

    selector {
      match_labels = { "app.kubernetes.io/name" = "banking-db" }
    }

    template {
      metadata {
        labels = merge(local.common_labels, { "app.kubernetes.io/name" = "banking-db" })
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:15-alpine"

          port {
            container_port = 5432
          }

          # Inject POSTGRES_PASSWORD, POSTGRES_USER, and POSTGRES_DB from the Secret.
          env_from {
            secret_ref {
              name = kubernetes_secret.banking_db.metadata[0].name
            }
          }

          # Mount the PVC at the PostgreSQL default data directory.
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        # Bind the named volume to the banking DB PVC.
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.banking_db.metadata[0].name
          }
        }
      }
    }
  }
}

# StatefulSet running PostgreSQL 15 for the trading service.
resource "kubernetes_stateful_set" "trading_db" {
  metadata {
    name      = "${var.project_name}-trading-db"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "trading-db" })
  }

  spec {
    service_name = "${var.project_name}-trading-db"
    replicas     = 1

    selector {
      match_labels = { "app.kubernetes.io/name" = "trading-db" }
    }

    template {
      metadata {
        labels = merge(local.common_labels, { "app.kubernetes.io/name" = "trading-db" })
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:15-alpine"

          port {
            container_port = 5432
          }

          # Inject POSTGRES_PASSWORD, POSTGRES_USER, and POSTGRES_DB from the Secret.
          env_from {
            secret_ref {
              name = kubernetes_secret.trading_db.metadata[0].name
            }
          }

          # Mount the PVC at the PostgreSQL default data directory.
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        # Bind the named volume to the trading DB PVC.
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.trading_db.metadata[0].name
          }
        }
      }
    }
  }
}

# ── Database Services (headless) ──────────────────────────────────────────────

# Headless ClusterIP Service for the banking StatefulSet.
# clusterIP = "None" means no virtual IP is assigned — pods are addressed directly
# via stable DNS names (<pod-name>.<service-name>.<namespace>.svc.cluster.local).
resource "kubernetes_service" "banking_db" {
  metadata {
    name      = "${var.project_name}-banking-db"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "banking-db" })
  }

  spec {
    selector   = { "app.kubernetes.io/name" = "banking-db" }
    cluster_ip = "None"

    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
}

# Headless ClusterIP Service for the trading StatefulSet.
resource "kubernetes_service" "trading_db" {
  metadata {
    name      = "${var.project_name}-trading-db"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "trading-db" })
  }

  spec {
    selector   = { "app.kubernetes.io/name" = "trading-db" }
    cluster_ip = "None"

    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }
  }
}

# ── Application Deployments ───────────────────────────────────────────────────

# Deployment running the banking Express service.
# Pulls the image from ECR, injects config and DB credentials, and exposes /health
# for liveness and readiness probes.
resource "kubernetes_deployment" "banking" {
  metadata {
    name      = "${var.project_name}-banking"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "banking" })
  }

  spec {
    replicas = var.banking_replicas

    selector {
      match_labels = { "app.kubernetes.io/name" = "banking" }
    }

    template {
      metadata {
        labels = merge(local.common_labels, { "app.kubernetes.io/name" = "banking" })
      }

      spec {
        container {
          name  = "banking"
          image = local.banking_image

          port {
            container_port = 8080
          }

          # Inject all keys from the ConfigMap as environment variables.
          env_from {
            config_map_ref {
              name = kubernetes_config_map.banking.metadata[0].name
            }
          }

          # Inject the DB password from the Secret as environment variables.
          env_from {
            secret_ref {
              name = kubernetes_secret.banking_db.metadata[0].name
            }
          }

          # Liveness probe — restart the pod if the health endpoint stops responding.
          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          # Readiness probe — remove the pod from Service endpoints until it is ready to serve.
          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# Deployment running the trading Express service.
# Same pattern as banking — separate image, port 8081, and its own ConfigMap and Secret.
resource "kubernetes_deployment" "trading" {
  metadata {
    name      = "${var.project_name}-trading"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "trading" })
  }

  spec {
    replicas = var.trading_replicas

    selector {
      match_labels = { "app.kubernetes.io/name" = "trading" }
    }

    template {
      metadata {
        labels = merge(local.common_labels, { "app.kubernetes.io/name" = "trading" })
      }

      spec {
        container {
          name  = "trading"
          image = local.trading_image

          port {
            container_port = 8081
          }

          # Inject all keys from the ConfigMap as environment variables.
          env_from {
            config_map_ref {
              name = kubernetes_config_map.trading.metadata[0].name
            }
          }

          # Inject the DB password from the Secret as environment variables.
          env_from {
            secret_ref {
              name = kubernetes_secret.trading_db.metadata[0].name
            }
          }

          # Liveness probe — restart the pod if the health endpoint stops responding.
          liveness_probe {
            http_get {
              path = "/health"
              port = 8081
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          # Readiness probe — remove the pod from Service endpoints until it is ready to serve.
          readiness_probe {
            http_get {
              path = "/health"
              port = 8081
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# ── Application Services ──────────────────────────────────────────────────────

# ClusterIP Service exposing the banking pods at port 8080 inside the cluster.
# Traefik (ingress on the Pi) routes /api/banking traffic to this service,
# which it receives from the Cloudflare Tunnel.
resource "kubernetes_service" "banking" {
  metadata {
    name      = "${var.project_name}-banking"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "banking" })
  }

  spec {
    selector = { "app.kubernetes.io/name" = "banking" }
    type     = "ClusterIP"

    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }
}

# ClusterIP Service exposing the trading pods at port 8081 inside the cluster.
# Traefik routes /api/trading traffic to this service.
resource "kubernetes_service" "trading" {
  metadata {
    name      = "${var.project_name}-trading"
    namespace = kubernetes_namespace.cnb.metadata[0].name
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "trading" })
  }

  spec {
    selector = { "app.kubernetes.io/name" = "trading" }
    type     = "ClusterIP"

    port {
      port        = 8081
      target_port = 8081
      protocol    = "TCP"
    }
  }
}
