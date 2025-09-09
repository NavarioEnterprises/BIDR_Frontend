# BIDR SSL Certificate Setup

This directory contains everything needed to set up proper SSL certificates for direct container access to your BIDR services.

## 🎯 Overview

This solution provides:
- **SSL certificate generation** (self-signed or Let's Encrypt)
- **Nginx SSL proxy** for each service
- **Docker containers** with SSL termination
- **Azure Container Instance** deployment with HTTPS
- **Updated Flutter/Dart configuration** with HTTPS URLs

## 📁 Files Included

| File | Description |
|------|-------------|
| `setup-ssl-deployment.sh` | Initial setup script (run this first) |
| `generate-ssl-certs.sh` | SSL certificate generation script |
| `deploy-ssl-containers.sh` | Main deployment script |
| `nginx-ssl.conf.template` | Nginx SSL proxy configuration template |
| `Dockerfile.ssl.template` | Docker container template with SSL |
| `README.md` | This documentation file |

## 🚀 Quick Start

### Step 1: Setup
```bash
./ssl-setup/setup-ssl-deployment.sh
```
This will:
- Make all scripts executable  
- Install certbot (if needed)
- Prepare the environment

### Step 2: Generate SSL Certificates
```bash
./ssl-setup/generate-ssl-certs.sh
```
Choose between:
1. **Self-signed certificates** (recommended for testing)
2. **Let's Encrypt certificates** (requires domain validation)

### Step 3: Deploy SSL-Enabled Containers
```bash
./ssl-setup/deploy-ssl-containers.sh
```
This will:
- Generate service configurations
- Build Docker images with nginx SSL proxy
- Deploy containers to Azure Container Instances
- Generate updated Flutter/Dart configuration
- Test HTTPS endpoints

## 📋 Prerequisites

- **Azure CLI** installed and logged in (`az login`)
- **Docker** installed and running
- **certbot** (installed automatically by setup script)
- **Existing BIDR service code** in respective directories
- **Azure Container Registry** (bidrregistry) access

## 🔧 Service Configuration

The deployment script handles these services:

| Service | Port | Directory | Description |
|---------|------|-----------|-------------|
| auth | 443 | authentication_service | Authentication API |
| product | 443 | product_management_service | Product Management API |
| chat | 443 | chat_service | Chat/Messaging API |
| payment | 443 | payment_service | Payment Processing API |
| resolution | 443 | resolution_service | Dispute Resolution API |
| notifications | 443 | notifications_service | Notification Service |
| transactions | 443 | transactions_service | Transaction Management |
| reviews | 443 | reviews_and_ratings | Reviews & Ratings API |

## 🔒 SSL Certificate Details

### Self-Signed Certificates
- **Validity**: 365 days
- **Key Size**: 2048 bits RSA
- **Subject**: `/C=US/ST=WA/L=Seattle/O=BIDR/OU=IT/CN=domain`
- **Use Case**: Development and testing

### Let's Encrypt Certificates
- **Validity**: 90 days (auto-renewal recommended)
- **Key Size**: 2048 bits RSA
- **Validation**: DNS challenge (manual mode)
- **Use Case**: Production deployment

## 🏗️ Container Architecture

Each deployed container includes:

```
┌─────────────────────┐
│   Azure Container   │
│                     │
│  ┌───────────────┐  │
│  │     nginx     │  │ <- SSL Termination
│  │   (Port 443)  │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────▼───────┐  │
│  │    Django     │  │ <- Your Service
│  │   (Port 80xx) │  │
│  └───────────────┘  │
│                     │
└─────────────────────┘
```

## 📱 Flutter/Dart Configuration

After deployment, you'll get an updated configuration file:

```dart
EnvironmentType.uat: EnvironmentConfig(
  // HTTPS Service URLs with SSL certificates
  authServiceUrl: "https://bidr-auth-ssl-123456.westus.azurecontainer.io/",
  productsServiceUrl: "https://bidr-product-ssl-123456.westus.azurecontainer.io/",
  // ... other services
  
  // HTTPS Admin URLs
  authAdminUrl: "https://bidr-auth-ssl-123456.westus.azurecontainer.io/admin/",
  // ... other admin URLs
),
```

## 🔍 Testing HTTPS Endpoints

Test your SSL endpoints:

```bash
# Test with curl (accept self-signed certificates)
curl -k https://your-service-domain/health/

# Test certificate details
openssl s_client -connect your-service-domain:443 -servername your-service-domain
```

## ⚙️ Configuration Options

### Environment Variables
The containers are deployed with these environment variables:
- `DJANGO_SETTINGS_MODULE`: Service-specific settings
- `DEBUG`: Set to `False` for production
- `ALLOWED_HOSTS`: Set to `*` (adjust for security)
- `SECURE_SSL_REDIRECT`: Set to `False` (nginx handles SSL)

### Nginx SSL Configuration
- **TLS Versions**: 1.2 and 1.3 only
- **Strong Ciphers**: ECDHE, AES-GCM preferred
- **Security Headers**: HSTS, X-Frame-Options, etc.
- **CORS Support**: Enabled for API services
- **HTTP to HTTPS**: Automatic redirect

## 🔄 Certificate Renewal

### Self-Signed Certificates
Re-run the certificate generation script:
```bash
./ssl-setup/generate-ssl-certs.sh
./ssl-setup/deploy-ssl-containers.sh
```

### Let's Encrypt Certificates
Set up automatic renewal with cron:
```bash
# Add to crontab
0 0 1 */2 * /path/to/generate-ssl-certs.sh && /path/to/deploy-ssl-containers.sh
```

## 🐛 Troubleshooting

### Common Issues

**Certificate not trusted by browser:**
- This is expected with self-signed certificates
- Users will see a security warning - they can proceed safely
- For production, use proper CA-signed certificates

**Container fails to start:**
- Check certificate file permissions
- Verify service code is in correct directory
- Check Docker build logs: `docker logs <container-id>`

**HTTPS endpoint not responding:**
- Wait 2-3 minutes for container to fully start
- Check container status: `az container show --name <container-name>`
- Verify ports 80 and 443 are exposed

**SSL handshake errors:**
- Check certificate validity: `openssl x509 -noout -dates -in cert.pem`
- Verify certificate matches domain
- Check nginx SSL configuration

### Debugging Commands

```bash
# Check container status
az container list --resource-group bidr-simple-rg --output table

# View container logs
az container logs --resource-group bidr-simple-rg --name <container-name>

# Test certificate
echo | openssl s_client -connect <domain>:443 -servername <domain>

# Check nginx configuration
docker exec <container> nginx -t
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review container logs for error messages  
3. Verify all prerequisites are met
4. Test with a simple curl command first

## 🎉 Success!

Once deployed successfully, you'll have:
- ✅ All BIDR services running with HTTPS
- ✅ Valid SSL certificates (self-signed or Let's Encrypt)
- ✅ Proper security headers and CORS support
- ✅ Updated Flutter/Dart configuration
- ✅ Auto-redirect from HTTP to HTTPS

Your services will be accessible at:
```
https://bidr-auth-ssl-123456.westus.azurecontainer.io/register/
https://bidr-product-ssl-123456.westus.azurecontainer.io/api/products/
# ... and so on
```
