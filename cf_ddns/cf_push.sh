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

# 发送 Telegram 消息
res=$(timeout 20s curl -s -X POST "$TGURL" -H "Content-Type: application/json" \
    -d '{"chat_id":"'"${telegramBotUserId}"'", "parse_mode":"HTML", "text":"'"${message_text}"'"}')

# 判断是否请求超时
if [[ $? -eq 124 ]]; then
    echo "Telegram API 请求超时，请检查网络"
    exit 1
fi

# 判断请求是否成功
resSuccess=$(echo "$res" | jq -r ".ok")

if [[ $resSuccess == "true" ]]; then
    echo "Telegram 推送成功"
else
    echo "Telegram 推送失败，请检查网络连接或 Telegram Bot Token 和 User ID 配置"
    echo "错误响应: $res"
    exit 1
fi

exit 0
