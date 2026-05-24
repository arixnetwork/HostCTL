# Hostctl

A modern, secure, extensible multi-tenant web hosting control panel.

## Features

- **Multi-Tenant** - Isolated tenants with resource quotas and reseller support
- **Site Management** - Static sites, PHP, Node.js, Python, Ruby, Java, Docker, Custom Stacks
- **"Build Your Own Custom" Stack Builder** - Define stacks via YAML manifest with build hooks, services, health checks
- **DNS Management** - Full DNS hosting with zone editor supporting A/AAAA/CNAME/MX/TXT/SRV/TLSA/CAA
- **SSL/TLS Automation** - Automatic Let's Encrypt ACME integration with wildcard support
- **Managed Databases** - MySQL/MariaDB/PostgreSQL with backups and slow query analysis
- **Backups & Snapshots** - Scheduled backups to S3 with encryption and retention policies
- **Monitoring & Alerts** - CPU, memory, disk, network metrics with configurable alert rules
- **Host Management** - Add/manage host nodes with agent-based provisioning
- **Billing & Invoicing** - Plans, usage-based billing, Stripe integration, tax support
- **Marketplace** - One-click install apps (WordPress, Ghost, etc.) and stack templates
- **Plugin System** - Extend the panel with plugins and custom hooks
- **Webhooks & API** - Full REST API, webhooks for events, and CLI tool
- **Audit Logging** - Immutable audit trail of all actions
- **Team Management** - RBAC with Owner, Admin, Developer, Billing roles
- **Security** - WAF, rate limiting, MFA/2FA, session management, secrets encryption
- **White-labeling** - Custom branding and domain

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Control Plane                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Auth/   │  │   API    │  │Provision │  │  Job     │   │
│  │  IAM     │  │  Gateway │  │  Engine  │  │  Queue   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  DNS     │  │   SSL/   │  │   DB     │  │  Storage │   │
│  │  Manager │  │   ACME   │  │  Manager │  │  Manager │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Billing │  │Monitoring│  │   Plugin │  │Marketplace│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└───────────────────┬─────────────────────────────────────────┘
                    │ gRPC (mTLS)
┌───────────────────▼─────────────────────────────────────────┐
│                    Host Agents                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Container │  │   File   │  │   DNS    │  │  Metrics │   │
│  │  Manager │  │  System  │  │  Config  │  │  Collector│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Go 1.22, Chi Router |
| API | REST JSON, OpenAPI 3.1 |
| Agent Communication | gRPC with mTLS |
| Database | PostgreSQL 16 |
| Cache/Queue | Redis 7 |
| Object Storage | S3/MinIO |
| Web UI | React 18, TypeScript, Vite, Tailwind CSS |
| Monitoring | Prometheus + Grafana |
| Containers | Docker/Podman |
| Message Queue | NATS (optional) |
| Billing | Stripe |

## Getting Started

### Prerequisites

- Go 1.22+
- PostgreSQL 16+
- Redis 7+
- Node.js 20+ (for UI development)
- Docker & Docker Compose (for development environment)

### Quick Start with Docker Compose

```bash
# Clone and start all services
make docker-up

# Run database migrations
make db-migrate

# Start the API server
make dev
```

### Manual Setup

```bash
# 1. Start infrastructure
docker compose -f deploy/compose/docker-compose.yml up -d postgres redis minio

# 2. Run migrations
psql -h localhost -U hostctl -d hostctl -f internal/database/schema.sql

# 3. Start the API server
make dev

# 4. Start the web UI (in another terminal)
cd web/ui && npm install && npm run dev
```

### Configuration

Copy and edit the config file:

```bash
cp config.yaml config.local.yaml
# Edit config.local.yaml with your settings
hostctl --config config.local.yaml server
```

### CLI Usage

```bash
# Show all commands
hostctl help

# Manage tenants
hostctl tenants create "My Agency" --slug my-agency --plan starter

# Manage sites
hostctl sites create example.com --tenant <tenant-id> --runtime node --git-repo https://github.com/user/repo

# Deploy a site
hostctl sites deploy <site-id> --branch main

# Manage stacks
hostctl stacks validate my-stack.yaml
hostctl stacks create "My Stack" --file my-stack.yaml --version 1.0.0

# Manage hosts
hostctl hosts list
hostctl hosts add node-01 --ip 192.168.1.100
```

## API Documentation

Full OpenAPI 3.1 specification is available in `docs/openapi.yaml`.

