from transformers import AutoTokenizer, AutoModelForCausalLM

MODEL = "mistralai/Mistral-7B-Instruct-v0.3"

print("Downloading tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(MODEL)

print("Downloading model...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL,
    torch_dtype="auto",
)

print("Done.")
