# Manual SSL Setup for api.bidr.co.za

If the automated script fails, follow these manual steps:

## Step 1: Get Let's Encrypt Certificate

```bash
# Method 1: HTTP Challenge (if port 80 is accessible)
sudo certbot certonly \
  --standalone \
  --email admin@bidr.co.za \
  --agree-tos \
  --no-eff-email \
  -d api.bidr.co.za

# Method 2: DNS Challenge (if port 80 is blocked)
sudo certbot certonly \
  --manual \
  --preferred-challenges dns \
  --email admin@bidr.co.za \
  --agree-tos \
  --no-eff-email \
  -d api.bidr.co.za
```

## Step 2: Copy Certificates

```bash
# Create directory
mkdir -p "/tmp/bidr-ssl-certs/api.bidr.co.za"

# Copy certificates
sudo cp /etc/letsencrypt/live/api.bidr.co.za/fullchain.pem "/tmp/bidr-ssl-certs/api.bidr.co.za/"
sudo cp /etc/letsencrypt/live/api.bidr.co.za/privkey.pem "/tmp/bidr-ssl-certs/api.bidr.co.za/"

# Fix permissions
sudo chown $(whoami) "/tmp/bidr-ssl-certs/api.bidr.co.za/"*
```

## Step 3: Update Configuration Files

```bash
# Backup current files
cp deploy-auth-ssl.sh deploy-auth-ssl.sh.backup
cp ssl-setup/generate-ssl-certs.sh ssl-setup/generate-ssl-certs.sh.backup
cp manage-auth-container.sh manage-auth-container.sh.backup

# Update domain references
sed -i.bak 's/bidr-auth-api.westus.azurecontainer.io/api.bidr.co.za/g' deploy-auth-ssl.sh
sed -i.bak 's/bidr-auth-api.westus.azurecontainer.io/api.bidr.co.za/g' ssl-setup/generate-ssl-certs.sh
sed -i.bak 's/bidr-auth-api.westus.azurecontainer.io/api.bidr.co.za/g' manage-auth-container.sh
```

## Step 4: Redeploy

```bash
# Delete current container
az container delete --resource-group bidr-simple-rg --name bidr-auth-ssl-container --yes

# Deploy with new certificate
./deploy-auth-ssl.sh
```

## Step 5: Test

```bash
# Test HTTPS
curl -I https://api.bidr.co.za

# Check certificate
openssl s_client -connect api.bidr.co.za:443 -servername api.bidr.co.za 2>/dev/null | openssl x509 -noout -subject -dates
```
