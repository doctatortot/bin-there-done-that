# ✅ Master Compliance Checklist  
*(Status: ☐ = Not Started | 🟨 = In Progress | ✅ = Complete)*

## 🧑‍💼 Access & User Management
- [ ] Role-Based Access Control (RBAC) in place (Customer, Admin, etc.)
- [ ] Account creation follows secure onboarding workflows
- [ ] Admin access restricted to SSH keys only
- [ ] Inactive accounts locked or removed quarterly
- [ ] Least privilege enforced across all services

## 💾 Backups & Disaster Recovery
- [ ] Daily backups enabled for all key services (DirectAdmin, WHMCS, AzuraCast, TeamTalk)
- [ ] Weekly offsite backups with verification
- [ ] ZFS snapshots scheduled (hourly/daily/weekly)
- [ ] Backup integrity validated with checksums or scrubs
- [ ] Quarterly disaster recovery drill completed
- [ ] Restore instructions documented and tested

## 🔐 Security
- [ ] 2FA enabled on all admin interfaces (WHMCS, SSH, DirectAdmin)
- [ ] SSH password auth disabled, key-only enforced
- [ ] Weekly patching or updates scheduled (Sunday 7–9 PM)
- [ ] Centralized logging active and stored 30–90 days
- [ ] Fail2Ban + Genesis Shield integrated and alerting
- [ ] TLS 1.2+ enforced for all public services
- [ ] AES-256 encryption at rest on backups and sensitive volumes

## 🖥️ Provisioning & Automation
- [ ] WHMCS integrated with DirectAdmin, AzuraCast, TeamTalk
- [ ] All provisioning scripts tested and logged
- [ ] Post-deploy verification checklist followed
- [ ] DNS + SSL automation in place (Let's Encrypt)
- [ ] Monitoring added after provisioning (Prometheus/Grafana)

## 📋 Client Policies
- [ ] Acceptable Use Policy posted and enforced
- [ ] Abuse response process defined and working
- [ ] DMCA policy publicly available and followed
- [ ] Suspension and refund rules defined in WHMCS
- [ ] Privacy Policy and Terms of Service available on client portal

## 🌐 Services Configuration
- [ ] DirectAdmin quotas enforced (disk, bandwidth, email)
- [ ] AzuraCast listener/storage/bitrate limits respected
- [ ] TeamTalk server abuse protection and user limits enforced
- [ ] Domain registration/renewal workflows tested
- [ ] SSL auto-renew working correctly (Let's Encrypt + certbot)

## ⚙️ Infrastructure
- [ ] ZFS pools configured for redundancy (RAIDZ1, mirrors)
- [ ] rclone mount points with caching working and monitored
- [ ] Genesis Shield actively alerting via Telegram/Mastodon
- [ ] All VMs named per convention (e.g., `krang`, `shredderv2`)
- [ ] Sunday maintenance window consistently followed
- [ ] Ansible playbooks used for provisioning/config consistency

## 🛠️ Tools & Scripts
- [ ] All scripts version-controlled and documented
- [ ] Backups and restore tools tested and working
- [ ] Mastodon alert bot operating with secure tokens
- [ ] Rclone VFS stats monitored regularly
- [ ] Admin tools accessible only by authorized users
"""
