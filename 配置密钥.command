#!/bin/bash
cd "$(dirname "$0")"
chmod +x configure-key.sh 2>/dev/null
./configure-key.sh
echo ""
read -p "按回车键关闭窗口..."
