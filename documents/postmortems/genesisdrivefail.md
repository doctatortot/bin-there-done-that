# Postmortem: SPL Media Disk Incident and Disaster Recovery Drill

**Date:** [05/19/2025]  
**Author:** Doc (Genesis Hosting)
*
---

## Summary

On [05/19/2025], while attempting to remove a deprecated RAID5 drive from the SPL Windows host, the incorrect disk was accidentally detached. This disk contained the live SPL media volume. Due to Windows' handling of dynamic disks, the volume was marked as "Failed" and inaccessible, triggering an immediate DR response.

Despite the unintentional nature of the incident, it served as a live test of Genesis Hosting's SPL disaster recovery process. The full restore was completed successfully in under an hour using tarball-based SCP transfer from Shredder, validating both the local snapshot source and DR scripting approach.

---

## Timeline

- **T-0 (Start):** Attempt made to remove deprecated RAID5 disk  
- **T+0:** Incorrect disk unplugged (live SPL media)  
- **T+2m:** Disk appears in Windows as "Missing/Failed"  
- **T+5m:** SCP-based restore initiated from Shredder  
- **T+10m:** `.zfs` snapshot artifact detected and ignored  
- **T+15m:** Decision made to continue full tarball-based SCP restore  
- **T+58m:** Restore completed to `R:\` and SPL resumed functionality

---

## Impact

- SPL station was temporarily offline (estimated downtime < 1 hour)  
- No data was lost  
- No external users were affected due to off-air timing

---

## Root Cause

Human error during manual drive removal in a mixed-disk environment where Windows showed multiple 5TB drives.

---

## Resolution

- Restore initiated from validated ZFS source (Shredder)  
- SCP-based tarball transfer completed  
- Permissions and structure preserved  
- SPL fully restored to operational state

---

## Lessons Learned

1. Windows dynamic disks are fragile and easily corrupted by hot-unplug events  
2. SCP is reliable but not optimal for large restores  
3. `.zfs` snapshot visibility can interfere with SCP unless explicitly excluded  
4. Tarball-based transfers dramatically reduce restore time  
5. Disaster recovery scripts should log and time every phase

---

## Action Items

- [x] Set up secondary disk on SPL host for test restores  
- [x] Begin alternating restore tests from Shredder and Linode Object Storage  
- [x] Convert restore flow to tarball-based for faster execution  
- [ ] Formalize `genesisctl drill` command for DR testing  
- [ ] Add timed logging to all DR scripts  
- [ ] Expand approach to AzuraCast and Mastodon (in progress)

---

## Conclusion

While the incident began as a misstep, it evolved into a high-value test of Genesis Hosting's disaster recovery capabilities. The successful, timely restore validated the core backup architecture and highlighted key improvements to be made in automation, speed, and DR testing processes moving forward.

This will serve as Drill #1 in the GenesisOps DR series, codename: **Sterling Forest**.
