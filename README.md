# Hetzner Server Management

This repository contains infrastructure-as-code and GitOps configurations for deploying and managing a K3s Kubernetes cluster on Hetzner Cloud.

## 📁 Project Structure

### `k3s-hetzner-sv-tf/` - Terraform Infrastructure

Terraform configuration for provisioning a K3s Kubernetes cluster on Hetzner Cloud.

#### Features

- Automated K3s cluster deployment on Hetzner Cloud
- Configurable server type, location, and image
- SSH key management
- Automatic installation of Docker, Helm, and K3s
- Kubeconfig setup

#### Configuration

The following variables can be configured in `variables.tf` or via environment variables:

| Variable          | Default        | Description                                   |
| ----------------- | -------------- | --------------------------------------------- |
| `cloud_token`     | -              | Hetzner Cloud API token (required, sensitive) |
| `server_name`     | `k3s-master`   | Name of the server                            |
| `server_type`     | `cx23`         | Server type/size                              |
| `server_location` | `nbg1`         | Hetzner datacenter location                   |
| `server_image`    | `ubuntu-24.04` | OS image to use                               |

#### Prerequisites

- Terraform installed
- Hetzner Cloud account and API token
- SSH key pair at `~/.ssh/hetzner_ssh` and `~/.ssh/hetzner_ssh.pub`

#### Usage

1. **Set up SSH keys:**

   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/hetzner_ssh
   ```

2. **Initialize Terraform:**

   ```bash
   cd k3s-hetzner-sv-tf
   terraform init
   ```

3. **Configure your Hetzner Cloud token:**

   ```bash
   export TF_VAR_cloud_token="your-hetzner-token"
   ```

4. **Deploy the infrastructure:**

   ```bash
   terraform plan
   terraform apply
   ```

5. **Retrieve the server IP:**

   ```bash
   terraform output
   ```

6. **Copy kubeconfig from the server:**
   ```bash
   scp -i ~/.ssh/hetzner_ssh root@<server-ip>:~/.kube/config ~/.kube/config-hetzner
   # Update the server IP in the kubeconfig
   kubectl --kubeconfig ~/.kube/config-hetzner config set-cluster default --server=https://<server-ip>:6443
   ```

### `flux/` - GitOps with Flux CD

Flux CD configuration for managing Kubernetes resources via GitOps methodology.

#### Structure

```
flux/
├── apps/              # Application definitions
│   ├── base/          # Base application configurations
│   └── staging/       # Staging environment overlays
├── charts/            # Helm charts
│   └── service-chart/ # Generic service helm chart
├── clusters/          # Cluster configurations
│   └── staging/       # Staging cluster setup
└── infrastructure/    # Infrastructure components
    ├── base/          # Base infrastructure
    └── staging/       # Staging infrastructure
```

#### Components

**Infrastructure:**

- **Sealed Secrets** - Encrypted secrets management
- **Cert-Manager** - Automated TLS certificate management with Let's Encrypt and Cloudflare DNS
- **Helm Repositories** - External chart sources

**Applications:**

- **nginx** - Ingress controller
- **smart-news** - Application deployment
- **steam-companion** - Application deployment

#### Flux Bootstrap

1. **Install Flux CLI:**

   ```bash
   curl -s https://fluxcd.io/install.sh | sudo bash
   ```

2. **Bootstrap Flux on your cluster:**

   ```bash
   export GITHUB_TOKEN="your-github-token"
   export GITHUB_USER="your-github-username"
   export GITHUB_REPO="hetzner-server-management"

   flux bootstrap github \
     --owner=$GITHUB_USER \
     --repository=$GITHUB_REPO \
     --branch=main \
     --path=flux/clusters/staging \
     --personal
   ```

3. **Verify Flux installation:**
   ```bash
   flux check
   kubectl get kustomizations -n flux-system
   ```

## 🔐 Managing Secrets with Kubeseal

This project uses [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) to securely manage Kubernetes secrets in Git.

### Installing kubeseal CLI

**Linux:**

```bash
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar -xvzf kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

**macOS:**

```bash
brew install kubeseal
```

### Creating a Sealed Secret

**Create a regular Kubernetes secret (don't commit this!):**

```bash
kubectl create secret generic steam-companion-secrets \
--namespace=apps \
--from-literal=USERNAME="admin" \
--from-literal=PASSWORD="password" \
--dry-run=client -o yaml | \
kubeseal --format yaml --cert flux/scripts/staging_pub_key.pem \
> flux/apps/staging/<app>/secret.yaml
```

## 📊 Monitoring

Check Flux reconciliation status:

```bash
flux get sources git
flux get kustomizations
flux get helmreleases -A
```

View logs:

```bash
flux logs --follow --all-namespaces
```

## 🔄 Updates

To update applications or infrastructure:

1. Modify the YAML files in the respective directories
2. Commit and push changes
3. Flux will automatically reconcile within 10 minutes (or force with `flux reconcile kustomization <name>`)
