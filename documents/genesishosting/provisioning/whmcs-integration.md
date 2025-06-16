# WHMCS Integration

WHMCS handles client billing, service provisioning, and support workflows.

## Services Integrated

| Service      | Method                          |
|--------------|---------------------------------|
| DirectAdmin  | Built-in WHMCS module           |
| AzuraCast    | Custom provisioning script       |
| TeamTalk     | API + XML user patching scripts |

## Auto-Provisioning Steps

1. Client signs up and completes payment
2. WHMCS triggers product-specific hook
3. Script/module provisions the service
4. Welcome email is sent with credentials

## Logging & Troubleshooting

- Logs stored at `/var/log/whmcs-hooks.log`
- Errors generate internal ticket automatically if provisioning fails
