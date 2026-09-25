#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container. Modified from startQ3-14Bgguf.sh
# for Qwen3.6-35B-A3B (MoE, ~3B active params/token, 41 layers total).
#
# -ncmoe N keeps the first N layers' MoE experts on CPU RAM, the rest
# (41-N layers) on the MI50's VRAM. N=20 is a first trial (~half GPU,
# half CPU). Confirmed working: the previous run with ALL 41 layers on
# CPU (--cpu-moe) loaded fine, so moving layers onto the GPU only
# *reduces* RAM pressure -- there's no OOM risk in lowering N further.
# Tune it: after each restart, run `rocm-smi --showmeminfo vram` in the
# container -- if there's free VRAM left, lower N (more layers -> GPU);
# if it fails to load or OOMs, raise N back up.
#
# --no-mmap: the server warned that mmap + tensor overrides (-ncmoe)
# adds page-fault overhead for no benefit, since the CPU-resident
# tensors need a real copy anyway.
#
# --threads 8: pins CPU inference threads to the 2700X's 8 physical
# cores. This is compute-bound matmul work, so the 8 SMT sibling
# threads mostly just contend for the same core's execution units --
# try 6/8/12/16 and compare the server's reported tokens/sec if you
# want to double check on your box.
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/Qwen_Qwen3.6-35B-A3B-GGUF/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf \
  --device ROCm0 \
  --gpu-layers all \
  -ncmoe 20 \
  --no-mmap \
  --threads 8 \
  -c 16384 \
  --cache-type-k f16 --cache-type-v f16 \
  --jinja \
  --host 0.0.0.0 --port 41223
