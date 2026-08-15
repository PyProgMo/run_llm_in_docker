from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class TaskPlan:
    title: str
    description: str
    source_file: Optional[str] = None


class TaskPlanner:
    def __init__(self, default_directory: str = "tasks"):
        self.default_directory = Path(default_directory)
        self.default_directory.mkdir(parents=True, exist_ok=True)

    def from_text(self, task_text: str, title: str = "task") -> TaskPlan:
        cleaned = (task_text or "").strip()
        if not cleaned:
            raise ValueError("The task text is empty. Write the task into a .txt file or pass a --task string.")
        return TaskPlan(title=title, description=cleaned, source_file=None)

    def from_file(self, task_file: str | Path, title: Optional[str] = None) -> TaskPlan:
        task_path = Path(task_file)
        if not task_path.exists():
            raise FileNotFoundError(f"Task file not found: {task_path}")

        content = task_path.read_text(encoding="utf-8")
        plan_title = title or task_path.stem
        return TaskPlan(title=plan_title, description=content.strip(), source_file=str(task_path))

    def write_task_template(self, task_file: str | Path = "tasks/task.txt") -> Path:
        path = Path(task_file)
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_text(
                "Create a Python script that prints Hello World and saves it as hello_world.py.\n",
                encoding="utf-8",
            )
        return path
