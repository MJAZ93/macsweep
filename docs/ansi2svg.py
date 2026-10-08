#!/usr/bin/env python3
"""Render ANSI terminal output to an SVG that looks like a macOS terminal window."""
import re, sys, html

PALETTE = {30:"#1f2430",31:"#ff6b6b",32:"#5be49b",33:"#ffd866",34:"#78a9ff",35:"#c792ea",36:"#5ad4e6",37:"#d6deeb",
           90:"#6b7280",91:"#ff8787",92:"#7ef0b0",93:"#ffe08a",94:"#9cc0ff",95:"#d9b3ff",96:"#8ee3f0",97:"#ffffff"}
BG = {42:"#5be49b",43:"#ffd866",41:"#ff6b6b",44:"#78a9ff"}
FG_DEFAULT = "#d6deeb"
CW, LH, PAD = 8.4, 19, 18

def parse(text):
    lines, row = [], []
    fg, bg, bold, dim = None, None, False, False
    for m in re.finditer(r'\x1b\[([0-9;]*)m|\x1b\[[0-9;]*[A-Za-z]|(\r)(?!\n)|(\r?\n)|([^\x1b\r\n]+)', text):
        code, cr, nl, chunk = m.groups()
        if code is None and cr is None and nl is None and chunk is None:
            continue  # other escape sequence (cursor movement etc.)
        if code is not None:
            for c in (code or "0").split(";"):
                c = int(c or 0)
                if c == 0: fg, bg, bold, dim = None, None, False, False
                elif c == 1: bold = True
                elif c == 2: dim = True
                elif c in PALETTE: fg = PALETTE[c]
                elif c in BG: bg = BG[c]
        elif cr: row = []
        elif nl: lines.append(row); row = []
        elif chunk: row.append((chunk, fg, bg, bold, dim))
    if row: lines.append(row)
    return lines

def render(lines, title="macsweep"):
    width = max((sum(len(c[0]) for c in r) for r in lines), default=80)
    width = max(width, 60)
    W, H = int(width*CW + 2*PAD), int(len(lines)*LH + 2*PAD + 34)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="SFMono-Regular,Menlo,Consolas,monospace" font-size="13">',
           f'<rect width="{W}" height="{H}" rx="10" fill="#0f1117"/>',
           f'<rect width="{W}" height="34" rx="10" fill="#1b1e28"/><rect y="20" width="{W}" height="14" fill="#1b1e28"/>',
           '<circle cx="20" cy="17" r="6" fill="#ff5f57"/><circle cx="40" cy="17" r="6" fill="#febc2e"/><circle cx="60" cy="17" r="6" fill="#28c840"/>',
           f'<text x="{W/2}" y="22" fill="#8b93a7" text-anchor="middle" font-size="12">{html.escape(title)}</text>']
    y = 34 + PAD
    for r in lines:
        x = PAD
        for chunk, fg, bg, bold, dim in r:
            w = len(chunk)*CW
            if bg: out.append(f'<rect x="{x:.1f}" y="{y-14}" width="{w:.1f}" height="{LH}" fill="{bg}"/>')
            col = fg or FG_DEFAULT
            if bg and not fg: col = "#111"
            style = f' font-weight="bold"' if bold else ''
            op = ' opacity="0.55"' if dim else ''
            out.append(f'<text x="{x:.1f}" y="{y}" fill="{col}"{style}{op} xml:space="preserve">{html.escape(chunk)}</text>')
            x += w
        y += LH
    out.append('</svg>')
    return "\n".join(out)

if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    title = sys.argv[3] if len(sys.argv) > 3 else "macsweep"
    with open(src, encoding="utf-8", errors="replace", newline="") as f: text = f.read()
    with open(dst, "w", encoding="utf-8") as f: f.write(render(parse(text), title))
