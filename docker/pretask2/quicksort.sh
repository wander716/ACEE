#!/bin/bash

# 快速排序函数
quick_sort() {
    local arr=("$@")  # 传入数组
    local len=${#arr[@]}

    # 递归结束条件
    if [ "$len" -le 1 ]; then
        echo "${arr[@]}"
        return
    fi

    # 选取基准值（这里取第一个元素）
    local pivot=${arr[0]}
    local left=()
    local right=()

    # 分区
    for ((i = 1; i < len; i++)); do
        if [ "${arr[i]}" -lt "$pivot" ]; then
            left+=("${arr[i]}")
        else
            right+=("${arr[i]}")
        fi
    done

    # 递归排序并合并结果
    echo "$(quick_sort "${left[@]}") $pivot $(quick_sort "${right[@]}")"
}

# 示例数组
numbers=(34 7 23 32 5 62)
echo "原始数组: ${numbers[@]}"
sorted_numbers=($(quick_sort "${numbers[@]}"))
echo "排序后的数组: ${sorted_numbers[@]}"
