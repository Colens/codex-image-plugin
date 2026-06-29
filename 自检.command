#!/bin/bash
cd "$(dirname "$0")"
chmod +x doctor.sh scripts/*.sh 2>/dev/null
./doctor.sh
echo ""
read -p "按回车键关闭窗口..."
