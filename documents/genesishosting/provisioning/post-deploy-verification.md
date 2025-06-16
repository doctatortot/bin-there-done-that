# Post-Deployment Verification

All services go through a post-deploy QA check to ensure they're live and stable.

## Verification Tasks

- [ ] Service reachable from public IP or internal route
- [ ] DNS resolves correctly (for domains/subdomains)
- [ ] SSL certificate is active and trusted
- [ ] Admin login works as expected
- [ ] Usage quotas correctly applied (disk, users, bandwidth)

## Monitoring

- [ ] Add to Prometheus for service-specific metrics
- [ ] Set alert thresholds (e.g., disk > 80%)
- [ ] Confirm Telegram/Mastodon alert webhook is functional

## Documentation

- [ ] Log final status in WHMCS admin notes
- [ ] Store internal service details in `genesis-inventory.yaml`
