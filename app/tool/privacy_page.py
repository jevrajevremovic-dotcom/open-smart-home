#!/usr/bin/env python3
"""Renders docs/PRIVACY.md as docs/privacy/index.html (the privacy policy URL
app stores ask for, e.g. on GitHub Pages). Run after every PRIVACY.md change:

    app/tool/privacy_page.py [--name "Brand"] [--contact "mail@example.rs"]

Only the Markdown PRIVACY.md uses: headings, paragraphs, lists, tables, bold,
inline code and links. No dependencies.
"""
import argparse
import html
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--name', default='Open Smart Home')
parser.add_argument('--contact', default='')
parser.add_argument('--out', default=str(root / 'docs' / 'privacy' / 'index.html'))
args = parser.parse_args()


def inline(text: str) -> str:
    text = html.escape(text, quote=False)
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
    # Links to other repository files make no sense on the web page.
    text = re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)', r'<a href="\2">\1</a>', text)
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    return text


lines = (root / 'docs' / 'PRIVACY.md').read_text(encoding='utf-8').splitlines()
out = []
i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith('# '):
        i += 1
        continue  # the page has its own title
    if line.startswith('## '):
        out.append(f'\n<h2>{inline(line[3:])}</h2>')
    elif line.startswith('- '):
        out.append('<ul>')
        while i < len(lines) and lines[i].startswith('- '):
            out.append(f'<li>{inline(lines[i][2:])}</li>')
            i += 1
        out.append('</ul>')
        continue
    elif line.startswith('|'):
        rows = []
        while i < len(lines) and lines[i].startswith('|'):
            cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
            if not all(re.fullmatch(r':?-+:?', c) for c in cells):
                rows.append(cells)
            i += 1
        out.append('<div class="scroll"><table>')
        out.append('<tr>' + ''.join(f'<th>{inline(c)}</th>' for c in rows[0]) + '</tr>')
        for r in rows[1:]:
            out.append('<tr>' + ''.join(f'<td>{inline(c)}</td>' for c in r) + '</tr>')
        out.append('</table></div>')
        continue
    elif line.strip():
        para = [line]
        while i + 1 < len(lines) and lines[i + 1].strip() and not re.match(r'(#|- |\|)', lines[i + 1]):
            i += 1
            para.append(lines[i])
        out.append(f'<p>{inline(" ".join(para))}</p>')
    i += 1

name = html.escape(args.name)
contact = (f'<p>Kontakt / Contact: {html.escape(args.contact)}</p>' if args.contact else '')
page = f"""<!doctype html>
<html lang="sr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{name} – privatnost</title>
<style>
  :root {{ --bg:#fbfaf8; --fg:#1d1b19; --muted:#5f5a55; --line:#e4dfda; --accent:#b4531f; }}
  @media (prefers-color-scheme: dark) {{
    :root {{ --bg:#171513; --fg:#ece7e2; --muted:#a9a19a; --line:#34302c; --accent:#f0a06a; }}
  }}
  body {{ margin:0; background:var(--bg); color:var(--fg);
         font:16px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }}
  main {{ max-width:760px; margin:0 auto; padding:32px 16px 64px; }}
  h1 {{ font-size:1.8rem; margin:0 0 4px; }}
  h2 {{ font-size:1.2rem; margin:32px 0 8px; }}
  .lead, .muted {{ color:var(--muted); }}
  a {{ color:var(--accent); }}
  code {{ font-size:.9em; background:var(--line); padding:1px 4px; border-radius:4px; }}
  .scroll {{ overflow-x:auto; }}
  table {{ border-collapse:collapse; width:100%; font-size:.95rem; }}
  th, td {{ text-align:left; vertical-align:top; padding:8px; border-bottom:1px solid var(--line); }}
  section.en {{ margin-top:48px; padding-top:16px; border-top:1px solid var(--line); }}
</style>
</head>
<body>
<main>
<h1>{name} – izjava o privatnosti</h1>
{chr(10).join(out)}
{contact}
<section class="en" lang="en">
<h2>In short (English)</h2>
<p>{name} is an app for <strong>your own</strong> Home Assistant server. The app's makers run
no server and receive no data: the app talks only to the Home Assistant address you enter.
There is no analytics, tracking or advertising. The sign-in token stays in the device's
secure storage. Data leaves your home network only for features you turn on yourself:
weather from MET Norway (location rounded to ~1 km), the update check on GitHub (not in
store builds), online speech recognition if you choose it, remote access through your own
Tailscale, Nabu Casa or domain, and the AI service configured in your Home Assistant when you
ask it to draft an automation. Settings → “Delete all local data” removes everything the app
keeps on the device.</p>
</section>
</main>
</body>
</html>
"""
path = pathlib.Path(args.out)
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(page, encoding='utf-8')
print(f'wrote {path}')
