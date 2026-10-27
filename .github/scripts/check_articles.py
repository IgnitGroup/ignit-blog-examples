"""Require every articles/<slug>/ directory to have a row in the README catalog."""

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


def check_catalog(root: Path) -> list[str]:
    readme = root / "README.md"
    articles = root / "articles"
    if not readme.is_file() or not articles.is_dir():
        return ["README.md and the articles/ directory are required."]

    section = re.search(
        r"^## Articles[ \t]*\r?\n(.*?)(?=^#{1,2} |\Z)",
        readme.read_text(encoding="utf-8"),
        flags=re.MULTILINE | re.DOTALL,
    )
    if not section:
        return ["README.md must contain a '## Articles' section with a table."]

    listed = set()
    for line in section.group(1).splitlines():
        if not line.lstrip().startswith("|"):
            continue
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", line):
            link = urlsplit(target.strip())
            if link.scheme or link.netloc:
                continue
            target_path = (root / unquote(link.path)).resolve()
            if not target_path.exists():
                continue
            try:
                relative = target_path.relative_to(articles.resolve())
            except ValueError:
                continue
            if relative.parts:
                listed.add(relative.parts[0])

    expected = {p.name for p in articles.iterdir() if p.is_dir() and not p.name.startswith(".")}
    return [
        f"Missing README Articles table entry: articles/{name}/"
        for name in sorted(expected - listed)
    ]


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    errors = check_catalog(root)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("Every article directory is listed in the README Articles table.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
