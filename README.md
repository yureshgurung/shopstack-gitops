# ShopStack GitOps

GitOps repository for deploying **ShopStack** across Development, Staging, and Production Kubernetes environments using **Helm** and **Argo CD**.

## Architecture

```text
                    ┌──────────────────────┐
                    │   ShopStack Source   │
                    │      Repository      │
                    └──────────┬───────────┘
                               │
                               │ CI/CD
                               ▼
                    ┌──────────────────────┐
                    │ Container Registry   │
                    └──────────┬───────────┘
                               │
                               │ Image
                               ▼
┌───────────────────────────────────────────────────────────┐
│                    shopstack-gitops                        │
│                                                           │
│  ┌─────────────────┐       ┌──────────────────────────┐  │
│  │ Helm Chart      │       │ Environment Values       │  │
│  │                 │       │                          │  │
│  │ charts/shopstack│──────▶│ dev                      │  │
│  │                 │       │ staging                  │  │
│  │                 │       │ production               │  │
│  └────────┬────────┘       └────────────┬─────────────┘  │
│           │                             │                │
└───────────┼─────────────────────────────┼────────────────┘
            │                             │
            └──────────────┬──────────────┘
                           ▼
                    ┌───────────────┐
                    │    Argo CD    │
                    └───────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
           DEV K8s      STAGING K8s    PROD K8s
```

## Repository Structure

```text
shopstack-gitops/
│
├── argocd/
│   │
│   ├── projects/
│   │   ├── shopstack-dev.yaml
│   │   ├── shopstack-staging.yaml
│   │   └── shopstack-prod.yaml
│   │
│   ├── applications/
│   │   ├── shopstack-dev.yaml
│   │   ├── shopstack-staging.yaml
│   │   └── shopstack-prod.yaml
│   │
│   └── rbac/
│       └── shopstack-rbac.yaml
│
├── charts/
│   │
│   └── shopstack/
│       ├── Chart.yaml
│       ├── values.yaml
│       │
│       └── templates/
│           ├── _helpers.tpl
│           ├── backend-deployment.yaml
│           ├── backend-service.yaml
│           ├── frontend-deployment.yaml
│           ├── frontend-service.yaml
│           ├── serviceaccount.yaml
│           ├── configmap.yaml
│           ├── networkpolicy.yaml
│           └── httproute.yaml
│
├── environments/
│   │
│   ├── dev/
│   │   └── values.yaml
│   │
│   ├── staging/
│   │   └── values.yaml
│   │
│   └── production/
│       └── values.yaml
│
└── README.md
```

## Technology Stack

* Kubernetes
* Helm
* Argo CD
* GitOps
* Gateway API
* NetworkPolicy
* Kubernetes ServiceAccounts
* Container Registry

## Helm Strategy

The repository uses **one reusable Helm chart** for ShopStack.

```text
charts/shopstack/
        │
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
```

Environment-specific configuration is separated from the chart:

```text
environments/
├── dev/
│   └── values.yaml
├── staging/
│   └── values.yaml
└── production/
    └── values.yaml
```

This avoids duplicating Kubernetes manifests for every environment.

### Environment Configuration

| Environment | Values File                           | Purpose                |
| ----------- | ------------------------------------- | ---------------------- |
| Development | `environments/dev/values.yaml`        | Development workloads  |
| Staging     | `environments/staging/values.yaml`    | Pre-production testing |
| Production  | `environments/production/values.yaml` | Production workloads   |

## Helm Commands

### Lint the Chart

```bash
helm lint charts/shopstack
```

### Render Development

```bash
helm template shopstack-dev \
  ./charts/shopstack \
  -f ./environments/dev/values.yaml
```

### Render Staging

```bash
helm template shopstack-staging \
  ./charts/shopstack \
  -f ./environments/staging/values.yaml
```

### Render Production

```bash
helm template shopstack-prod \
  ./charts/shopstack \
  -f ./environments/production/values.yaml
```

### Install Development Manually

```bash
helm upgrade --install shopstack \
  ./charts/shopstack \
  -f ./environments/dev/values.yaml \
  -n shopstack-dev \
  --create-namespace
```

## Argo CD

Argo CD is responsible for continuously synchronizing the Kubernetes cluster with this Git repository.

Each environment has its own Argo CD `Application`:

```text
argocd/applications/
├── shopstack-dev.yaml
├── shopstack-staging.yaml
└── shopstack-prod.yaml
```

Each Application points to the same Helm chart but uses a different values file.

```text
                 charts/shopstack
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
        dev          staging       production
        values        values         values
          │            │            │
          ▼            ▼            ▼
      Argo CD       Argo CD       Argo CD
          │            │            │
          ▼            ▼            ▼
       Dev K8s      Staging K8s    Prod K8s
```

## GitOps Workflow

```text
Developer
    │
    │ Push code
    ▼
Application Repository
    │
    │ CI Pipeline
    ▼
Build Docker Image
    │
    ▼
Container Registry
    │
    │ Update image tag
    ▼
GitOps Repository
    │
    ▼
Argo CD
    │
    ▼
Kubernetes
```

The Git repository is the **source of truth** for Kubernetes application configuration.

## Deployment Flow

### Development

```text
environments/dev/values.yaml
            │
            ▼
      Argo CD Application
            │
            ▼
       Kubernetes DEV
```

### Staging

```text
environments/staging/values.yaml
            │
            ▼
      Argo CD Application
            │
            ▼
      Kubernetes STAGING
```

### Production

```text
environments/production/values.yaml
            │
            ▼
      Argo CD Application
            │
            ▼
       Kubernetes PROD
```

## Repository Responsibilities

### Application Repository

Contains:

* Frontend source code
* Backend source code
* Dockerfiles
* Application tests
* CI pipeline

### GitOps Repository

Contains:

* Helm charts
* Kubernetes configuration
* Environment values
* Argo CD Applications
* Argo CD Projects
* RBAC configuration

Keeping application source code and deployment configuration separate provides a cleaner GitOps architecture.

## Security

Production configuration should follow these principles:

* Do not commit passwords or API keys.
* Do not commit private keys.
* Do not store Kubernetes secrets in plain text.
* Use a secret management solution for sensitive configuration.
* Use separate Argo CD Projects for environments.
* Restrict production access using RBAC.
* Use immutable container image tags for production.
* Apply Kubernetes NetworkPolicies.
* Run application containers as non-root users where possible.

## Production Image Strategy

Avoid:

```yaml
image:
  tag: latest
```

Prefer immutable versions:

```yaml
image:
  tag: "v1.0.0"
```

or preferably a commit SHA:

```yaml
image:
  tag: "a8f31c2"
```

This makes production deployments reproducible.

## Useful Commands

Check Helm:

```bash
helm version
```

Check Kubernetes:

```bash
kubectl version
```

Check Argo CD:

```bash
argocd version
```

Check Helm releases:

```bash
helm list -A
```

Check applications:

```bash
kubectl get applications -n argocd
```

Check ShopStack:

```bash
kubectl get all -n shopstack-dev
```

## Goals

* [x] Create GitOps repository
* [x] Create reusable Helm chart
* [x] Separate environment values
* [x] Configure Argo CD Projects
* [x] Configure Argo CD Applications
* [x] Configure RBAC
* [ ] Add CI image automation
* [ ] Add automated image tag updates
* [ ] Add production secret management
* [ ] Add monitoring and alerting
* [ ] Add deployment rollback strategy

## Principle

> **One application → One reusable Helm chart → Environment-specific values → Argo CD → Kubernetes**

This repository follows the GitOps principle where Git is the source of truth for application deployment configuration.
