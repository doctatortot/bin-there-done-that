## 2025-05-02 22:24:25 – MinIO Bucket Access Configuration for Mastodon

**Bucket**: `assets-mastodon`
**Server**: `shredderv2`
**User**: `genesisuser`
**Permissions**: Read / Write / Delete
**Policy Name**: `assets-mastodon-rw-policy`

### Commands Executed:

```bash
mc alias set localminio http://localhost:9000 genesisadmin MutationXv3!

cat > assets_mastodon_rw_policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::assets-mastodon"
    },
    {
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::assets-mastodon/*"
    }
  ]
}
EOF

mc admin policy add localminio assets-mastodon-rw-policy assets_mastodon_rw_policy.json
mc admin policy set localminio assets-mastodon-rw-policy user=genesisuser
```

### Outcome:

User `genesisuser` now has full authenticated access to `assets-mastodon` on `shredderv2`'s MinIO.

---

## 2025-05-02 22:43:00 – MinIO Transfer Log: AzuraCast Assets

**Source**: `thevault:/nexus/miniodata/assets_azuracast`
**Destination**: `shredderv2 MinIO` bucket `assets-azuracast`

### Transfer Method:

```bash
rclone sync thevault:/nexus/miniodata/assets_azuracast localminio:assets-azuracast \
  --progress \
  --transfers=8 \
  --checkers=8 \
  --s3-chunk-size=64M \
  --s3-upload-concurrency=4 \
  --s3-acl=private \
  --s3-storage-class=STANDARD
```

### Outcome:

Data from AzuraCast backup (`assets_azuracast`) successfully synchronized to MinIO bucket `assets-azuracast` on `shredderv2`.

---

## 2025-05-02 23:05:00 – MinIO Transfer Log: Mastodon Assets

**Source**: `thevault:/nexus/miniodata/assets_mastodon`
**Destination**: `shredderv2 MinIO` bucket `assets-mastodon`

### Transfer Method:

```bash
rclone sync thevault:/nexus/miniodata/assets_mastodon localminio:assets-mastodon \
  --progress \
  --transfers=8 \
  --checkers=8 \
  --s3-chunk-size=64M \
  --s3-upload-concurrency=4 \
  --s3-acl=private \
  --s3-storage-class=STANDARD
```

### Outcome:

Assets from `assets_mastodon` replicated to `assets-mastodon` bucket on `shredderv2`. No impact to production (`shredderv1`) during sync.
