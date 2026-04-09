#!/bin/bash
# auto-session-title plugin
# 自動為缺少 ai-title 的 session 補上標題
# 格式：{session-id-prefix}-{第一條有意義的使用者訊息}
#
# 觸發：Stop event（每次 Claude 回應結束時）
# 效能：已有標題 → grep 命中直接退出（< 5ms）

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# 取 session ID 前 8 碼作為前綴
SESSION_PREFIX="${SESSION_ID:0:8}"

# 找到 session 檔案
CWD_ENCODED=$(pwd | tr '/' '-')
SESSION_DIR="$HOME/.claude/projects/$CWD_ENCODED"
SESSION_FILE="$SESSION_DIR/$SESSION_ID.jsonl"

if [ ! -f "$SESSION_FILE" ]; then
  exit 0
fi

# 快速檢查：已有標題就退出
if grep -q '"ai-title"' "$SESSION_FILE" 2>/dev/null; then
  exit 0
fi

# 訊息數門檻檢查（至少 3 條 user 訊息才補標題）
USER_MSG_COUNT=$(grep -c '"type": *"user"' "$SESSION_FILE" 2>/dev/null || echo "0")
if [ "$USER_MSG_COUNT" -lt 3 ]; then
  exit 0
fi

# 擷取第一條有意義的使用者訊息作為標題
TITLE=$(python3 -c "
import json, re

with open('$SESSION_FILE', 'r', encoding='utf-8') as f:
    for line in f:
        try:
            obj = json.loads(line.strip())
            if obj.get('type') != 'user':
                continue
            msg = obj.get('message', {})
            content = msg.get('content', '')
            text = ''
            if isinstance(content, list):
                for c in content:
                    if isinstance(c, dict) and c.get('type') == 'text':
                        text = c['text']
                        break
            elif isinstance(content, str):
                text = content
            if not text:
                continue
            # 跳過純 IDE/command 標籤開頭的訊息
            stripped = text.strip()
            if re.match(r'^<(ide_|command-|local-command|system)', stripped):
                # 嘗試擷取標籤後的文字
                clean = re.sub(r'<[^>]+>', '', stripped).strip()
                if len(clean) < 5:
                    continue
                text = clean
            # 清理並截斷
            text = re.sub(r'\s+', ' ', text.strip())[:70]
            if text:
                print(text)
                break
        except:
            pass
" 2>/dev/null)

if [ -z "$TITLE" ]; then
  TITLE="Untitled ($(date '+%m/%d'))"
fi

# 寫入 ai-title，格式：{session-id-prefix}-{title}
FULL_TITLE="${SESSION_PREFIX}-${TITLE}"
echo "{\"type\": \"ai-title\", \"sessionId\": \"$SESSION_ID\", \"aiTitle\": \"$FULL_TITLE\"}" >> "$SESSION_FILE"
