from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Optional

from agent.llm_client import LocalLLMClient
from agent.project_context import ProjectContext


@dataclass
class TaskResult:
    code: str
    filename: str
    extra_info: str
    summary: str
    iteration: int
    validation: Optional[Dict[str, Any]] = None


def estimate_prompt_tokens(prompt: str) -> float:
    normalized_prompt = " ".join(str(prompt).split())
    return max(1.0, len(normalized_prompt) / 3.5)


def parse_response(answer: str):
    raw_text = (answer or "").strip()
    code = ""
    filename = "generated_code.py"
    extra_info = ""

    fenced_match = re.search(r"```(?:\w+)?\s*\n?(.*?)\n?```\s*", raw_text, flags=re.DOTALL)
    if fenced_match:
        code = fenced_match.group(1).strip()
    elif raw_text.startswith("```") and raw_text.endswith("```"):
        lines = raw_text.splitlines()
        if len(lines) >= 3:
            code = "\n".join(lines[1:-1]).strip()

    filename_match = re.search(r"(?im)^(?:Filename|filename)\s*:\s*(.+)$", raw_text)
    if filename_match:
        filename = filename_match.group(1).strip().strip("`\"'")

    rest = raw_text
    rest = re.sub(r"```(?:\w+)?\s*.*?```\s*", "", rest, flags=re.DOTALL)
    rest = re.sub(r"(?im)^(?:Filename|filename)\s*:\s*.+$", "", rest)
    rest = rest.strip()
    if rest and rest not in code:
        extra_info = rest

    return code, filename, extra_info


def compress_prompt_if_needed(prompt: str, max_input_tokens: int) -> str:
    prompt_tokens = estimate_prompt_tokens(prompt)
    if prompt_tokens <= max_input_tokens:
        return prompt

    compressed = (
        "You are a coding agent operating under a small context budget. "
        "Compress the task down to the essential goal, constraints, requirement, and current state. "
        "Return only the compact version of the task.\n\n"
        f"Target max input tokens: {max_input_tokens}\n\n"
        f"Original task (trimmed):\n{str(prompt)[:4000]}"
    )
    return compressed


