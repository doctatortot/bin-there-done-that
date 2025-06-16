# Account Creation Policy

## Customer Accounts

- Created automatically via WHMCS upon signup
- Email verification is required before service activation
- Strong passwords (minimum 10 characters) are enforced
- 2FA is recommended and required for admin-facing services

## Staff/Admin Accounts

- Created manually by Super Admin only
- Must use SSH keys for server access
- Access logs are enabled and monitored
- Each staff account must be linked to an internal email

## Account Naming Convention

- Customers: `client_{username}`
- Admins: `admin.{firstname}`
