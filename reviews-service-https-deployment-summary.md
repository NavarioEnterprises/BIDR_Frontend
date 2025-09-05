# Reviews Service HTTPS SSL Setup - Complete Guide

**Domain:** `reviews.bidr.co.za`  
**Service:** BIDR Reviews and Ratings Service  
**Date:** September 5, 2025  
**Status:** ✅ SSL Infrastructure Complete, ⚠️ Backend Service Needs Fix

## 📋 Overview

This document provides a comprehensive guide for the HTTPS SSL setup for the BIDR Reviews Service at `reviews.bidr.co.za`. The setup includes SSL certificate generation, Azure Application Gateway configuration, and deployment automation.

## 🏗️ Architecture

```
Internet → DNS (reviews.bidr.co.za) → Azure Application Gateway (172.185.41.205:443) 
    → SSL Termination → Backend Pool → Reviews Service Container (13.64.114.164:8000)
```

## ✅ Completed Components

### 1. SSL Certificate
- **Certificate Authority:** Let's Encrypt
- **Domain:** `reviews.bidr.co.za`
- **Certificate Name:** `reviews-bidr-co-za-cert`
- **Format:** PFX (uploaded to Azure Application Gateway)
- **Password:** `BidrReviewsService2024!`
- **Expiration:** December 4, 2025

### 2. Azure Application Gateway Configuration

#### Backend Pool
- **Name:** `reviews-service-pool`
- **Current Backend:** `20.228.108.228` (temporary - auth service)
- **Target Backend:** `13.64.114.164` (reviews service - not responding)
- **Port:** 8000

#### HTTPS Listener
- **Name:** `reviews-service-https-listener`
- **Port:** 443 (HTTPS)
- **SSL Certificate:** `reviews-bidr-co-za-cert`
- **Host Name:** `reviews.bidr.co.za`
- **SNI:** Enabled

#### HTTP Settings
- **Name:** `reviews-service-http-settings`
- **Protocol:** HTTP
- **Port:** 8000
- **Timeout:** 30 seconds
- **Cookie Affinity:** Disabled

#### Routing Rule
- **Name:** `reviews-service-https-rule`
- **Type:** Basic
- **Priority:** 110
- **Listener:** `reviews-service-https-listener`
- **Backend Pool:** `reviews-service-pool`
- **HTTP Settings:** `reviews-service-http-settings`

## 🚀 Deployment Scripts

### Main Deployment Script
```bash
./deploy-reviews-service-ssl.sh
```

This script:
- ✅ Validates all SSL infrastructure components
- ✅ Checks Application Gateway configuration  
- ✅ Tests HTTPS endpoint connectivity
- ✅ Verifies DNS resolution
- ✅ Provides status summary and next steps

## 🔧 Service Configuration

### Reviews Service Container
- **Name:** `bidr-reviews-service`
- **IP Address:** `13.64.114.164`
- **Port:** 8000
- **Status:** ⚠️ Waiting/CrashLoopBackOff (763 restarts)
- **Health Endpoint:** `/health/`

### Application Details
- **Framework:** Django 
- **Python Version:** 3.11
- **Server:** Gunicorn
- **Workers:** 3
- **Database:** PostgreSQL

## 🌐 DNS Configuration

### Required DNS Records

**A Record:**
```
Name: reviews.bidr.co.za
Type: A
Value: 172.185.41.205 (Application Gateway IP)
TTL: 300
```

**TXT Record (for SSL renewal):**
```
Name: _acme-challenge.reviews.bidr.co.za
Type: TXT
Value: [Generated during certificate renewal]
TTL: 300
```

## 🧪 Testing

### SSL Certificate Test
```bash
echo | openssl s_client -servername reviews.bidr.co.za -connect reviews.bidr.co.za:443 2>/dev/null | openssl x509 -noout -dates
```

### HTTPS Endpoint Test
```bash
curl -k -I https://reviews.bidr.co.za/
```

### DNS Resolution Test
```bash
nslookup reviews.bidr.co.za
```

