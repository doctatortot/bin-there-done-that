# Provisioning Checklist

This checklist is followed every time a new service is deployed.

## Pre-Provisioning

- [ ] Verify order and payment in WHMCS
- [ ] Confirm product mapping is correct
- [ ] Check available server resources

## Provisioning

- [ ] Trigger appropriate script/module
- [ ] Log provisioning result
- [ ] Assign DNS entries if applicable
- [ ] Generate Let’s Encrypt SSL if public-facing

## Post-Provisioning

- [ ] Send welcome email via WHMCS
- [ ] Confirm monitoring alert is active
- [ ] Test login credentials and endpoints
- [ ] Label service with client ID in Grafana/Prometheus
