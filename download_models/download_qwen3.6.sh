#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container (paths are /workspace/...).
# Downloads the Qwen3.6-35B-A3B MoE model (Q4_K_M quant, ~22GB, single file)
# from bartowski's GGUF repo into /workspace/models/Qwen_Qwen3.6-35B-A3B-GGUF
#
# Why 35B-A3B and not the 27B dense model: A3B only activates ~3B params/token,
# so with --cpu-moe (see startQ3.6-35B-A3B-gguf.sh) the expert weights can live
# in system RAM and only the small non-expert path + KV cache need to fit in
# 16GB VRAM. The 27B dense model would need ~all of its weights on the GPU.
set -euo pipefail

pip install -q -U huggingface_hub hf_transfer

python3 /workspace/scripts/download_model.py \
  --repo bartowski/Qwen_Qwen3.6-35B-A3B-GGUF \
  --file Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf
