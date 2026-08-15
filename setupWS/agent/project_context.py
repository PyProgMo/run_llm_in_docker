from __future__ import annotations

from pathlib import Path
from typing import Union


PathLike = Union[str, Path]


class ProjectContext:
    def __init__(self, root_dir: PathLike, summary_file: PathLike, output_dir: PathLike):
        self.root_dir = Path(root_dir).resolve()
        self.summary_file = Path(summary_file).resolve()
        self.output_dir = Path(output_dir).resolve()
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.summary_file.parent.mkdir(parents=True, exist_ok=True)
        self._ensure_summary_exists()

    def _ensure_summary_exists(self) -> None:
        if not self.summary_file.exists():
            self.summary_file.write_text("Project Summary:\n", encoding="utf-8")
            return

        content = self.summary_file.read_text(encoding="utf-8")
        if not content.startswith("Project Summary:"):
            self.summary_file.write_text("Project Summary:\n" + content, encoding="utf-8")

    def read_summary(self) -> str:
        return self.summary_file.read_text(encoding="utf-8")

    def write_summary(self, content: str) -> None:
        self.summary_file.write_text(content.strip() or "Project Summary:\n", encoding="utf-8")

    def write_code(self, filename: str, content: str) -> Path:
        target_path = self.output_dir / filename
        target_path.parent.mkdir(parents=True, exist_ok=True)
        target_path.write_text(content, encoding="utf-8")
        return target_path

    def read_code(self, filename: str) -> str:
        return (self.output_dir / filename).read_text(encoding="utf-8")
