#!/bin/bash

# === Genesis PXE Verifier ===
# Verifies iPXE script and image accessibility over Tailscale

TAILSCALE_IP="100.113.50.65"
VM_NAME="$1"

if [[ -z "$VM_NAME" ]]; then
  echo "Usage: $0 <vm-name>"
  exit 1
fi

IPXE_URL="http://100.113.50.65:3000/ipxe/${VM_NAME}.ipxe"


echo "🔎 Checking iPXE script at $IPXE_URL ..."
if ! curl -fsSL "$IPXE_URL" -o /tmp/${VM_NAME}.ipxe; then
  echo "❌ Failed to fetch iPXE script: $IPXE_URL"
  exit 2
fi
echo "✅ iPXE script retrieved."

# Extract kernel and initrd lines
KERNEL_URL=$(grep '^kernel ' /tmp/${VM_NAME}.ipxe | awk '{print $2}')
INITRD_URL=$(grep '^initrd ' /tmp/${VM_NAME}.ipxe | awk '{print $2}')

if [[ -z "$KERNEL_URL" || -z "$INITRD_URL" ]]; then
  echo "❌ Could not parse kernel/initrd URLs from iPXE script."
  exit 3
fi

echo "🔍 Kernel URL:  $KERNEL_URL"
echo "🔍 Initrd URL:  $INITRD_URL"

echo "🔎 Verifying kernel URL ..."
if ! curl -fsI "$KERNEL_URL" >/dev/null; then
  echo "❌ Kernel file not accessible."
  exit 4
fi
echo "✅ Kernel accessible."

echo "🔎 Verifying initrd URL ..."
if ! curl -fsI "$INITRD_URL" >/dev/null; then
  echo "❌ Initrd file not accessible."
  exit 5
fi
echo "✅ Initrd accessible."

echo "🎉 PXE verification successful for VM: $VM_NAME"
echo "🚀 Ready to launch boot from $IPXE_URL"

# Optional: Telegram notify (requires telegram-send config)
if command -v telegram-send &>/dev/null; then
  telegram-send "✅ PXE verify passed for *${VM_NAME}*.  
Netboot source: \`${IPXE_URL}\`  
Kernel: \`${KERNEL_URL##*/}\`  
Initrd: \`${INITRD_URL##*/}\`  
Ready to launch via Proxmox." --parse-mode markdown
fi

exit 0
