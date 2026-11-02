#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container. Dense model, same layout as
# startQ3-14Bgguf.sh, but Q8_0 (~14GB) leaves little headroom on a 16GB
# card, so context is dropped to 8192 to keep the KV cache small. If you
# still hit an OOM, lower -c further or try --cache-type-k/v q8_0.
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/mistralai_Ministral-3-14B-Instruct-2512-GGUF/mistralai_Ministral-3-14B-Instruct-2512-Q8_0.gguf \
  --device ROCm0 \
  -c 8192 \
  --cache-type-k f16 --cache-type-v f16 \
  --jinja \
  --host 0.0.0.0 --port 41223
