#!/usr/bin/env python3
"""Inject custom tokens into shadcn-generated index.css.

Reads custom-tokens.css template, parses :root and .dark token groups,
replaces overlapping tokens (e.g. chart-1~5) and appends new ones (chart-6, kpi-*, table-row-hover).
Also adds --color-chart-6 to @theme inline block.
"""

import re
import sys
from pathlib import Path


def parse_custom_tokens(template_path: Path) -> tuple[dict[str, str], dict[str, str]]:
    """Parse custom-tokens.css into light and dark token dicts."""
    content = template_path.read_text()
    sections = re.split(r'/\*.*?\*/', content, flags=re.DOTALL)

    light: dict[str, str] = {}
    dark: dict[str, str] = {}
    current = None

    for section in sections:
        for line in section.strip().splitlines():
            stripped = line.strip()
            m = re.match(r'(--[\w-]+):\s*(.+);', stripped)
            if not m:
                continue
            if current is None:
                current = 'light'
            if current == 'light':
                light[m.group(1)] = m.group(2)
            else:
                dark[m.group(1)] = m.group(2)
        # Switch to dark after first section with tokens (split boundary = next comment)
        if current == 'light' and light:
            current = 'dark'

    return light, dark


def patch_block(css: str, selector: str, tokens: dict[str, str]) -> str:
    """Replace existing token values and append new tokens in a CSS block."""
    pattern = re.compile(
        r'^(' + re.escape(selector) + r'\s*\{)(.*?)(^\})',
        re.MULTILINE | re.DOTALL
    )
    match = pattern.search(css)
    if not match:
        print(f'Warning: {selector} block not found', file=sys.stderr)
        return css

    block_start = match.start(2)
    block_end = match.start(3)
    block_content = match.group(2)

    remaining = dict(tokens)

    # Replace existing tokens in the block
    def replace_token(m: re.Match) -> str:
        name = m.group(1)
        if name in remaining:
            new_val = remaining.pop(name)
            return f'{m.group(0).split(":")[0]}: {new_val};'
        return m.group(0)

    new_block = re.sub(r'(--[\w-]+):\s*[^;]+;', replace_token, block_content)

    # Append remaining new tokens before the closing }
    if remaining:
        append_lines = '\n'.join(f'    {name}: {val};' for name, val in remaining.items())
        new_block = new_block.rstrip() + '\n' + append_lines + '\n'

    return css[:block_start] + new_block + css[block_end:]


def add_chart6_to_theme(css: str) -> str:
    """Add --color-chart-6 mapping to @theme inline block."""
    chart6_line = '    --color-chart-6: var(--chart-6);\n'
    match = re.search(r'(    --color-chart-5: var\(--chart-5\);\n)', css)
    if match:
        pos = match.end()
        css = css[:pos] + chart6_line + css[pos:]
    return css


def main():
    if len(sys.argv) < 3:
        print('Usage: inject-custom-tokens.py <index.css> <custom-tokens.css>')
        sys.exit(1)

    index_path = Path(sys.argv[1])
    template_path = Path(sys.argv[2])

    css = index_path.read_text()
    light_tokens, dark_tokens = parse_custom_tokens(template_path)

    css = patch_block(css, ':root', light_tokens)
    css = patch_block(css, '.dark', dark_tokens)
    css = add_chart6_to_theme(css)

    index_path.write_text(css)
    print(f'Injected custom tokens into {index_path}')


if __name__ == '__main__':
    main()
