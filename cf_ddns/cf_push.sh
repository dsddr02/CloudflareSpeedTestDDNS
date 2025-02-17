#!/bin/bash

# 读取日志信息并格式化
message_text=$(echo "$(sed "$ ! s/$/\\\n/ " ./cf_ddns/informlog | tr -d '\n')")

# 设置 Telegram API 地址
if [[ -z ${Proxy_TG} ]]; then
    tgapi="https://api.telegram.org"
else
    tgapi=$Proxy_TG
fi

TGURL="$tgapi/bot${telegramBotToken}/sendMessage"

# 检查是否配置了 Telegram Bot Token
if [[ -z ${telegramBotToken} ]]; then
    echo "未配置 Telegram 推送"
    exit 1
fi

# 使用后台运行 curl，并设置超时
{
    res=$(curl -s -X POST "$TGURL" -H "Content-Type: application/json" \
        -d '{"chat_id":"'"${telegramBotUserId}"'", "parse_mode":"HTML", "text":"'"${message_text}"'"}')
} &

# 捕获后台进程PID
pid=$!

# 设置超时时间（例如20秒）
timeout=20
sleep $timeout && kill $pid 2>/dev/null &

# 等待进程完成
wait $pid 2>/dev/null

# 检查进程是否还存在
if kill -0 $pid 2>/dev/null; then
    echo "Telegram API 请求超时，请检查网络"
    exit 1
fi

# 打印 `res` 变量的内容，方便调试
echo "Response from Telegram API: $res"

# 判断请求是否成功
resSuccess=$(echo "$res" | jq -r ".ok")

# 如果 `res` 不是有效的 JSON，这行会导致错误
if [[ $? -ne 0 ]]; then
    echo "解析返回内容失败，返回内容: $res"
    exit 1
fi

if [[ $resSuccess == "true" ]]; then
    echo "Telegram 推送成功"
else
    echo "Telegram 推送失败，请检查网络连接或 Telegram Bot Token 和 User ID 配置"
    echo "错误响应: $res"
    exit 1
fi

exit 0
