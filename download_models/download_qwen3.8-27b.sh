#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container (paths are /workspace/...).
# Downloads Qwen3.8-27B (dense, Q3_K_M quant, ~13.4GB, single file) from
# bartowski's GGUF repo into /workspace/models/Qwen3.8-27B-GGUF
#
# Dense model (not MoE) with a hybrid Gated-DeltaNet/attention layout --
# tagged architecture "qwen35" in its own GGUF metadata, i.e. it reuses
# Qwen3.5-dense's architecture, which this box's current llama.cpp build
# already implements (src/models/qwen35.cpp). No --cpu-moe trick needed
# or possible here; the whole model goes on the GPU.
#
# Q3_K_M picked over IQ4_XS (15.48GB, barely fits with ~no context left)
# so there's VRAM headroom for a real context window -- see
# startQ3.8-27B-gguf.sh for the context-size math.
set -euo pipefail

pip install -q -U huggingface_hub hf_transfer

python3 /workspace/scripts/download_models/download_model.py \
  --repo bartowski/Qwen3.8-27B-GGUF \
  --file Qwen3.8-27B-Q3_K_M.gguf