### Authentication

```
POST /api/v1/auth/login
Authorization: Bearer <jwt_token>
X-API-Key: <api_key>
```

### Key Endpoints

| Category | Endpoints |
|----------|-----------|
| Auth | `/auth/login`, `/auth/register`, `/auth/refresh`, `/auth/mfa/verify` |
| Tenants | `/tenants`, `/tenants/{id}`, `/tenants/{id}/usage` |
| Sites | `/sites`, `/sites/{id}`, `/sites/{id}/deploy`, `/sites/{id}/certificates/issue` |
| Stacks | `/stacks`, `/stacks/{id}/generate`, `/stacks/{id}/publish` |
| DNS | `/dns/zones`, `/dns/zones/{id}/records` |
| Certs | `/certificates`, `/certificates/{id}/renew` |
| DBs | `/databases`, `/databases/{id}/backup` |
| Backups | `/backups`, `/backups/{id}/restore`, `/backups/schedules` |
| Hosts | `/hosts`, `/hosts/{id}/metrics` |
| Jobs | `/jobs`, `/jobs/{id}/cancel`, `/jobs/{id}/retry` |
| Billing | `/plans`, `/invoices`, `/invoices/{id}/pay` |
| Alerts | `/alerts/rules`, `/alerts/events` |
| Webhooks | `/webhooks`, `/webhooks/{id}/test` |
| Plugins | `/plugins`, `/plugins/install` |
| Marketplace | `/marketplace/apps`, `/marketplace/install` |

## Stack Builder

Define custom hosting stacks using the Hostctl Stack Manifest format (YAML):

```yaml
schema_version: "1.0"
name: "My Stack"
version: "1.0.0"
base_image: "ubuntu:22.04"
runtime: "node"

build_scripts:
  build: |
    npm ci && npm run build
  post_deploy: |
    npm run migrate

services:
  - name: app
    image: "node:20"
    command: "node dist/server.js"
    ports:
      - "3000:3000"

health_check:
  type: http
  endpoint: "/health"
  interval: 30
  timeout: 10
  retries: 3
```

See `examples/stacks/` for more examples (WordPress, Node.js, Django).

## Deployment

### Docker Compose (Development)

```bash
make docker-up
```

### Kubernetes (Production)

Helm charts available in `deploy/helm/`:

```bash
helm install hostctl ./deploy/helm/hostctl
```

### Production Requirements

- PostgreSQL HA (Patroni,PgBouncer)
- Redis Sentinel or Cluster
- MinIO HA or external S3
- Load balancer (HAProxy/Nginx)
- Prometheus + Grafana for monitoring
- Elasticsearch/Loki for centralized logging

## Project Structure

```
├── cmd/hostctl/            # CLI and server entry point
│   └── commands/           # CLI command implementations
├── internal/
│   ├── api/                # REST API handlers and server
│   ├── auth/               # Authentication, JWT, MFA
│   ├── agent/              # gRPC host agent service
│   ├── billing/            # Billing, plans, invoices
│   ├── certificates/       # ACME/SSL certificate management
│   ├── config/             # Configuration loading
│   ├── dns/                # DNS management
│   ├── monitoring/         # Metrics, alerts
│   ├── plugin/             # Plugin system
│   ├── provisioner/        # Job-based provisioning engine
│   ├── security/           # WAF, rate limiter, encryption
│   ├── storage/            # Backup storage (S3/local)
│   └── types/              # Core data types
├── proto/                  # gRPC protobuf definitions
├── web/ui/                 # React TypeScript web UI
├── deploy/
│   ├── compose/            # Docker Compose dev environment
│   ├── docker/             # Dockerfiles
│   ├── helm/               # Kubernetes Helm charts
│   └── terraform/          # Infrastructure as Code
├── examples/stacks/        # Stack manifest examples
└── docs/                   # Documentation and API specs
```

## Security

- **TLS everywhere** - mTLS for agent-server communication
- **Password hashing** - bcrypt with configurable cost
- **Secrets encryption** - AES-256-GCM with Argon2 key derivation
- **JWT authentication** - Configurable expiry and refresh tokens
- **2FA/MFA** - Time-based one-time passwords (TOTP)
- **Rate limiting** - Per-IP and per-account limits
- **WAF** - Built-in web application firewall rules
- **Audit logging** - Immutable audit trail
- **RBAC** - Role-based access control with granular permissions
- **API key auth** - Scoped API keys with prefix-based identification

## License

MIT
