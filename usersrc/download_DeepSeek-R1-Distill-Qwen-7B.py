from transformers import AutoTokenizer, AutoModelForCausalLM

MODEL = "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"

print("Downloading tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL)

print("Downloading model...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL,
    torch_dtype="auto",
)

# save the model and tokenizer to projectdir/models/huggingface/DeepSeek-R1-Distill-Qwen-7B
save_dir = "models/huggingface/DeepSeek-R1-Distill-Qwen-7B"
print(f"Saving model and tokenizer to {save_dir}...")
tokenizer.save_pretrained(save_dir)
model.save_pretrained(save_dir)

print("Done.")
