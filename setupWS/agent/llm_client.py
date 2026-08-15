from __future__ import annotations

from typing import Any, Dict, List

import requests


class LocalLLMClient:
    def __init__(self, endpoint: str, model: str = "local-model", timeout: int = 600):
        self.endpoint = endpoint
        self.model = model
        self.timeout = timeout

    def request(
        self,
        prompt: str,
        system_message: str = "",
        temperature: float = 0.2,
        max_tokens: int = 16384,
    ) -> str:
        messages: List[Dict[str, str]] = []
        if system_message:
            messages.append({"role": "system", "content": system_message})
        messages.append({"role": "user", "content": prompt})

        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": False,
        }

        response = requests.post(self.endpoint, json=payload, timeout=self.timeout)
        response.raise_for_status()
        data = response.json()

        if not data.get("choices"):
            raise RuntimeError(f"No response choices returned by local model: {data}")

        content = data["choices"][0]["message"]["content"]
        return content.strip()
