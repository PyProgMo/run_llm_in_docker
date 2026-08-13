import requests

url = "http://127.0.0.1:41223/v1/chat/completions"  # adjust host/port if needed

payload = {
    "model": "local-model",  # llama.cpp usually ignores this, but field is required
    "messages": [
        {"role": "user", "content": "Return: Tokens left, tokens used, tokens left, make what u do not know -1, and return the answer in a code block."}
    ],
    "stream": False
}

def test():        
    response = requests.post(url, json=payload)
    response.raise_for_status()

    data = response.json()
    answer = data["choices"][0]["message"]["content"]

    print(answer)


class Agent:
    def __init__(self, name, url):
        self.name = name
        self.url = url

    def send_request(self, payload):
        response = requests.post(self.url, json=payload)
        response.raise_for_status()
        return response.json()

    def write_pythonfile(self, filename, content):
        with open(filename, 'w') as f:
            f.write(content)

    def read_pythonfile(self, filename):
        with open(filename, 'r') as f:
            return f.read()

    def run_pythonfile(self, filename):
        import subprocess
        result = subprocess.run(['python', filename], capture_output=True, text=True)
        return result.stdout, result.stderr

    def do_complex_python_task(self, task_description):
        # Step 1: Send request to the LLM
        response_data = self.send_request({
            "model": "local-model",
            "messages": [{"role": "user", "content": task_description}],
            "stream": False
        })

        # Step 2: Extract the answer from the response
        answer = response_data["choices"][0]["message"]["content"]
        # remove first and last lines if they are code block markers
        if answer.startswith("```") and answer.endswith("```"):
            answer = "\n".join(answer.splitlines()[1:-1])

        # Step 3: Write the answer to a Python file
        filename = "generated_code.py"
        self.write_pythonfile(filename, answer)

        # Step 4: Read the content of the Python file (for verification)
        file_content = self.read_pythonfile(filename)
        print(f"Content of {filename}:\n{file_content}")

        # Step 5: Run the Python file and capture output
        stdout, stderr = self.run_pythonfile(filename)
        print(f"Output of {filename}:\n{stdout}")
        if stderr:
            print(f"Errors:\n{stderr}")

        # Step 6: Return the answer for further use if needed
        return answer

    def iterate_task(self, task_description, iterations=3):
        for i in range(iterations):
            print(f"\nIteration {i + 1}/{iterations}")
            answer = self.do_complex_python_task(task_description)
            print(f"Answer from iteration {i + 1}:\n{answer}")


def Agent1():
    agent = Agent("Agent1", url)
    task_description = "create a python program that I can use as a calender to keep track of my appointments and events, and make sure to include a feature that allows me to set reminders for upcoming events. You are part of a coding agent. Only Return the Python code, and nothing else. Do not include any explanations or comments in the code. Make sure to use the latest version of Python and include any necessary libraries or modules that are required for the program to run smoothly." 
    agent.iterate_task(task_description, iterations=5)

if __name__ == "__main__":
    Agent1()