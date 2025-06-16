# MinIO: It Works, But It Hates Me

*By someone who survived a 150,000-file sync and lived to tell the tale.*

---

MinIO is fast. It's lightweight. It's compatible with Amazon S3. It’s everything you want in a self-hosted object storage system.

Until you try to **use it like a filesystem**.

Then it becomes the most temperamental, moody, selectively mute piece of software you've ever met.

---

## What I Was Trying to Do

All I wanted was to migrate ~40GB of Mastodon media from local disk into a MinIO bucket. Nothing fancy. Just a clean `rclone sync` and a pat on the back.

---

## What Actually Happened

- **Load average spiked to 33**
- `find` froze
- `rclone size` hung
- `zfs snapshot` stalled so long I thought the server died
- The MinIO **UI lied to my face** about how much data was present (5GB when `rclone` said 22GB)
- Directory paths that looked like files. Files that were secretly directories. I saw `.meta` and `.part.1` in my dreams.

---

## The Root Problem

MinIO is **not** a filesystem.

It's a flat key-value object store that's just *pretending* to be a folder tree. And when you throw 150,000+ nested objects at it — especially from a tool like `rclone` — all the lies unravel.

It keeps going, but only if:
- You feed it one file at a time
- You don’t ask it questions (`rclone ls`, `rclone size`, `find`, etc.)
- You don’t use the UI expecting it to reflect reality

---

## The Fixes That Kept Me Sane

- Switched from `rclone ls` to `rclone size` with `--json` (when it worked)
- Cleaned up thousands of broken `.meta`/`.part.*` directories using a targeted script
- Paused `rclone` mid-sync with `kill -STOP` to get snapshots to complete
- Used `du -sh` instead of `find` to track usage
- Lowered `rclone` concurrency with `--transfers=4 --checkers=4`
- Drank water. A lot of it.

---

## The Moral of the Story

If you're going to use MinIO for massive sync jobs, treat it like:

- A **delicate black box** with fast internals but fragile mood
- Something that **prefers to be written to, not inspected**
- An S3 clone with boundary issues

---

## Final Thought

MinIO *does* work. It's powerful. It’s fast. But it also absolutely hates being watched while it works.

And you won't realize how much until you're 100,000 files deep, snapshot frozen, and `rclone` is telling you you're doing great — while the UI smirks and says you're at 5 gigs.

MinIO: It works.  
But it hates you.

---

**Filed under:** `disaster recovery`, `object storage`, `sync trauma`, `zfs`, `rclone`, `why me`
