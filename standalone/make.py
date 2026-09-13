"""혼자 도는 HTML 한 장을 만듭니다.

    python3 make.py            -> 축구분석기.html
    python3 make.py <토큰>     -> football-data 토큰을 넣은 개인용 사본

원본(../sports-ai-analyzer-v4.html)은 건드리지 않습니다. 두 가지만 합니다.

  1. autoDetectProxy() 호출을 지웁니다 - 이 판에는 프록시가 없어서, 몇 초를
     버린 끝에 "프록시를 찾지 못했습니다" 라는 틀린 안내를 남깁니다.
  2. standalone.js 를 </body> 앞에 끼웁니다 - 브라우저에서 쓸 수 없는 소스를
     화면에서 치우고, 키를 기억할 수 있게 합니다.
"""
from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "sports-ai-analyzer-v4.html")
EXTRA = os.path.join(HERE, "standalone.js")
OUT = os.path.join(HERE, "축구분석기.html")

CALL = "\nautoDetectProxy();"


def main(token: str = "") -> int:
    html = open(SRC, encoding="utf-8").read()
    extra = open(EXTRA, encoding="utf-8").read()

    if html.count(CALL) != 1:
        print(f"autoDetectProxy() 호출을 하나만 찾아야 하는데 {html.count(CALL)}개입니다.")
        return 1
    html = html.replace(CALL, "\n/* 이 판에는 프록시가 없습니다 - 브라우저가 직접 부를 수 있는 소스만 씁니다. */")

    if token:
        slot = " fdKey  :'',"
        if html.count(slot) != 1:
            print("fdKey 자리를 찾지 못했습니다.")
            return 1
        html = html.replace(slot, f" fdKey  :'{token}',")

    if "</body>" not in html:
        print("</body> 를 찾지 못했습니다.")
        return 1
    html = html.replace("</body>", f"\n<!-- standalone -->\n<script>\n{extra}\n</script>\n</body>", 1)

    open(OUT, "w", encoding="utf-8").write(html)
    print(f"만들었습니다: {OUT}  ({len(html):,} 자)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else ""))
