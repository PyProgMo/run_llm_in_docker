#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container. Modified from startQ3-14Bgguf.sh
# for Qwen3.6-35B-A3B (MoE, ~3B active params/token).
#
# --cpu-moe keeps all MoE expert weights in system RAM and only the small
# shared/attention path + KV cache on the GPU, which is what makes a ~22GB
# quant workable on a 16GB card. If it fits with room to spare, try swapping
# --cpu-moe for e.g. `-ncmoe 20` (keep only the first 20 layers' experts on
# CPU, rest on GPU) to push more of the model onto the GPU for more speed --
# raise/lower the number until it just fits, then use `rocm-smi` to check
# VRAM headroom.
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/Qwen_Qwen3.6-35B-A3B-GGUF/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf \
  --device ROCm0 \
  --gpu-layers all \
  --cpu-moe \
  -c 16384 \
  --cache-type-k f16 --cache-type-v f16 \
  --jinja \
  --host 0.0.0.0 --port 41223
