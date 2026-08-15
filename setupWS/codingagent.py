import argparse
import sys
from pathlib import Path

import defaults as defaults
from agent.coding_agent import CodingAgent
from agent.task_planner import TaskPlanner
from agent.task_queue import TaskQueue


DEFAULT_ENDPOINT = defaults.Endpoint
DEFAULT_MAX_TOKENS = defaults.KontextMaxTokens
DEFAULT_MAX_INPUT_TOKENS = defaults.KontextMaxinpTokens
DEFAULT_OUTPUT_DIR = Path(defaults.targetdir).resolve()
DEFAULT_PROJECT_SUMMARY_FILE = Path(defaults.projectsummaryfile).resolve()


def build_agent() -> CodingAgent:
    return CodingAgent(
        name="local-coding-agent",
        endpoint=DEFAULT_ENDPOINT,
        max_tokens=DEFAULT_MAX_TOKENS,
        max_input_tokens=DEFAULT_MAX_INPUT_TOKENS,
        project_summary_file=DEFAULT_PROJECT_SUMMARY_FILE,
        output_dir=DEFAULT_OUTPUT_DIR,
    )


def load_task_plan(task_source: str | Path):
    planner = TaskPlanner(default_directory=str(Path(__file__).resolve().parent / "tasks"))
    task_path = Path(task_source)

    if task_path.exists() and task_path.suffix.lower() == ".txt":
        return planner.from_file(task_path)
    if task_path.exists() and task_path.suffix.lower() != ".txt":
        return planner.from_text(task_path.read_text(encoding="utf-8"), title=task_path.stem)
    return planner.from_text(str(task_source))


def run_task(task_source: str | Path, max_iterations: int = 5, auto_run: bool = True):
    task_plan = load_task_plan(task_source)
    queue = TaskQueue()
    queued_task = queue.enqueue(task_plan.title, task_plan.description)

    agent = build_agent()
    result = agent.solve(queued_task.prompt, max_iterations=max_iterations, auto_run=auto_run)

    queued_task.status = "finished"
    queued_task.result = {
        "task_id": queued_task.task_id,
        "task_name": queued_task.task_name,
        "filename": result.filename,
        "code": result.code,
        "summary": result.summary,
        "iteration": result.iteration,
        "validation": result.validation,
    }

    queued_task.command = [
        sys.executable,
        "-c",
        "print('task processed and queue resumed after subprocess completion')",
    ]
    queue.run_all()
    return result


def parse_args():
    parser = argparse.ArgumentParser(description="Run the modular local coding agent on a task text file.")
    parser.add_argument("--task-file", type=str, help="Path to a .txt file containing the task description.")
    parser.add_argument("--task", type=str, help="Inline task text to run when no task file is provided.")
    parser.add_argument("--iterations", type=int, default=5, help="Maximum iterative coding rounds.")
    parser.add_argument("--no-run", action="store_true", help="Skip subprocess validation runs.")
    return parser.parse_args()


def main():
    args = parse_args()

    if args.task_file:
        result = run_task(args.task_file, max_iterations=args.iterations, auto_run=not args.no_run)
    elif args.task:
        result = run_task(args.task, max_iterations=args.iterations, auto_run=not args.no_run)
    else:
        template_path = Path(__file__).resolve().parent / "tasks" / "task.txt"
        template_path.parent.mkdir(parents=True, exist_ok=True)
        if not template_path.exists():
            template_path.write_text("Create a Python script that prints Hello World and saves it as hello_world.py.\n", encoding="utf-8")
        result = run_task(template_path, max_iterations=args.iterations, auto_run=not args.no_run)

    print(f"Saved result to: {result.filename}")
    print(result.code)


if __name__ == "__main__":
    main()
