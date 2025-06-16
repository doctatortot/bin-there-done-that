# SSL Certificate Policy

## Free Certificates

- Let’s Encrypt certificates issued automatically
- Applies to DirectAdmin, AzuraCast, and custom subdomains
- Auto-renews every 60 days with 30-day buffer

## Premium SSL

- Custom SSL certs (e.g., EV/OV) available for purchase
- Requires manual install via WHMCS ticket

## Certificate Management

- Certbot used for automation
- Custom certs must be supplied in `.crt` + `.key` format
- Broken SSL installs may be reverted to Let’s Encrypt fallback

## Support

- Certificate issues resolved within 24h of report
- DNS challenges supported for wildcard certs
