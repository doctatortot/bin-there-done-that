# Death to Object Storage: A Love Letter to Flat Files

Once upon a time, I believed in MinIO.

I really did. The idea was beautiful: S3-compatible object storage, self-hosted, redundant, robust — all those wonderful buzzwords they slap on the side of a Docker image and call “enterprise.” I bought into it. I built around it. I dreamed in buckets.

And then, reality set in.

What reality, you ask?

- Media uploads timing out.
- Phantom 403s from ghosts of CORS configs past.
- Uploader works on Tuesday, breaks on Wednesday.
- “Why are all the thumbnails gone?”
- “Why does the backup contain *literally nothing*?”

MinIO became that coworker who talks a big game but never shows up to help move the server rack. Sure, he says he's “highly available” — but when you need him? Boom. 503.

So I did what any burned-out, overcaffeinated sysadmin would do. I tore it all down.

Flat files. ZFS. Snapshots. The old gods.

Now my media lives on Shredder. It’s fast. It’s simple. It scrubs itself weekly and never lies to me. Want to know if something's backed up? I check with my own eyes — not by playing 20 questions with a broken object path and a timestamp from the Nixon administration.

I don’t have to `mc alias` anything.
I don’t need to care about ACLs.
I don’t need to learn how to spell “presigned URLs” ever again.

It. Just. Works.

So, farewell MinIO. You tried. You failed. You’re off my network.

Long live `chmod -R`, long live ZFS, and long live sysadmins who know when to throw the whole stack in the trash and start over.

---

📌 PS: If you’re still on object storage for your Mastodon instance… I’m sorry. I really am.


