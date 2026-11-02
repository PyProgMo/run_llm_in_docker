#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container. Modified from
# startQ3.6-35B-A3B-gguf.sh for GLM-4.7-Flash (MoE, 30B-A3B).
#
# --cpu-moe keeps all MoE expert weights in system RAM and only the small
# shared/attention path + KV cache on the GPU, which is what makes the
# ~14GB Q3_K_M quant workable on a 16GB card. Same tuning knob as the
# Qwen3.6 script applies here: swap --cpu-moe for e.g. `-ncmoe 20` to push
# more experts onto the GPU if VRAM allows, checked via rocm-smi.
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/zai-org_GLM-4.7-Flash-GGUF/zai-org_GLM-4.7-Flash-Q3_K_M.gguf \
  --device ROCm0 \
  --gpu-layers all \
  --cpu-moe \
  -c 16384 \
  --cache-type-k f16 --cache-type-v f16 \
  --jinja \
  --host 0.0.0.0 --port 41223