class CodingAgent:
    def __init__(
        self,
        name: str,
        endpoint: str,
        max_tokens: int,
        max_input_tokens: int,
        project_summary_file: str | Path,
        output_dir: str | Path,
        model: str = "local-model",
    ):
        self.name = name
        self.client = LocalLLMClient(endpoint=endpoint, model=model)
        self.max_tokens = max_tokens
        self.max_input_tokens = max_input_tokens
        self.project = ProjectContext(
            root_dir=self._resolve_base_dir(),
            summary_file=project_summary_file,
            output_dir=output_dir,
        )

    @staticmethod
    def _resolve_base_dir() -> Path:
        return Path(__file__).resolve().parent.parent

    def _read_summary(self) -> str:
        return self.project.read_summary()

    def _write_summary(self, summary: str) -> None:
        self.project.write_summary(summary)

    def _ask_llm(self, prompt: str, system_message: str = "", max_tokens: Optional[int] = None) -> str:
        prompt = compress_prompt_if_needed(prompt, self.max_input_tokens)
        return self.client.request(prompt, system_message=system_message, max_tokens=max_tokens or self.max_tokens)

    def _update_project_summary(self, code: str, filename: str, extra_info: str, summary: str) -> str:
        update_prompt = (
            "You are maintaining a project summary for a coding agent. "
            "Keep the summary concise but useful. Add the new information, preserve earlier facts, and return only the updated summary.\n\n"
            f"Current project summary:\n{summary}\n\n"
            f"New information:\n{code}\n\nFile: {filename}\n\nExtra context:\n{extra_info or 'None'}"
        )
        new_summary = self._ask_llm(update_prompt, system_message="You are a careful project summarizer.")
        self._write_summary(new_summary)
        return new_summary

    def _decide_completion(self, task_description: str, code: str, filename: str, extra_info: str, summary: str) -> str:
        decision_prompt = (
            "Return exactly one of these values: 1 or 0.\n"
            "Use 1 only if the task is fully complete and the generated code is likely correct.\n"
            "Use 0 if the code is incomplete, flawed, missing requirements, or needs another iteration.\n\n"
            f"Task:\n{task_description}\n\n"
            f"Generated file:\n{filename}\n\n"
            f"Code:\n{code}\n\n"
            f"Extra context:\n{extra_info or 'None'}\n\n"
            f"Project summary:\n{summary}"
        )
        decision = self._ask_llm(decision_prompt, system_message="Reply with only 1 or 0.")
        cleaned = re.sub(r"[^01]", "", decision.strip())
        return cleaned[:1] if cleaned else "0"

    def _build_retry_prompt(self, task_description: str, summary: str, filename: str, error_text: str) -> str:
        return (
            "You are iterating on a coding task. Fix the problem and continue from the current state. "
            "Return only a corrected Python program in a single code block and include the file name after the code block in the format: Filename: name.py\n\n"
            f"Original task:\n{task_description}\n\n"
            f"Current summary:\n{summary}\n\n"
            f"Current file:\n{filename}\n\n"
            f"Failure details:\n{error_text}"
        )

    def validate_code(self, filename: str) -> Dict[str, Any]:
        target = self.project.output_dir / filename
        if not target.exists():
            return {"return_code": 1, "stdout": "", "stderr": f"File not found: {filename}", "file": str(target)}

        process = subprocess.run(
            [sys.executable, str(target)],
            capture_output=True,
            text=True,
            cwd=str(self.project.root_dir),
            timeout=600,
            check=False,
        )
        return {
            "return_code": process.returncode,
            "stdout": process.stdout,
            "stderr": process.stderr,
            "file": str(target),
        }

    def solve(self, task_description: str, max_iterations: int = 5, auto_run: bool = True) -> TaskResult:
        current_task = task_description
        summary = self._read_summary()
        last_code = ""
        last_filename = "generated_code.py"
        last_extra_info = ""
        validation: Optional[Dict[str, Any]] = None

        for iteration in range(1, max_iterations + 1):
            iteration_prompt = (
                "You are a coding agent. Generate the requested Python program. "
                "Return only the code, and include the file name after the code block in this exact format: Filename: name.py.\n\n"
                f"Iteration {iteration}/{max_iterations}\n\n"
                f"Project summary:\n{summary}\n\n"
                f"Task:\n{current_task}"
            )

            llm_answer = self._ask_llm(iteration_prompt, system_message="You are a precise code generator.")
            code, filename, extra_info = parse_response(llm_answer)
            last_code, last_filename, last_extra_info = code, filename, extra_info

            if not code.strip():
                raise ValueError("The model returned no code block. Please ensure it returns fenced Python code and a filename.")

            self.project.write_code(filename, code)
            summary = self._update_project_summary(code, filename, extra_info, summary)

            if auto_run:
                validation = self.validate_code(filename)
                if validation["return_code"] != 0:
                    current_task = self._build_retry_prompt(
                        task_description,
                        summary,
                        filename,
                        f"stdout: {validation['stdout'][:1500]}\n\nstderr: {validation['stderr'][:1500]}",
                    )
                    continue

            decision = self._decide_completion(task_description, code, filename, extra_info, summary)
            if decision == "1":
                return TaskResult(code=code, filename=filename, extra_info=extra_info, summary=summary, iteration=iteration, validation=validation)

            current_task = self._build_retry_prompt(
                task_description,
                summary,
                filename,
                "The previous version did not fully meet the specification. Improve it and keep the same project goals.",
            )

        return TaskResult(
            code=last_code,
            filename=last_filename,
            extra_info=last_extra_info,
            summary=summary,
            iteration=max_iterations,
            validation=validation,
        )
