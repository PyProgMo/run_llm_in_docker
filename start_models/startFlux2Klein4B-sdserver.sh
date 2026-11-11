#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container.
# Serves FLUX.2-klein-4B via stable-diffusion.cpp's sd-server, which exposes
# OpenAI-compatible endpoints: POST /v1/images/generations and
# POST /v1/images/edits (the latter takes reference image(s) + a prompt --
# this is the "image editing and reference images" feature).
#
# No --device-style flag exists here (unlike llama.cpp's --device ROCm0) --
# with the HIP backend built in, it just uses the one GPU on the box.
# No --offload-to-cpu either: all 3 components fit in well under the 16GB
# card (~8.75GB total), so streaming weights from RAM would only add
# latency here for no VRAM benefit.
#
# Needs: scripts/build_sdcpp.sh run once first, and
# scripts/download_models/download_flux2-klein-4b.sh to have fetched the
# 3 model files referenced below.
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH="/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_libraries/lib:/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_core/lib:$LD_LIBRARY_PATH"

/workspace/stable-diffusion.cpp/build/bin/sd-server \
  --diffusion-model /workspace/models/flux2-klein-4b/flux-2-klein-4b-Q8_0.gguf \
  --vae /workspace/models/flux2-klein-4b/vae/diffusion_pytorch_model.safetensors \
  --llm /workspace/models/flux2-klein-4b/Qwen3-4B-Q8_0.gguf \
  --cfg-scale 1.0 \
  --steps 4 \
  --listen-ip 0.0.0.0 --listen-port 41224
