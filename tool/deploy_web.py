#!/usr/bin/env python3
"""Deploy Flutter WASM web build to S3 and invalidate CloudFront.

This script uploads a Flutter WASM web build (from example/build/web/) to S3
with appropriate Cache-Control and Content-Type headers, updates the CloudFront
distribution config for SPA error routing (optional), and invalidates the
distribution cache.

Note: This script only uploads and invalidates; it never deletes old content.
The bucket will grow over time as content-hashed assets accumulate. Consider
setting up an S3 lifecycle policy to prune old objects, or run manual cleanup
when needed.

Configuration is read from environment variables:
  DEPLOY_BUCKET (required): Target S3 bucket name
  DEPLOY_DISTRIBUTION_ID (required): CloudFront distribution ID to invalidate
  AWS_REGION (required): AWS region for the boto3 clients
  DEPLOY_BUILD_DIR (optional, default: example/build/web): Build output directory
  DEPLOY_ENSURE_SPA_FALLBACK (optional, default: true): Set to false to skip SPA fallback
  DEPLOY_UPLOAD_SYMBOLS (optional, default: false): Set to true to upload .js.symbols
"""

import hashlib
import logging
import mimetypes
import os
import re
import sys
import time
from pathlib import Path
from typing import Dict, Optional, Tuple

import boto3


logger = logging.getLogger(__name__)


# Cache control strategy constants
NO_CACHE_FILES = {'index.html', 'flutter.js', 'flutter_bootstrap.js', 'manifest.json', 'version.json'}
IMMUTABLE_EXTENSIONS = ('.wasm', '.js.symbols')
HASHABLE_ENTRY_FILES = ('main.dart.wasm', 'main.dart.mjs')
IMMUTABLE_FILES = {'canvaskit.js', 'skwasm.js', 'skwasm_heavy.js', 'wimp.js'}


def get_cache_control(relative_path: str, renames: Optional[Dict[str, str]] = None) -> str:
  """Determine Cache-Control header for a build artifact.

  Applies the following strategy:
  - No-cache files (index.html, etc.) always get 'no-cache'
  - Content-hashed files (from hash_entry_files) are immutable by definition
  - CanvasKit and certain immutable files get 'max-age=31536000, immutable'
  - Assets get 24-hour cache; fallback JS gets 1-hour cache
  - Everything else defaults to 'no-cache'

  Args:
    relative_path: Path relative to build root (e.g., 'canvaskit/canvaskit.js').
    renames: Optional dict mapping original filename to hashed filename.
             Any file in renames.values() is treated as content-addressed.

  Returns:
    Cache-Control header value suitable for S3 put_object.
  """
  if renames is None:
    renames = {}

  filename = relative_path.split('/')[-1]

  # No-cache files (always fresh)
  if filename in NO_CACHE_FILES:
    return 'no-cache'

  # Content-hashed files from hash_entry_files() are immutable by definition.
  # This must be checked before extension matching so main.dart.abc123.mjs
  # (hashed .mjs) does not fall through to the no-cache default.
  if filename in renames.values():
    return 'max-age=31536000, immutable'

  # Immutable by extension
  if any(relative_path.endswith(ext) for ext in IMMUTABLE_EXTENSIONS):
    return 'max-age=31536000, immutable'

  # Immutable canvaskit files
  if relative_path.startswith('canvaskit/'):
    return 'max-age=31536000, immutable'

  # Immutable by name
  if filename in IMMUTABLE_FILES:
    return 'max-age=31536000, immutable'

  # Asset files: 24-hour cache
  if relative_path.startswith('assets/'):
    return 'max-age=86400'

  # JS fallback: 1-hour cache
  if filename == 'main.dart.js':
    return 'max-age=3600'

  # Default: no cache
  return 'no-cache'


