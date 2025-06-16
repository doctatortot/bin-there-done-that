# 🛡️ Case Study: Bulletproofing Genesis Infrastructure with ChaosMonkey DR Drills

**Date:** May 10, 2025  
**Organization:** Genesis Hosting Technologies  
**Lead Engineer:** Doc (Genesis Radio, Infrastructure Director)  

---

## 🎯 Objective

Design and validate a robust, automated disaster recovery (DR) system for Genesis infrastructure — including PostgreSQL, MinIO object storage, and ZFS-backed media — with an external testbed (Linode-hosted) named **ChaosMonkey**.

---

## 🧩 Infrastructure Overview

| Component        | Role                                 | Location                    |
|------------------|--------------------------------------|-----------------------------|
| PostgreSQL       | Primary/replica database nodes       | zcluster.technodrome1/2     |
| MinIO            | S3-compatible object storage         | shredder                    |
| ZFS              | Primary media storage backend        | minioraid5, thevault        |
| GenesisSync      | Hybrid mirroring and integrity check | Deployed to all asset nodes |
| ChaosMonkey      | DR simulation and restore target     | Linode                      |

---

## 🧰 Tools Developed

### `genesis_sync.sh`
- Mirrors local ZFS to MinIO and vice versa
- Supports verification, dry-run, and audit mode
- Alerts via KrangBot on error or drift

### `run_dr_failover.sh` & `run_dr_failback.sh`
- Safely fail over and restore PostgreSQL + GenesisSync
- Auto-promotes DB nodes
- Sends alerts via Telegram

### `genesis_clone_manager_multihost.sh`
- Clones live systems (DB, ZFS, MinIO) from prod to ChaosMonkey
- Runs with dry-run preview mode
- Multi-host orchestration via SSH

### `genesis_clone_validator.sh`
- Runs on ChaosMonkey
- Verifies PostgreSQL snapshot, ZFS datasets, and MinIO content
- Can optionally trigger a GenesisSync `--verify`

---

## 🧪 DR Drill Process (Stage 3 - Controlled Live Test)

1. 🔒 Freeze writes on production nodes
2. 📤 Snapshot and clone entire stack to ChaosMonkey
3. 🔁 Promote standby PostgreSQL and redirect test traffic
4. 🧪 Validate application behavior and data consistency
5. 📩 Alert via KrangBot with sync/report logs
6. ✅ Trigger safe failback using snapshot + delta sync

---

## 🚨 Results

- **Recovery time (RTO)**: PostgreSQL in 3 min, full app < 10 min
- **Zero data loss** using basebackups and WAL
- **GenesisSync** completed with verified parity between ZFS and MinIO
- **Repeatable**: Same scripts reused weekly for validation

---

## 💡 Key Takeaways

- **Scripts are smarter than sleepy admins** — guardrails matter
- **ZFS + WAL + GitOps-style orchestration = rock solid DR**
- **Testing DR live on ChaosMonkey builds real confidence**
- **Failure Friday is not a risk — it’s a training ground**

---

## 🌟 Final Thoughts

By taking DR out of theory and into action, Genesis Hosting Technologies ensures that not only is data safe — it’s recoverable, testable, and fully verified on demand. With ChaosMonkey in the mix, Genesis now embraces disaster… on its own terms.



---

## 📝 A Note on Naming

"ChaosMonkey" is inspired by the original [Chaos Monkey](https://github.com/Netflix/chaosmonkey) tool created by Netflix, designed to test the resilience of their infrastructure by randomly terminating instances. Our use of the name pays homage to the same principles of reliability, failover testing, and engineering with failure in mind. No affiliation or endorsement by Netflix is implied.