### Expected Responses
- **HTTPS Status:** HTTP/1.1 502 Bad Gateway (expected with current backend)
- **SSL:** ✅ Certificate valid (Let's Encrypt)
- **DNS:** ❌ Currently not resolving (A record needed)

## 🎯 Current Status

### ✅ Completed
- [x] SSL certificate obtained from Let's Encrypt
- [x] Certificate uploaded to Azure Application Gateway
- [x] Backend pool created and configured
- [x] HTTPS listener configured with SSL certificate
- [x] HTTP settings configured for port 8000
- [x] Routing rule created with priority 110
- [x] HTTPS endpoint responding (502 expected with temp backend)
- [x] Deployment script created and tested
- [x] Comprehensive documentation completed

### ⚠️ Pending Issues
- [ ] DNS A record: `reviews.bidr.co.za` → `172.185.41.205`
- [ ] Reviews service container fix (CrashLoopBackOff)
- [ ] Backend pool update to working reviews service IP
- [ ] End-to-end functionality testing

## 🔧 Troubleshooting

### Common Issues

**1. DNS Resolution Fails**
```bash
# Check DNS propagation
nslookup reviews.bidr.co.za 8.8.8.8

# Add temporary hosts entry for testing
echo "172.185.41.205 reviews.bidr.co.za" | sudo tee -a /etc/hosts
```

**2. SSL Certificate Issues**
```bash
# Verify certificate
az network application-gateway ssl-cert show --resource-group bidr-simple-rg --gateway-name bidr-app-gateway --name reviews-bidr-co-za-cert

# Check certificate expiration
echo | openssl s_client -servername reviews.bidr.co.za -connect 172.185.41.205:443 2>/dev/null | openssl x509 -noout -dates
```

**3. Backend Service Issues**
```bash
# Check container status
az container show --resource-group bidr-simple-rg --name bidr-reviews-service

# Test direct container connection
curl -i --connect-timeout 5 http://13.64.114.164:8000/health
```

## 🔄 SSL Certificate Renewal

### Manual Renewal Process
```bash
# 1. Generate new certificate
sudo certbot certonly --manual --preferred-challenges dns -d reviews.bidr.co.za

# 2. Convert to PFX
openssl pkcs12 -export -out reviews-bidr-co-za-new.pfx -inkey /etc/letsencrypt/live/reviews.bidr.co.za/privkey.pem -in /etc/letsencrypt/live/reviews.bidr.co.za/fullchain.pem -passout pass:BidrReviewsService2024!

# 3. Update Application Gateway
az network application-gateway ssl-cert update --resource-group bidr-simple-rg --gateway-name bidr-app-gateway --name reviews-bidr-co-za-cert --cert-file reviews-bidr-co-za-new.pfx --cert-password BidrReviewsService2024!
```

## 📞 Support Information

### Key Resources
- **Azure Resource Group:** `bidr-simple-rg`  
- **Application Gateway:** `bidr-app-gateway`
- **Public IP:** `172.185.41.205`
- **Container Group:** `bidr-reviews-service`

### Log Locations
- **Let's Encrypt:** `/var/log/letsencrypt/letsencrypt.log`
- **Application Gateway:** Azure Portal → Monitoring → Logs
- **Container Logs:** `az container logs --resource-group bidr-simple-rg --name bidr-reviews-service`

## 📈 Next Steps

### Immediate (Priority 1)
1. **Add DNS A Record:** `reviews.bidr.co.za` → `172.185.41.205`
2. **Fix Reviews Service Container:** Debug CrashLoopBackOff issue
3. **Update Backend Pool:** Point to working reviews service IP

### Short Term (Priority 2)
1. **End-to-End Testing:** Verify full HTTPS functionality
2. **Performance Testing:** Load test the HTTPS endpoint
3. **Monitoring Setup:** Configure alerts and health checks

### Long Term (Priority 3)
1. **SSL Automation:** Set up automatic certificate renewal
2. **Security Hardening:** Review SSL/TLS configuration
3. **Documentation Updates:** Keep deployment guides current

---

## 📄 Files Generated

- `deploy-reviews-service-ssl.sh` - Main deployment and validation script
- `reviews-service-https-deployment-summary.md` - This documentation file

---

**Last Updated:** September 5, 2025  
**Next Review:** December 1, 2025 (before SSL expiration)