def guess_mime(key: str) -> str:
  """Guess MIME type for an S3 object key.

  Applies specific overrides for common web assets, then falls back to
  Python's mimetypes module, then application/octet-stream.

  Args:
    key: Object key (filename or path).

  Returns:
    MIME type string.
  """
  if key.endswith('.mjs'):
    return 'text/javascript'
  if key.endswith('.lottie'):
    return 'application/lottie+zip'
  if key.endswith('.wasm'):
    return 'application/wasm'
  if key.endswith('apple-app-site-association'):
    return 'application/json'
  if key.endswith('assetlinks.json'):
    return 'application/json'
  if key.endswith('webauthn'):
    return 'application/json'

  guessed, _ = mimetypes.guess_type(key)
  if guessed:
    return guessed

  return 'application/octet-stream'


def hash_entry_files(build_dir: Path) -> Dict[str, str]:
  """Rename hashable entry files to content-addressed paths.

  Computes SHA256 of main.dart.wasm and main.dart.mjs, renames them with
  the first 12 hex chars of the digest appended before the extension.
  For example: main.dart.wasm -> main.dart.abc123def456.wasm

  Args:
    build_dir: Build output directory (e.g., example/build/web).

  Returns:
    Dict mapping original filename (e.g., 'main.dart.wasm') to hashed
    filename (e.g., 'main.dart.abc123def456.wasm').

  Raises:
    FileNotFoundError: If a hashable entry file is missing.
  """
  renames = {}

  for entry_file in HASHABLE_ENTRY_FILES:
    src = build_dir / entry_file
    if not src.exists():
      raise FileNotFoundError(f"Entry file missing: {src}")

    content = src.read_bytes()
    digest = hashlib.sha256(content).hexdigest()[:12]

    # main.dart.wasm -> main.dart.<digest>.wasm
    parts = entry_file.rsplit('.', 1)
    hashed_name = f"{parts[0]}.{digest}.{parts[1]}"

    dst = build_dir / hashed_name
    src.rename(dst)

    renames[entry_file] = hashed_name
    logger.info(f"Renamed {entry_file} -> {hashed_name}")

  return renames


def rewrite_build_config(build_dir: Path, renames: Dict[str, str]) -> None:
  """Update build config files with hashed filenames.

  Scans index.html and flutter_bootstrap.js (and other candidate files) for
  references to the original entry file names, replacing them with hashed
  versions. Both single and double quotes are matched, with or without a
  leading slash.

  CRITICAL: If any rename was performed but zero references were found and
  rewritten for that name, the script hard-fails. A silent miss here would
  result in 404 errors and a blank page despite a successful deploy report.

  Args:
    build_dir: Build output directory.
    renames: Mapping from original to hashed filenames.

  Raises:
    FileNotFoundError: If no candidate config files exist.
    RuntimeError: If a filename was renamed but no references were rewritten.
  """
  # Candidate config files in search order
  candidate_files = ['flutter_bootstrap.js', 'index.html']
  found_any = False
  rewrite_counts = {}  # orig -> count of rewrites across all files

  for candidate_name in candidate_files:
    candidate_path = build_dir / candidate_name
    if not candidate_path.exists():
      continue

    found_any = True
    content = candidate_path.read_text(encoding='utf-8')
    original = content

    for orig, hashed in renames.items():
      # Match quoted paths: "main.dart.wasm" or 'main.dart.wasm' or "/main.dart.wasm"
      pattern = f'["\']/?{re.escape(orig)}["\']'
      replacement = f'"{hashed}"'
      updated_content, count = re.subn(pattern, replacement, content)

      if count > 0:
        content = updated_content
        rewrite_counts[orig] = rewrite_counts.get(orig, 0) + count
        logger.info(f"Rewrote {orig} -> {hashed} in {candidate_name} ({count} occurrences)")

    # Only write if changed
    if content != original:
      candidate_path.write_text(content, encoding='utf-8')

  if not found_any:
    raise FileNotFoundError(
      f"No config files found in {build_dir}. Expected index.html or flutter_bootstrap.js"
    )

  # HARD-FAIL if any rename was not applied anywhere
  for orig, hashed in renames.items():
    if orig not in rewrite_counts:
      raise RuntimeError(
        f"CRITICAL: Renamed {orig} -> {hashed}, but no references were found "
        f"in index.html or flutter_bootstrap.js. The deployed site would 404 on its "
        f"entrypoint. Check the build config structure."
      )


