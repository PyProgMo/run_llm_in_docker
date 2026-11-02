#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container. Same shape as
# startQ3.6-35B-A3B-gguf.sh, for GLM-4.7-Flash (30B-A3B MoE, ~3B
# active params/token).
#
# --cpu-moe keeps all MoE expert weights in system RAM and only the small
# shared/attention path + KV cache on the GPU. This box only has ~31GB RAM
# total (check `free -h` -- close other heavy processes first if the model
# fails to load), so if it doesn't fit, drop to a smaller quant (e.g.
# zai-org_GLM-4.7-Flash-Q4_K_S.gguf / IQ4_XS) via download_glm4.7flash.sh.
# If it loads with room to spare, swap --cpu-moe for e.g. `-ncmoe 20` to
# push more layers onto the GPU for more speed -- tune N with `rocm-smi`.
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/zai-org_GLM-4.7-Flash-GGUF/zai-org_GLM-4.7-Flash-Q4_K_M.gguf \
  --device ROCm0 \
  --gpu-layers all \
  --cpu-moe \
  -c 16384 \
  --cache-type-k f16 --cache-type-v f16 \
  --jinja \
  --host 0.0.0.0 --port 41223
