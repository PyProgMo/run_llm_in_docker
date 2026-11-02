#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container (paths are /workspace/...).
# Downloads GLM-4.7-Flash (30B-A3B MoE, Q3_K_M quant, ~14GB, single file)
# from bartowski's GGUF repo into /workspace/models/zai-org_GLM-4.7-Flash-GGUF
#
# MoE model, same reasoning as download_qwen3.6.sh: run with --cpu-moe (see
# startGLM4.7-Flash-gguf.sh) so the expert weights live in system RAM and
# only the small non-expert path + KV cache need to fit in 16GB VRAM.
set -euo pipefail

pip install -q -U huggingface_hub hf_transfer

python3 /workspace/scripts/download_model.py \
  --repo bartowski/zai-org_GLM-4.7-Flash-GGUF \
  --pattern "*Q3_K_M*"
