"""내 PC 서버용 화면을 만듭니다.

원본 HTML 은 손대지 않습니다. 여기서 두 가지만 합니다.

  1. local-bridge.js 를 </body> 앞에 끼워 넣습니다.
  2. autoDetectProxy() 호출을 지웁니다 - 이 방식에는 프록시가 없어서
     8787 포트를 두드리며 몇 초를 버리고, 끝나면 "프록시를 찾지 못했습니다"
     라고 잘못된 안내를 덮어씁니다.
"""
from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "sports-ai-analyzer-v4.html")
BRIDGE = os.path.join(HERE, "local-bridge.js")
OUT = os.path.join(HERE, "index.html")

CALL = "\nautoDetectProxy();"


def main(token: str = "") -> int:
    html = open(SRC, encoding="utf-8").read()
    bridge = open(BRIDGE, encoding="utf-8").read()

    if html.count(CALL) != 1:
        print(f"autoDetectProxy() 호출을 정확히 하나 찾지 못했습니다: {html.count(CALL)}개")
        return 1
    html = html.replace(CALL, "\n/* 이 빌드에는 프록시가 없습니다 - 서버가 같은 주소에서 대신 부릅니다. */")

    if token:
        key = " fdKey  :'',"
        if html.count(key) != 1:
            print("fdKey 자리를 찾지 못했습니다.")
            return 1
        html = html.replace(key, f" fdKey  :'{token}',")

    if "</body>" not in html:
        print("</body> 를 찾지 못했습니다.")
        return 1
    html = html.replace("</body>", f"\n<!-- local-bridge -->\n<script>\n{bridge}\n</script>\n</body>", 1)

    open(OUT, "w", encoding="utf-8").write(html)
    print(f"만들었습니다: {OUT}  ({len(html):,} 자)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else ""))