def ensure_spa_error_responses(distribution_id: str, region: str) -> None:
  """Configure CloudFront distribution for single-page app error routing.

  Sets up error responses so 404/403 errors return index.html with
  status 200, allowing the app to handle routing. This requires the
  cloudfront:UpdateDistribution permission and is gated by the
  DEPLOY_ENSURE_SPA_FALLBACK environment variable.

  Args:
    distribution_id: CloudFront distribution ID.
    region: AWS region.

  Raises:
    RuntimeError: If distribution config fetch or update fails.
  """
  cf = boto3.client('cloudfront', region_name=region)

  try:
    resp = cf.get_distribution_config(Id=distribution_id)
    config = resp['DistributionConfig']
    etag = resp['ETag']
  except Exception as e:
    raise RuntimeError(f"Failed to get CloudFront distribution config: {e}") from e

  # Add or update error responses
  if 'CustomErrorResponses' not in config:
    config['CustomErrorResponses'] = []

  error_codes = {404, 403}
  existing = {item['ErrorCode'] for item in config['CustomErrorResponses']}
  missing = error_codes - existing

  for code in missing:
    config['CustomErrorResponses'].append({
      'ErrorCode': code,
      'ResponsePagePath': '/index.html',
      'ResponseCode': '200',
      'ErrorCachingMinTTL': 0,
    })

  try:
    cf.update_distribution(
      DistributionConfig=config,
      Id=distribution_id,
      IfMatch=etag,
    )
    logger.info(f"Updated CloudFront distribution {distribution_id} with SPA error responses")
  except Exception as e:
    raise RuntimeError(f"Failed to update CloudFront distribution: {e}") from e


def invalidate_distribution(distribution_id: str, region: str) -> str:
  """Invalidate all paths in a CloudFront distribution.

  Creates a wildcard invalidation /* to cache-bust the entire distribution.

  Args:
    distribution_id: CloudFront distribution ID.
    region: AWS region.

  Returns:
    Invalidation ID for tracking.

  Raises:
    RuntimeError: If invalidation creation fails.
  """
  cf = boto3.client('cloudfront', region_name=region)

  try:
    resp = cf.create_invalidation(
      DistributionId=distribution_id,
      InvalidationBatch={
        'Paths': {
          'Quantity': 1,
          'Items': ['/*'],
        },
        'CallerReference': str(int(time.time() * 1000)),
      },
    )
    invalidation_id = resp['Invalidation']['Id']
    logger.info(f"Invalidation created: {invalidation_id}")
    return invalidation_id
  except Exception as e:
    raise RuntimeError(f"Failed to invalidate distribution: {e}") from e


