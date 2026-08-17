from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def processed_dir() -> Path:
    return repo_root() / "data" / "processed"
