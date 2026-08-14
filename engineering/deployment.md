# Deployment: Showroom to S3 and CloudFront

## Overview

The layrz_ui example showroom is a Flutter web application compiled to **WebAssembly (WASM)** and deployed to Amazon S3, served globally via CloudFront CDN. The deployment workflow uses a Python script (`tool/deploy_web.py`) that handles per-file MIME types, content-hashing, cache-control headers, and SPA routing.

## What Gets Published

The workflow builds `example/` in release mode using `flutter build web --wasm --release`, targeting WebAssembly. The compiled output is uploaded to the S3 bucket with per-file cache headers and MIME type configuration. CloudFront sits in front of the bucket and serves the app to end users.

## When It Runs

The deployment workflow runs on every push to the `main` branch. It can also be triggered manually via **Actions → Deploy Showroom → Run workflow** in GitHub, which is useful while `main` is behind `development`.

## Secrets and Variables

Five configuration values are stored as **GitHub repository secrets** (not variables) and passed into the workflow via `secrets.*`:

| Name | Type | Purpose |
|------|------|---------|
| `UI_AWS_ACCESS_KEY` | Secret | IAM user access key ID |
| `UI_AWS_ACCESS_SECRET` | Secret | IAM user secret access key |
| `US_AWS_REGION` | Secret | AWS region for S3 and CloudFront (e.g., `us-east-1`) |
| `UI_AWS_S3_BUCKET` | Secret | S3 bucket name to receive the WASM build |
| `UI_AWS_CLOUDFRONT_DISTRIBUTION` | Secret | CloudFront distribution ID for cache invalidation |

All secrets are masked in workflow logs. **Because the bucket name and distribution ID are secrets (not repository variables), GitHub masks them as `***` in Actions logs.** They cannot be read back from the build log and must be verified in repository settings when debugging deployment issues.

### Note on Region Secret Naming

The region secret uses the prefix `US_AWS_REGION` while the other four use `UI_AWS_*`. This appears to be a typo (`US_` instead of `UI_`). It is referenced exactly as created; renaming it requires updating both the secret in repository settings and the workflow reference in the same change.

## IAM Policy

