#!/bin/bash
# Run INSIDE the rocm-mi50-714v5 container (paths are /workspace/...).
# Downloads GLM-4.7-Flash (Q4_K_M quant, ~18.5GB, single file) from
# bartowski's GGUF repo into /workspace/models/zai-org_GLM-4.7-Flash-GGUF
#
# GLM-4.7-Flash: Zhipu/Z.ai's Jan 2026 release, 30B-A3B MoE (~3B active
# params/token), MIT license, 128k context. Picked over the newer/bigger
# GLM-4.6 (357B), GLM-5 (754B) and GLM-5.3-Flash (320B) flagships because
# those need 150-700GB just to hold their weights -- they cannot fit this
# machine's 16GB VRAM + ~31GB system RAM at any quant level. GLM-4.7-Flash
# is the newest GLM release that actually does.
set -euo pipefail

pip install -q -U huggingface_hub hf_transfer

python3 /workspace/scripts/download_model.py \
  --repo bartowski/zai-org_GLM-4.7-Flash-GGUF \
  --file zai-org_GLM-4.7-Flash-Q4_K_M.gguf
