#!/usr/bin/env python3
"""
Download a model (or specific quant files) from Hugging Face into /workspace/models/<name>.

Examples:
  python download_model.py --repo bartowski/Qwen3-14B-GGUF --pattern "*Q6_K*"
  python download_model.py --repo bartowski/Qwen3-14B-GGUF --file Qwen3-14B-Q6_K.gguf
"""
import argparse
import os
import sys
from pathlib import Path

try:
    from huggingface_hub import snapshot_download, hf_hub_download
except ImportError:
    sys.exit("huggingface_hub not installed. Run: pip install -U huggingface_hub hf_transfer")

MODELS_ROOT = Path("/workspace/models")


def main():
    parser = argparse.ArgumentParser(description="Download a model/GGUF from Hugging Face")
    parser.add_argument("--repo", required=True, help="HF repo id, e.g. bartowski/Qwen3-14B-GGUF")
    parser.add_argument("--file", help="Exact single filename to download")
    parser.add_argument("--pattern", help="Glob pattern to match one or more files, e.g. '*Q6_K*' (handles sharded ggufs too)")
    parser.add_argument("--revision", default="main", help="Branch/tag/commit (default: main)")
    parser.add_argument("--name", help="Subfolder name under /workspace/models (default: derived from repo)")
    parser.add_argument("--token", help="HF token for gated/private repos (or set HF_TOKEN env var)")
    args = parser.parse_args()

    if not args.file and not args.pattern:
        parser.error("Provide either --file (exact filename) or --pattern (glob match)")

    folder_name = args.name or args.repo.split("/")[-1]
    target_dir = MODELS_ROOT / folder_name
    target_dir.mkdir(parents=True, exist_ok=True)

    os.environ.setdefault("HF_HUB_ENABLE_HF_TRANSFER", "1")  # faster parallel chunks, needs hf_transfer pkg
    token = args.token or os.environ.get("HF_TOKEN")

    print(f"Repo:   {args.repo}")
    print(f"Target: {target_dir}")

    if args.file:
        path = hf_hub_download(
            repo_id=args.repo,
            filename=args.file,
            revision=args.revision,
            local_dir=target_dir,
            token=token,
        )
        print(f"Downloaded: {path}")
    else:
        snapshot_download(
            repo_id=args.repo,
            revision=args.revision,
            local_dir=target_dir,
            allow_patterns=[args.pattern],
            token=token,
        )

    print("\nFiles in target directory:")
    for f in sorted(target_dir.rglob("*")):
        if f.is_file():
            size_gb = f.stat().st_size / (1024**3)
            print(f"  {f.relative_to(target_dir)}  ({size_gb:.2f} GB)")


if __name__ == "__main__":
    main()
