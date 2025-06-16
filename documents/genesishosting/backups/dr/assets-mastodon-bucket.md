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
