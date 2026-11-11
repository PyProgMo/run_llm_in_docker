#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container (paths are /workspace/...).
# Downloads the 3 components FLUX.2-klein-4B needs (image gen + editing
# with reference images), picking the Q8_0/best-quality quant for both
# GGUF parts since the combined footprint (~8.75GB) leaves plenty of the
# 16GB card free -- no need to trade quality for VRAM here:
#   - diffusion model (GGUF, Q8_0, ~4.3GB)  <- leejet/FLUX.2-klein-4B-GGUF
#   - VAE (safetensors, ~168MB)             <- black-forest-labs/FLUX.2-klein-4B
#   - text encoder "llm" (GGUF, Q8_0, ~4.3GB) <- unsloth/Qwen3-4B-GGUF
#
# NOTE: black-forest-labs/FLUX.2-dev (the usual VAE source in sd.cpp's own
# docs) is a GATED repo -- it 401s without an accepted license + HF token.
# Sidestepped that entirely: FLUX.2-klein-4B's own repo ships the same VAE
# at vae/diffusion_pytorch_model.safetensors and is NOT gated, so no HF
# login/token is needed for this script to work.
#
# Requires scripts/build_sdcpp.sh to have been run first (builds sd-cli /
# sd-server) before start_models/startFlux2Klein4B-sdserver.sh can use these.
set -euo pipefail

pip install -q -U huggingface_hub hf_transfer

python3 /workspace/scripts/download_models/download_model.py \
  --repo leejet/FLUX.2-klein-4B-GGUF \
  --file flux-2-klein-4b-Q8_0.gguf \
  --name flux2-klein-4b

python3 /workspace/scripts/download_models/download_model.py \
  --repo black-forest-labs/FLUX.2-klein-4B \
  --file vae/diffusion_pytorch_model.safetensors \
  --name flux2-klein-4b

python3 /workspace/scripts/download_models/download_model.py \
  --repo unsloth/Qwen3-4B-GGUF \
  --file Qwen3-4B-Q8_0.gguf \
  --name flux2-klein-4b
