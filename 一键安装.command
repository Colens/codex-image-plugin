#!/bin/bash
cd "$(dirname "$0")"
chmod +x install.sh configure-key.sh doctor.sh scripts/*.sh 2>/dev/null
./install.sh
echo ""
read -p "按回车键关闭窗口..."
