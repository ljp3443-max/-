"""ui/index.html 을 다시 만듭니다.

원본 HTML(../sports-ai-analyzer-v4.html)은 손대지 않습니다. 여기서는 그 파일을
그대로 읽어 bridge.js 만 </body> 앞에 끼워 넣습니다. 원본을 고치면 이 스크립트를
다시 돌리기만 하면 화면이 따라옵니다.

    python make_ui.py
"""
from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BRIDGE = os.path.join(HERE, "bridge.js")
OUT = os.path.join(HERE, "ui", "index.html")

MARK = "<!-- desktop-bridge -->"


def find_source() -> str | None:
    """원본 HTML 을 찾습니다.

    같은 폴더에 두고 쓰는 경우와, 저장소처럼 한 단계 위에 두는 경우가 둘 다
    있습니다. 브라우저가 이름 뒤에 (1) 을 붙여 놓았을 수도 있어 그것도 봅니다.
    """
    import glob
    for d in (HERE, os.path.join(HERE, "..")):
        exact = os.path.join(d, "sports-ai-analyzer-v4.html")
        if os.path.exists(exact):
            return exact
    for d in (HERE, os.path.join(HERE, "..")):
        hits = sorted(glob.glob(os.path.join(d, "*analyzer*.html")))
        hits = [h for h in hits if os.path.abspath(h) != os.path.abspath(OUT)]
        if hits:
            return hits[0]
    return None


def main() -> int:
    SRC = find_source()
    if SRC is None:
        print("원본 HTML 을 찾지 못했습니다.")
        print("  sports-ai-analyzer-v4.html 을 이 폴더나 바로 위 폴더에 두세요.")
        print(f"  찾아본 곳: {HERE}  그리고  {os.path.abspath(os.path.join(HERE, '..'))}")
        return 1
    print(f"원본: {SRC}")
    html = open(SRC, encoding="utf-8").read()
    bridge = open(BRIDGE, encoding="utf-8").read()

    if MARK in html:
        print("원본에 이미 다리가 들어 있습니다. 원본은 순수한 상태로 두세요.")
        return 1
    if "</body>" not in html:
        print("</body> 를 찾지 못해 끼워 넣을 자리가 없습니다.")
        return 1

    block = f"\n{MARK}\n<script>\n{bridge}\n</script>\n"
    html = html.replace("</body>", block + "</body>", 1)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"만들었습니다: {OUT}  ({len(html):,} 자)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
