# MythCards Asset Storage

MythCards uses three complementary storage layers:

1. The local workspace is the working copy used for editing and review.
2. GitHub and Git LFS version approved development assets alongside their mappings and code.
3. Cloudflare R2 stores franchise masters, production exports, and website-ready images independently of any one computer.

## Git LFS

Artwork and editable image-source formats are registered in `.gitattributes`. Every contributor must install Git LFS and run this once before working in the repository:

```powershell
git lfs install
```

After cloning, verify that artwork was downloaded rather than left as pointer files:

```powershell
git lfs pull
git lfs ls-files
```

Do not serve a public website directly from Git LFS. It is the development copy, not the public image host.

## R2 Buckets

Create two Cloudflare R2 buckets:

- `mythcards-master`: private originals, approved masters, print files, packaging, and archived variants.
- `mythcards-public`: approved, optimized website images that may be served through an asset domain.

Use immutable versioned filenames. Never replace an approved file in place.

```text
mythcards/
  russian/
    closed-city/
      characters/
      events/
      relics/
    far-north/
    winter-front/
  atlantis/
    flood-survivors/
  shared/
    card-backs/
    logos/
    templates/
  production/
    tarot-deck-v1/
      print/
      web/
      packaging/
```

Example asset versions:

```text
irina-sokolova/source-v001.png
irina-sokolova/source-v002.png
irina-sokolova/approved-v001.png
irina-sokolova/print-v001.png
irina-sokolova/web-v001.webp
```

## Uploading To R2

The helper at `tools/upload_assets_to_r2.ps1` copies files with `rclone`. It does not delete remote objects. Configure an S3-compatible `rclone` remote for Cloudflare R2, then run:

```powershell
.\tools\upload_assets_to_r2.ps1 -RemoteName mythcards-r2 -BucketName mythcards-master
```

Upload website exports separately to the public bucket:

```powershell
.\tools\upload_assets_to_r2.ps1 -RemoteName mythcards-r2 -BucketName mythcards-public -SourcePath outputs\web -DestinationPrefix production/tarot-deck-v1/web
```

Keep R2 access keys in the local credential manager or `rclone` configuration. Never commit credentials, account IDs, bucket tokens, or `.env` files containing secrets.

## Asset Lifecycle

1. Save a new working image with a versioned filename.
2. Review and approve it before changing a card mapping.
3. Commit the approved development asset and mapping together through Git LFS.
4. Copy the full-resolution master to `mythcards-master`.
5. Export print and web derivatives without modifying the master.
6. Copy optimized website derivatives to `mythcards-public`.
7. Retain superseded approved versions for provenance instead of overwriting them.
