#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container (paths are /workspace/...).
# Downloads Mistral-Small-3.2-24B-Instruct-2506 (dense model, Q4_K_M quant,
# ~14GB) from bartowski's GGUF repo into
# /workspace/models/mistralai_Mistral-Small-3.2-24B-Instruct-2506-GGUF
set -euo pipefail

pip install -q -U huggingface_hub hf_transfer

python3 /workspace/scripts/download_model.py \
  --repo bartowski/mistralai_Mistral-Small-3.2-24B-Instruct-2506-GGUF \
  --pattern "*2506-Q4_K_M.gguf"
