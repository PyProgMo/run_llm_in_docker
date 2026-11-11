#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container.
# One-time build of stable-diffusion.cpp (leejet/stable-diffusion.cpp) with
# the HIP/gfx906 backend, for local image generation (FLUX.2-klein-4B etc).
# This is a separate engine from llama.cpp -- same ggml/HIP foundation, but
# its own repo and its own build.
#
# Flags mirror llama.cpp's known-working gfx906 build exactly (same
# compiler, same AMDGPU_TARGETS, same CMAKE_PREFIX_PATH into the rocm-venv
# devel package) -- see /workspace/llama.cpp/build/CMakeCache.txt.
set -euo pipefail

cd /workspace/stable-diffusion.cpp

ROCM_DEVEL=/opt/rocm-venv/lib/python3.12/site-packages/_rocm_sdk_devel

cmake -S . -B build \
  -DSD_HIPBLAS=ON \
  -DGGML_HIP_MMQ_MFMA=ON \
  -DAMDGPU_TARGETS=gfx906 \
  -DCMAKE_HIP_ARCHITECTURES=gfx906 \
  -DCMAKE_HIP_PLATFORM=amd \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$ROCM_DEVEL/lib/cmake" \
  -DCMAKE_HIP_COMPILER="$ROCM_DEVEL/lib/llvm/bin/clang++"

cmake --build build -j"$(nproc)"

echo "Built: /workspace/stable-diffusion.cpp/build/bin/sd-cli and sd-server"
