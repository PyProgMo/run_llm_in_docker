from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("mistralai/Mistral-7B-Instruct-v0.3")
tokenizer = AutoTokenizer.from_pretrained("mistralai/Mistral-7B-Instruct-v0.3")

# Save to your project directory (e.g., ~/ai-agent/models/)
model.save_pretrained("../../models/mistralai/Mistral-7B-Instruct-v0.3")
tokenizer.save_pretrained("../../models/mistralai/Mistral-7B-Instruct-v0.3")
