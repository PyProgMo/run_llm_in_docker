from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "setupWS"))

from codingagent import estimate_prompt_tokens, parse_response


def test_parse_response_extracts_code_and_filename():
    raw = "```python\nprint('hello from the agent')\n```\nFilename: hello_agent.py"

    code, filename, extra = parse_response(raw)

    assert "print('hello from the agent')" in code
    assert filename == "hello_agent.py"
    assert extra == ""


def test_estimate_prompt_tokens_is_positive_and_reasonable():
    prompt = "This is a small prompt with several words to estimate token usage. " * 25

    token_count = estimate_prompt_tokens(prompt)

    assert token_count > 0
    assert token_count > 50
