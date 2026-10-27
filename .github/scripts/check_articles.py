"""Check the Articles table, or synchronize its directory entries with --write."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path, PurePosixPath
from urllib.parse import quote, unquote, urlsplit


def article_key(row: str) -> str | None:
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", row):
        link = urlsplit(target.strip())
        if link.scheme or link.netloc:
            continue
        parts = PurePosixPath(unquote(link.path)).parts
        if len(parts) >= 2 and parts[0] == "articles":
            return parts[1]
    return None


def cell(text: str) -> str:
    return text.replace("\\", "\\\\").replace("|", "\\|").replace("[", "\\[").replace("]", "\\]")


def new_row(directory: Path) -> str:
    readme = directory / "README.md"
    text = readme.read_text(encoding="utf-8") if readme.is_file() else ""
    heading = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    title = heading.group(1).strip() if heading else directory.name.replace("-", " ")
    code = "articles/" + quote(directory.name, safe="-") + "/"
    published = re.search(r"https://ignit\.group/blog/[a-zA-Z0-9_-]+", text)
    article = published.group(0) if published else code
    labels = {"terraform": "Terraform", "python": "Python", "docker": "Docker", "node": "Node.js"}
    technologies = ", ".join(label for folder, label in labels.items() if (directory / folder).is_dir())
    return f"| [{cell(title)}]({article}) | [Code and instructions]({code}) | {technologies or 'See article README'} | See article README |"


def synchronize(root: Path) -> str:
    readme = root / "README.md"
    articles = root / "articles"
    if not articles.is_dir():
        raise ValueError("The articles/ directory is missing.")
    text = readme.read_text(encoding="utf-8")
    section = re.search(r"^## Articles[ \t]*\r?\n(.*?)(?=^#{1,2} |\Z)", text, re.MULTILINE | re.DOTALL)
    if not section:
        raise ValueError("README.md must contain a '## Articles' section.")
    table = re.search(r"(?:^\|[^\n]*\n?)+", section.group(1), re.MULTILINE)
    if not table:
        raise ValueError("The Articles section must contain a Markdown table.")
    rows = table.group().splitlines()
    expected_header = ["Article", "Code", "Technologies", "Verification"]
    if len(rows) < 2 or [part.strip() for part in rows[0].strip("|").split("|")] != expected_header:
        raise ValueError("Expected table columns: Article, Code, Technologies, Verification.")
    existing = {}
    for row in rows[2:]:
        key = article_key(row)
        if key is None:
            raise ValueError("Each Articles row must link to articles/<directory>/.")
        if key in existing:
            raise ValueError(f"Duplicate Articles table entry: {key}")
        existing[key] = row
    directories = sorted(p for p in articles.iterdir() if p.is_dir() and not p.name.startswith("."))
    updated = rows[:2] + [existing[p.name] if p.name in existing else new_row(p) for p in directories]
    start = section.start(1) + table.start()
    end = section.start(1) + table.end()
    return text[:start] + "\n".join(updated) + "\n" + text[end:]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Update README.md instead of checking it")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    readme = root / "README.md"
    try:
        updated = synchronize(root)
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1
    if updated == readme.read_text(encoding="utf-8"):
        print("Articles table is up to date.")
        return 0
    if args.write:
        readme.write_text(updated, encoding="utf-8")
        print("Updated the Articles table in README.md.")
        return 0
    print("Articles table is out of date. Run: python3 .github/scripts/check_articles.py --write", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
