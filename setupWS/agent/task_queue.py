from __future__ import annotations

import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass
class QueuedTask:
    task_id: int
    task_name: str
    prompt: str
    command: Optional[List[str]] = None
    status: str = "queued"
    result: Optional[Dict[str, Any]] = None


class TaskQueue:
    def __init__(self):
        self.tasks: List[QueuedTask] = []
        self._next_id = 1

    def enqueue(self, task_name: str, prompt: str, command: Optional[List[str]] = None) -> QueuedTask:
        task = QueuedTask(task_id=self._next_id, task_name=task_name, prompt=prompt, command=command)
        self._next_id += 1
        self.tasks.append(task)
        return task

    def run_task(self, task: QueuedTask) -> Dict[str, Any]:
        if task.command is None:
            task.command = [sys.executable, "-c", "print('queued task executed')"]

        task.status = "running"
        process = subprocess.run(task.command, capture_output=True, text=True, check=False)
        result = {
            "task_id": task.task_id,
            "task_name": task.task_name,
            "return_code": process.returncode,
            "stdout": process.stdout,
            "stderr": process.stderr,
            "command": task.command,
        }
        task.result = result
        task.status = "finished"
        return result

    def run_all(self) -> List[QueuedTask]:
        for task in self.tasks:
            if task.status in {"queued", "running"}:
                self.run_task(task)
        return self.tasks

    def wait_for_all(self) -> List[QueuedTask]:
        return self.run_all()

    def clear(self) -> None:
        self.tasks.clear()
        self._next_id = 1
