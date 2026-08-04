#!/bin/bash
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/Qwen_Qwen3-14B-GGUF/Qwen_Qwen3-14B-Q6_K.gguf \
  --device ROCm0 \
  -c 16384 \
  --cache-type-k f16 --cache-type-v f16 \
  --jinja \
  --host 0.0.0.0 --port 41223
