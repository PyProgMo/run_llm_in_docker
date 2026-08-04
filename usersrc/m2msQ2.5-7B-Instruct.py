from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-Coder-7B-Instruct")
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-Coder-7B-Instruct")

# Save to your project directory (e.g., ~/ai-agent/models/)
model.save_pretrained("../../models/Qwen2.5-Coder-7B-Instruct")
tokenizer.save_pretrained("../../models/Qwen2.5-Coder-7B-Instruct")
