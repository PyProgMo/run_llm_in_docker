#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container.
# Qwen3.8-27B dense, Q3_K_M quant (13.4GB). Whole model fits on the MI50;
# no --cpu-moe/-ncmoe here since this is a dense model, not MoE.
#
# Context math: 16GB VRAM - 13.4GB weights leaves ~2.6GB for KV cache +
# compute buffers. Qwen3.8-27B's hybrid Gated-DeltaNet layout means only
# 16 of its 64 layers grow a real KV cache (the other 48 are constant-size
# recurrent state), at ~64KiB/token fp16, ~32KiB/token at q8_0. -c 32768
# with q8_0 cache below should land around ~1GB of cache, leaving a safe
# margin for compute buffers out of the ~2.6GB budget. If it loads with
# room to spare (check `rocm-smi --showmeminfo vram`), this can likely go
# higher (try 49152+) since it's nowhere near the IQ4_XS-style "no room
# left" case.
#
# Thinking mode defaults to reasoning_effort=xhigh in this model's chat
# template, which can burn through a lot of the context on its own on
# hard prompts -- pass "reasoning_effort": "low" or "medium" (or
# "enable_thinking": false) in your chat requests if 32K feels tight.
#
# Nobody seems to have reported this architecture on gfx906/ROCm yet --
# first real test of it on this card.
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/Qwen3.8-27B-GGUF/Qwen3.8-27B-Q3_K_M.gguf \
  --device ROCm0 \
  --gpu-layers all \
  --load-mode none \
  -c 32768 \
  --cache-type-k q8_0 --cache-type-v q8_0 \
  --jinja \
  --host 0.0.0.0 --port 41223
