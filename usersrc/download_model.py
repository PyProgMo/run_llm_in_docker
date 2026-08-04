from transformers import AutoTokenizer, AutoModelForCausalLM

MODEL = "Qwen/Qwen_Qwen3-14B-Q4_K_M.gguf"

print("Downloading tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL)

print("Downloading model...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL,
    torch_dtype="auto",
)

# save the model and tokenizer to projectdir/models/huggingface/Qwen2.5-Coder-7B-Instruct
save_dir = "models/huggingface/Qwen_Qwen3-14B-Q4_K_M.gguf"
print(f"Saving model and tokenizer to {save_dir}...")
tokenizer.save_pretrained(save_dir)
model.save_pretrained(save_dir)

print("Done.")
