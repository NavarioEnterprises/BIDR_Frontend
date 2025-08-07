# BIDR Backend - Django API

A containerized Django REST API backend for the BIDR application, deployed on Azure Kubernetes Service (AKS) with automated CI/CD.

## 🚀 Live Application

**Production Environment:**
- **URL**: `http://20.66.69.82:8067/`
- **Admin**: `http://20.66.69.82:8067/admin/`
- **API Endpoints**: Available at `/accounts/`, `/sign_in/`, etc.

## 🏗️ Architecture

- **Backend**: Django 5.1 + Django REST Framework
- **Database**: PostgreSQL 15
- **Container**: Docker (multi-stage build)
- **Orchestration**: Kubernetes (Azure AKS)
- **Registry**: Azure Container Registry
- **CI/CD**: GitHub Actions

## 📋 Prerequisites

- Python 3.11
- Docker
- Azure CLI
- kubectl
- Azure subscription

## 🛠️ Local Development

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd BIDR

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver 8067
```

### Running Tests

```bash
# Run all tests
python manage.py test

# Run tests with coverage
coverage run --source='.' manage.py test
coverage report
coverage html
```

## 🐳 Docker

### Build and Run Locally

```bash
# Build the image
docker build -t bidr-app .

# Run the container
docker run -p 8067:8067 bidr-app
```

## ☁️ Azure Deployment

### Application Deployment

```bash
# Build and deploy using the script
./build-and-deploy.sh
```

Or manually:

```bash
# Build and push Docker image
docker build --platform linux/amd64 -t bidr-app .
az acr login --name BIDRcontainerregistry
docker tag bidr-app bidrcontainerregistry.azurecr.io/bidr-app:latest
docker push bidrcontainerregistry.azurecr.io/bidr-app:latest

# Deploy to Kubernetes
kubectl apply -k k8s/

# Check deployment status
kubectl get pods -n bidr
kubectl get services -n bidr
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The project includes automated CI/CD with GitHub Actions:

#### Triggers
- **Pull Requests**: Runs tests and code quality checks
- **Push to `develop`**: Deploys to staging environment
- **Push to `main`**: Deploys to production environment

#### Pipeline Stages

1. **Test Stage**
   - Python 3.11 setup
   - PostgreSQL service container
   - Install dependencies
   - Run Django tests
   - Generate coverage reports

2. **Build & Deploy Stage** (Production)
   - Build Docker image
   - Push to Azure Container Registry
   - Deploy to AKS production namespace
   - Verify deployment health

3. **Staging Deploy** (Develop branch)
   - Build staging image
   - Deploy to `bidr-staging` namespace

### Setup CI/CD

1. Run the setup script:
```bash
chmod +x setup-cicd.sh
./setup-cicd.sh
```

2. Add the `AZURE_CREDENTIALS` secret to your GitHub repository:
   - Go to: Settings → Secrets and variables → Actions
   - Add new secret: `AZURE_CREDENTIALS`
   - Paste the JSON output from the setup script

3. Create branch structure:
```bash
git checkout -b develop
git push origin develop
```

### Monitoring Deployments

```bash
# Check deployment status
kubectl get pods -n bidr
kubectl get services -n bidr

# View application logs
kubectl logs -f deployment/bidr-app -n bidr

# Check rollout status
kubectl rollout status deployment/bidr-app -n bidr
```

## 📁 Project Structure

```
BIDR/
├── .github/workflows/       # GitHub Actions CI/CD
│   └── deploy.yml
├── bidr_project/            # Django project settings
├── k8s/                     # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── postgres.yaml
│   ├── bidr-app.yaml
│   └── kustomization.yaml
├── Dockerfile               # Container definition
├── requirements.txt         # Python dependencies
├── build-and-deploy.sh      # Manual deployment script
├── setup-cicd.sh            # CI/CD setup script
└── README.md                # This documentation
```

## 🔧 Configuration

### Environment Variables

The application uses the following configuration:

**Production (Kubernetes ConfigMap & Secrets):**
- `DEBUG`: False
- `ALLOWED_HOSTS`: "*"
- `DATABASE_*`: PostgreSQL connection settings
- `SECRET_KEY`: Django secret key
- `EMAIL_*`: SMTP configuration

**Local Development:**
- Uses SQLite database by default
- Debug mode enabled
- Local file-based media storage

### Kubernetes Resources

- **Namespace**: `bidr`
- **Deployments**: `bidr-app` (2 replicas), `postgres`
- **Services**: `bidr-service-lb` (LoadBalancer), `bidr-service` (ClusterIP)
- **ConfigMaps**: Application configuration
- **Secrets**: Sensitive data (passwords, keys)

## 🔒 Security

### Production Security Features

- Container runs as non-root user
- Secrets stored in Kubernetes secrets
- RBAC enabled on AKS cluster
- Private container registry
- Network policies (recommended)

### Development Security

- Debug mode disabled in production
- Separate staging environment
- Automated security scanning (can be added)

## 📊 Monitoring

### Health Checks

- **Application**: `http://20.66.69.82:8067/admin/`
- **Database**: PostgreSQL health checks in Kubernetes
- **Container**: Docker health checks

### Logging

```bash
# View application logs
kubectl logs -f deployment/bidr-app -n bidr

# View all pods logs
kubectl logs -f -l app=bidr-app -n bidr

# View database logs
kubectl logs -f deployment/postgres -n bidr
```

## 🚀 Scaling

### Horizontal Scaling

```bash
# Scale application replicas
kubectl scale deployment bidr-app --replicas=5 -n bidr

# Auto-scaling (can be configured)
kubectl autoscale deployment bidr-app --cpu-percent=50 --min=2 --max=10 -n bidr
```

### Cluster Scaling

AKS node pool can be scaled through Azure portal or CLI.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch from `develop`
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Development Workflow

```bash
# Feature development
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# Make changes, add tests
# ...

# Commit and push
git add .
git commit -m "feat: add new feature"
git push origin feature/your-feature-name

# Create pull request to develop branch
```

## 📝 API Documentation

### Available Endpoints

- `POST /sign_in/` - User authentication
- `POST /app_user_create/` - User registration
- `GET /admin/` - Admin interface
- `GET /accounts/` - Account management

### API Response Format

```json
{
    "status": "success|error",
    "data": {},
    "message": "Response message"
}
```

## 🆘 Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   kubectl describe pod <pod-name> -n bidr
   # Check image pull secrets and ACR permissions
   ```

2. **Database Connection Issues**
   ```bash
   kubectl logs deployment/postgres -n bidr
   # Check database credentials in secrets
   ```

3. **Application Not Starting**
   ```bash
   kubectl logs deployment/bidr-app -n bidr
   # Check environment variables and migrations
   ```

### Support Commands

```bash
# Get cluster info
kubectl cluster-info

# Check node status
kubectl get nodes

# View events
kubectl get events -n bidr --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n bidr
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ for the BIDR project**
