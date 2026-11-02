#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container. Dense model, same layout as
# startQ3-14Bgguf.sh -- Q6_K (~11GB) fits on the 16GB card with room for a
# full 16k f16 KV cache, no --cpu-moe needed.
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/mistralai_Ministral-3-14B-Instruct-2512-GGUF/mistralai_Ministral-3-14B-Instruct-2512-Q6_K.gguf \
  --device ROCm0 \
  -c 16384 \
  --cache-type-k f16 --cache-type-v f16 \
  --jinja \
  --host 0.0.0.0 --port 41223
