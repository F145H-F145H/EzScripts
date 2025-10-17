#!/bin/bash

# 默认保存路径和文件前缀
prefix=""
is_running=false
monitor_pid=""
SCRIPT_NAME=$(basename "$0")

# 文件监听函数
monitor_folder() {
    local source_dir="$HOME/Pictures"
    local processed_file="/tmp/screenshot_monitor_processed_$$"
    
    # 创建已处理文件列表
    touch "$processed_file"
    
    # 设置退出时清理
    trap 'rm -f "$processed_file"; exit' SIGTERM SIGINT
    
    while true; do
        # 查找最新的截图文件（支持多种截图命名格式）
        latest_file=$(find "$source_dir" -maxdepth 1 -type f \( -name "Screenshot*.png" -o -name "screenshot*.png" \) | \
                     sort -r | head -1)
        
        if [ -n "$latest_file" ] && [ -f "$latest_file" ]; then
            # 检查是否已经处理过这个文件
            if ! grep -q "$latest_file" "$processed_file" 2>/dev/null; then
                # 计算文件名的序号
                file_index=1
                while [[ -e "$prefix-$file_index.png" ]]; do
                    ((file_index++))
                done

                # 将截图文件重命名并移动到目标路径
                mv "$latest_file" "$prefix-$file_index.png"
                echo "截图已保存到 $prefix-$file_index.png"
                
                # 记录已处理的文件
                echo "$latest_file" >> "$processed_file"
            fi
        fi

        # 每2秒检查一次
        sleep 2
    done
}

# 停止所有运行的监听进程
stop_all_listeners() {
    local pids
    pids=$(pgrep -f "$SCRIPT_NAME" | grep -v $$)
    
    if [ -n "$pids" ]; then
        echo "停止所有运行的监听进程..."
        for pid in $pids; do
            kill "$pid" 2>/dev/null
        done
        # 等待进程结束
        sleep 1
        # 强制杀死任何残留的进程
        pids=$(pgrep -f "$SCRIPT_NAME" | grep -v $$)
        if [ -n "$pids" ]; then
            kill -9 $pids 2>/dev/null
        fi
    fi
}

# 启动监听
start_listening() {
    if [ -z "$prefix" ]; then
        echo "错误：请设置目标路径和前缀。"
        echo "用法: $0 on /path/to/directory/prefix"
        return 1
    fi

    # 确保目标目录存在
    local target_dir=$(dirname "$prefix")
    if [ ! -d "$target_dir" ]; then
        echo "创建目录: $target_dir"
        mkdir -p "$target_dir"
    fi

    # 先停止所有现有的监听进程
    stop_all_listeners

    echo "启动截图监听..."
    echo "监控目录: $HOME/Pictures/"
    echo "目标位置: $prefix-{序号}.png"
    
    is_running=true
    monitor_folder &
    monitor_pid=$!
    echo "监听进程已启动 (PID: $monitor_pid)"
}

# 停止监听
stop_listening() {
    # 不需要参数，停止所有监听
    stop_all_listeners
    is_running=false
    monitor_pid=""
    echo "所有截图监听已停止"
}

# 显示状态
show_status() {
    local pids
    pids=$(pgrep -f "$SCRIPT_NAME" | grep -v $$)
    
    if [ -n "$pids" ]; then
        echo "截图监听状态: 运行中"
        echo "运行进程: $pids"
        if [ -n "$prefix" ] && [ "$is_running" = true ]; then
            echo "目标路径: $prefix-{序号}.png"
        fi
    else
        echo "截图监听状态: 已停止"
        if [ -n "$prefix" ]; then
            echo "配置的目标路径: $prefix-{序号}.png"
        fi
    fi
}

# 主控制函数
control_listener() {
    case "$1" in
        "on")
            if [ -z "$2" ]; then
                echo "错误：启动监听需要指定目标路径。"
                echo "用法: $0 on /path/to/directory/prefix"
                return 1
            fi
            prefix="$2"
            start_listening
            ;;
        "off")
            stop_listening
            ;;
        "status")
            show_status
            ;;
        *)
            echo "无效命令。请使用:"
            echo "  $0 on <目录/前缀>   - 启动监听"
            echo "  $0 off             - 停止监听" 
            echo "  $0 status          - 显示状态"
            echo ""
            echo "示例:"
            echo "  $0 on /home/user/Pictures/mal/PMAlab"
            echo "  这会将截图保存为: /home/user/Pictures/mal/PMAlab-1.png, PMAlab-2.png, 等等"
            ;;
    esac
}

# 解析传入的命令
if [ $# -eq 0 ]; then
    echo "截图文件监听脚本"
    echo "用法: $0 {on|off|status} [目标路径]"
    echo ""
    echo "当前状态:"
    show_status
else
    control_listener "$1" "$2"
fi
