"""
Download Soofi-S-Isar-Preview (GGUF, quantized) for llama.cpp.

Soofi-S is a ~30B hybrid Mamba-2/MoE model (128 routed experts + 1 shared,
~3.5B active params/token) from a German research consortium (SOOFI:
Sovereign Open Source Foundation Models). It's distributed as pre-quantized
GGUF files, so this pulls a single .gguf straight from the Hub instead of
going through AutoModelForCausalLM/AutoTokenizer -- that path is for
full-precision transformers checkpoints, not GGUF.

Before running:
1. Accept the gated model's terms while logged in on the HF page:
   https://huggingface.co/Soofi-Project/Soofi-S-Isar-Preview-GGUF
2. Authenticate locally, e.g.:
     huggingface-cli login
   (or set the HF_TOKEN environment variable)

VRAM note (MI50, 16GB HBM2):
No available quant fits fully in 16GB VRAM:
  Q8_0    ~32-33.6 GB  (practically lossless)
  Q5_K_M  ~25-26 GB    (recommended default quality/size trade-off)
  Q4_K_M  ~21 GB       (smallest available quant)
Plan on partial GPU offload (llama.cpp -ngl / your existing -fit layer
splitting) with the remainder in system RAM. Q4_K_M is the least painful
starting point on a 16GB card.

llama.cpp note: this is a custom hybrid Mamba-2/MoE architecture
(nemotron_h_moe). Your gfx906 build needs to be recent enough to recognize
it -- if it fails to load, check `llama-cli --version` and rebuild against
current llama.cpp first.

Reasoning model: this is the "Isar" variant and emits <think>...</think>
blocks before its answer. Run llama-server with --jinja so the GGUF's own
embedded chat template (identity + native tool calling) is applied, rather
than falling back to a generic template.
"""

from huggingface_hub import hf_hub_download

REPO_ID = "Soofi-Project/Soofi-S-Isar-Preview-GGUF"
FILENAME = "soofi-s-isar-preview-Q4_K_M.gguf"  # swap for Q5_K_M / Q8_0 if you have more VRAM+RAM headroom to spare

save_dir = "models/huggingface/Soofi-S-Isar-Preview-GGUF"

print(f"Downloading {FILENAME} from {REPO_ID}...")
path = hf_hub_download(
    repo_id=REPO_ID,
    filename=FILENAME,
    local_dir=save_dir,
)

print(f"Done. Saved to {path}")