The IAM user used for deployment must have the following policy attached. This policy is **tighter than an `aws s3 sync` workflow** because it uses `put_object` exclusively with no delete or multipart permissions.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HeadBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::BUCKET_NAME"
    },
    {
      "Sid": "UploadSiteObjects",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::BUCKET_NAME/*"
    },
    {
      "Sid": "InvalidateCdn",
      "Effect": "Allow",
      "Action": "cloudfront:CreateInvalidation",
      "Resource": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
    },
    {
      "Sid": "ConfigureSpaFallback",
      "Effect": "Allow",
      "Action": [
        "cloudfront:GetDistributionConfig",
        "cloudfront:UpdateDistribution"
      ],
      "Resource": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
    }
  ]
}
```

Replace the following placeholders:
- `BUCKET_NAME` — the S3 bucket name (no `s3://` prefix)
- `ACCOUNT_ID` — your 12-digit AWS account ID
- `DISTRIBUTION_ID` — your CloudFront distribution ID

## Why Each Permission Exists

### Statement 1: HeadBucket (`s3:ListBucket`)

- **`s3:ListBucket`** — The deploy script checks bucket existence with `head_bucket()`, which requires `s3:ListBucket` on the **bucket** ARN (not `bucket/*`). This is the most common source of `AccessDenied` errors: confusing the bucket-level resource ARN with the object-level ARN.
- **Resource**: `arn:aws:s3:::BUCKET_NAME` (no `/*` suffix)

### Statement 2: UploadSiteObjects (`s3:PutObject`)

- **`s3:PutObject`** — Every file uploaded to the bucket requires this permission. The script uses only `put_object()` with no deletes, so no `s3:DeleteObject`, `s3:GetObject`, `s3:AbortMultipartUpload`, or `s3:ListMultipartUploadParts` are needed.
- **Consequence**: Old content-hashed assets are deliberately left in place. A client mid-load can still fetch them if a browser cached an old `index.html`. The bucket grows over time and should use an S3 lifecycle rule or periodic manual pruning.
- **Resource**: `arn:aws:s3:::BUCKET_NAME/*` (with `/*` suffix)

### Statement 3: InvalidateCdn (`cloudfront:CreateInvalidation`)

- **`cloudfront:CreateInvalidation`** — After uploading new content, the script triggers a cache invalidation to purge CloudFront's edge caches and ensure users receive the latest version immediately.
- **CloudFront ARN format**: `arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID` — **note the empty region segment (two colons `::`, not three)**. Getting this wrong yields `AccessDenied` that looks like a policy problem rather than a typo.

### Statement 4: ConfigureSpaFallback (`cloudfront:GetDistributionConfig`, `cloudfront:UpdateDistribution`)

- **`cloudfront:GetDistributionConfig`** — Read the distribution's current configuration (optional, set `DEPLOY_ENSURE_SPA_FALLBACK=false` to skip).
- **`cloudfront:UpdateDistribution`** — Write a modified distribution config back to enable 404/403 → `/index.html` custom error responses. This is a **broad grant** that allows rewriting the entire distribution config, including origins. If the SPA fallback is configured by hand once in the AWS console, set `DEPLOY_ENSURE_SPA_FALLBACK=false` in the workflow environment and delete this entire statement to minimize CI blast radius.

## Caching Model

The script applies per-file cache headers according to this table:

| File(s) | Cache Header | Rationale |
|---------|--------------|-----------|
| `index.html`, `flutter.js`, `flutter_bootstrap.js`, `manifest.json`, `version.json` | `no-cache` | Entry points; must be revalidated on every visit to detect app updates. |
| `main.dart.wasm`, `main.dart.mjs` | `max-age=31536000, immutable` | Content-hashed at deploy time; renamed to include a 12-character SHA-256 suffix. Safe for one-year immutable caching because the hash changes if content changes. |
| Files ending `.wasm` (except main), canvaskit files, `skwasm.js`, `skwasm_heavy.js`, `wimp.js` | `max-age=31536000, immutable` | Framework and engine assets; immutable by build ID. |
| `assets/` directory | `max-age=86400` | App assets; cache for 24 hours. |
| `main.dart.js` | `max-age=3600` | JavaScript fallback renderer; cache for 1 hour. NOT content-hashed; kept at a stable filename so a one-hour cache works for both the renderer and the bootstrap. |
| Everything else | `no-cache` | Conservative default; updated assets revalidate on next visit. |

### Content-Hashing Strategy

`main.dart.wasm` and `main.dart.mjs` are **renamed at deploy time** to include a 12-character SHA-256 hash of their content (e.g., `main.dart.a1b2c3d4e5f6.wasm`, `main.dart.a1b2c3d4e5f6.mjs`), and **the references in `flutter_bootstrap.js` are rewritten to match** (the script also checks `index.html` for older Flutter templates, though current versions do not use it). 

The `_flutter.buildConfig` object in `flutter_bootstrap.js` holds `mainWasmPath`, `jsSupportRuntimePath`, and `mainJsPath`; the rewrite updates the hashed paths. The `mainJsPath` is deliberately left unhashed — `main.dart.js` keeps its `max-age=3600` rule instead — so the bootstrap can cache the fallback renderer on a one-hour cycle.

This decouples the long-lived immutable header from the actual file lifetime: users fetch the content once and cache it forever, but a new hash means new downloads. **This is the highest-risk step in the deploy**: if the rewrite silently missed, the bootstrap would fetch a filename that no longer exists and the site would serve a blank page. The script hard-fails rather than warning when a rename produces no rewrite to catch this immediately.

## MIME Types

The script sets content types explicitly:

- **`.wasm` → `application/wasm`** — Critical. An incorrect `Content-Type` on a `.wasm` file causes `WebAssembly.instantiateStreaming` to reject it, and the app refuses to boot.
- **`.mjs` → `text/javascript`** — ES modules; Python's `mimetypes` does not reliably recognize this extension.

All other types are derived from standard `mimetypes` library defaults (e.g., `.js` → `text/javascript`, `.json` → `application/json`).

## Optional Configuration: Symbol Upload

The WASM build emits six `*.js.symbols` debug map files totalling **8.2 MB** (`canvaskit.js.symbols`, `skwasm.js.symbols`, `skwasm_heavy.js.symbols`, `wimp.js.symbols`, `chromium/canvaskit.js.symbols`, `webparagraph/canvaskit.js.symbols`). These exist solely to deobfuscate production stack traces because the WASM build defaults to `--strip-wasm`. **The browser never requests them.**

By default, the deploy script skips uploading these files (`DEPLOY_UPLOAD_SYMBOLS=false`), which saves 8.2 MB of storage and transfer per deploy and avoids publishing internal symbol names.

Set `DEPLOY_UPLOAD_SYMBOLS=true` in the workflow environment **only if** someone needs to symbolise a production stack trace from a deployed bundle. In that case, the symbols are reuploaded alongside the app files and cached with the same immutable headers as other engine assets. Alternatively, the same symbol files remain in the CI build output and can be used to symbolise traces without uploading them to production.

## Prerequisite: Cross-Origin Isolation

Flutter's WASM renderer (skwasm) uses `SharedArrayBuffer` for multi-threaded execution, which requires the site to be **cross-origin isolated**:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

**S3 static hosting cannot add response headers**, so these headers must be attached via a **CloudFront Response Headers Policy** configured once in the AWS console and attached to the distribution's behaviour rule. This is outside both the workflow and the IAM policy.

Without cross-origin isolation, the app boots but drops to a **single-threaded or JavaScript fallback path** (`main.dart.js`), resulting in performance and rendering fidelity loss rather than an outage. The fallback exists precisely for this scenario.

## SPA Fallback

Single Page Applications (SPAs) need a catch-all routing rule: when a user navigates to a deep link (e.g., `/profile/123`) or refreshes a non-root path, the web server must return `index.html` at that path, not a 404.

**S3 static hosting cannot implement this routing**, but CloudFront can via custom error responses:

- When S3 returns HTTP **404** or **403**, rewrite the response to return `/index.html` with an HTTP **200** status.
- Set `ErrorCachingMinTTL: 0` so custom error responses are never cached by CloudFront or browsers — on the next refresh, the route is re-evaluated.

The script enables this routing when `DEPLOY_ENSURE_SPA_FALLBACK=true` (the default) by rewriting the distribution config. If you prefer to configure it by hand once, set `DEPLOY_ENSURE_SPA_FALLBACK=false` and remove the `ConfigureSpaFallback` statement from the IAM policy.

## S3 Bucket Configuration

### Bucket Policy (Allow CloudFront Access Only)

The S3 bucket should be **private** with no public access. CloudFront reaches the bucket via an **Origin Access Control (OAC)**, which allows the distribution to read from the bucket without public permissions.

A typical bucket policy looks like:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::BUCKET_NAME/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
        }
      }
    }
  ]
}
```

This policy grants CloudFront permission to read objects from the bucket and denies direct public access.

### ACLs

The S3 bucket should use **"Bucket owner enforced"** for ACL control, which disables ACLs entirely. The deploy script does not use or modify ACLs. Public read access comes from the bucket policy and Origin Access Control, not object ACLs.

## Monitoring and Troubleshooting

### Workflow Logs

The deployment workflow prints:
- Flutter version
- Deploy script output (every file with its resolved content type and cache-control)
- CloudFront invalidation ID
- Deployed size (`du -sh example/build/web`)

The per-file logging from the deploy script is the forensic record when a deployment misbehaves — check it to verify MIME types, cache headers, and content-hashing.

### Common Failures

- **`AccessDenied` on `s3:ListBucket`** — IAM user is missing `s3:ListBucket` on the bucket ARN (not `bucket/*`). Verify the policy attached to the user.
- **`NoSuchBucket`** — Bucket name in `UI_AWS_S3_BUCKET` is wrong, or the bucket does not exist in the configured region.
- **`AccessDenied` on `CreateInvalidation`** — Check the CloudFront ARN in the policy. A common mistake is using a non-empty region: `arn:aws:cloudfront:us-east-1::...` is wrong; it must be `arn:aws:cloudfront::...` (two colons, empty region).
- **App boots but single-threaded or all-JavaScript** — Cross-origin isolation headers are not set. Check the CloudFront Response Headers Policy in the distribution's behaviours.
- **Deep links or refreshes return 404** — SPA fallback is not configured. Either set `DEPLOY_ENSURE_SPA_FALLBACK=true` and re-deploy, or manually configure the custom error responses in the CloudFront distribution.