def upload_build(
  build_dir: Path,
  bucket: str,
  region: str,
  renames: Dict[str, str],
  upload_symbols: bool = False,
) -> Tuple[int, int, int]:
  """Upload build artifacts to S3.

  Recursively walks the build directory, determines MIME type and cache
  control for each file, and uploads via put_object. Only the ContentType
  parameter is passed to set the real Content-Type header; the Metadata
  parameter is omitted as it only creates a useless x-amz-meta-content-type.

  By default, .js.symbols files are skipped (they are debug artifacts never
  fetched by the browser and total ~8.2 MB). Set upload_symbols=True to
  include them.

  Args:
    build_dir: Build output directory.
    bucket: Target S3 bucket name.
    region: AWS region.
    renames: Mapping from original to hashed filenames (for cache-control logic).
    upload_symbols: Whether to upload .js.symbols debug files (default: False).

  Returns:
    Tuple of (file_count, total_bytes, skipped_symbol_bytes) for the upload.

  Raises:
    RuntimeError: If any upload fails.
  """
  s3 = boto3.client('s3', region_name=region)

  file_count = 0
  total_bytes = 0
  skipped_symbol_bytes = 0

  for local_path in sorted(build_dir.rglob('*')):
    if not local_path.is_file():
      continue

    relative_path = local_path.relative_to(build_dir).as_posix()

    # Skip symbol files unless explicitly enabled
    if relative_path.endswith('.js.symbols'):
      if not upload_symbols:
        skipped_symbol_bytes += local_path.stat().st_size
        continue

    content_type = guess_mime(relative_path)
    cache_control = get_cache_control(relative_path, renames)

    try:
      body = local_path.read_bytes()
      total_bytes += len(body)

      s3.put_object(
        Bucket=bucket,
        Key=relative_path,
        Body=body,
        ContentType=content_type,
        CacheControl=cache_control,
      )

      logger.info(
        f"Uploaded {relative_path} "
        f"(type={content_type}, cache={cache_control})"
      )
      file_count += 1
    except Exception as e:
      raise RuntimeError(
        f"Failed to upload {relative_path}: {e}"
      ) from e

  if skipped_symbol_bytes > 0:
    logger.info(f"Skipped .js.symbols files: {skipped_symbol_bytes} bytes")

  return file_count, total_bytes, skipped_symbol_bytes


def main() -> None:
  """Main entry point for deployment.

  Reads configuration from environment variables, validates required inputs,
  executes the deployment workflow (hash, rewrite, upload, invalidate),
  and exits with status 0 on success or non-zero on any error.
  """
  logging.basicConfig(
    level=logging.INFO,
    format='%(levelname)s: %(message)s',
  )

  # Read environment configuration
  bucket = os.environ.get('DEPLOY_BUCKET')
  distribution_id = os.environ.get('DEPLOY_DISTRIBUTION_ID')
  region = os.environ.get('AWS_REGION')
  build_dir_str = os.environ.get('DEPLOY_BUILD_DIR', 'example/build/web')
  ensure_spa = os.environ.get('DEPLOY_ENSURE_SPA_FALLBACK', 'true').lower() not in ('false', '0', 'no')
  upload_symbols = os.environ.get('DEPLOY_UPLOAD_SYMBOLS', 'false').lower() not in ('false', '0', 'no')

  # Validate required configuration
  if not bucket:
    sys.exit("ERROR: DEPLOY_BUCKET environment variable is required")
  if not distribution_id:
    sys.exit("ERROR: DEPLOY_DISTRIBUTION_ID environment variable is required")
  if not region:
    sys.exit("ERROR: AWS_REGION environment variable is required")

  build_dir = Path(build_dir_str).resolve()
  if not build_dir.is_dir():
    sys.exit(f"ERROR: Build directory not found: {build_dir}")

  # Verify S3 bucket is reachable before proceeding
  s3 = boto3.client('s3', region_name=region)
  try:
    s3.head_bucket(Bucket=bucket)
    logger.info(f"Verified S3 bucket: {bucket}")
  except Exception as e:
    sys.exit(f"ERROR: Cannot reach S3 bucket {bucket}: {e}")

  # Execute deployment workflow
  try:
    renames = hash_entry_files(build_dir)
    rewrite_build_config(build_dir, renames)

    if ensure_spa:
      ensure_spa_error_responses(distribution_id, region)

    file_count, total_bytes, skipped_symbol_bytes = upload_build(
      build_dir, bucket, region, renames, upload_symbols=upload_symbols
    )

    invalidation_id = invalidate_distribution(distribution_id, region)

    logger.info(
      f"Deployment complete: {file_count} files, {total_bytes} bytes "
      f"(skipped {skipped_symbol_bytes} bytes of symbols), "
      f"invalidation {invalidation_id}"
    )
  except Exception as e:
    sys.exit(f"ERROR: Deployment failed: {e}")


if __name__ == '__main__':
  main()
