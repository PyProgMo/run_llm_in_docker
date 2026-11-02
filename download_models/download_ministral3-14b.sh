#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container (paths are /workspace/...).
# Downloads Ministral-3-14B-Instruct-2512 (dense model) from bartowski's
# GGUF repo into /workspace/models/mistralai_Ministral-3-14B-Instruct-2512-GGUF
#
# Grabs both quants so you can pick at run time:
#   Q6_K  (~11GB) -> startMinistral3-14B-Q6-gguf.sh
#   Q8_0  (~14GB) -> startMinistral3-14B-Q8-gguf.sh
set -euo pipefail

pip install -q -U huggingface_hub hf_transfer

python3 /workspace/scripts/download_model.py \
  --repo bartowski/mistralai_Ministral-3-14B-Instruct-2512-GGUF \
  --pattern "*2512-Q6_K.gguf"

python3 /workspace/scripts/download_model.py \
  --repo bartowski/mistralai_Ministral-3-14B-Instruct-2512-GGUF \
  --pattern "*2512-Q8_0.gguf"
