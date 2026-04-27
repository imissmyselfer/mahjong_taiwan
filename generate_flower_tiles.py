#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
台灣麻將花牌 SVG 生成腳本
產生 8 張花牌（春夏秋冬 + 梅蘭竹菊）
符合 riichi-mahjong-tiles 的尺寸和風格
"""

import os
from pathlib import Path

# 花牌定義
FLOWERS = {
    '1': ('春', 'Spring', '#FF6B6B'),      # 春 - 紅色
    '2': ('夏', 'Summer', '#FFD93D'),      # 夏 - 黃色
    '3': ('秋', 'Autumn', '#FF8C42'),      # 秋 - 橙色
    '4': ('冬', 'Winter', '#6BCB77'),      # 冬 - 綠色
    '5': ('梅', 'Plum', '#FF69B4'),        # 梅 - 粉紅
    '6': ('蘭', 'Orchid', '#9D84B7'),      # 蘭 - 紫色
    '7': ('竹', 'Bamboo', '#4D96FF'),      # 竹 - 藍色
    '8': ('菊', 'Chrysanthemum', '#FFD700') # 菊 - 金色
}

def generate_flower_svg(num, cn_name, en_name, color):
    """生成單張花牌 SVG"""
    
    svg_template = f'''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 120">
  <!-- 牌背 -->
  <rect width="100" height="120" fill="white" stroke="#333333" stroke-width="1.5" rx="3"/>
  
  <!-- 牌面背景（淡色） -->
  <rect x="3" y="3" width="94" height="114" fill="#f9f9f9" rx="2"/>
  
  <!-- 花牌裝飾邊框 -->
  <rect x="8" y="8" width="84" height="104" fill="none" stroke="{color}" stroke-width="2"/>
  <rect x="10" y="10" width="80" height="100" fill="none" stroke="{color}" stroke-width="0.5" opacity="0.5"/>
  
  <!-- 花朵圖案（簡約） -->
  <g id="flower-design">
    <!-- 中心圓形 -->
    <circle cx="50" cy="45" r="8" fill="{color}" opacity="0.8"/>
    
    <!-- 花瓣（5 瓣） -->
    <circle cx="50" cy="30" r="5" fill="{color}" opacity="0.6"/>
    <circle cx="63" cy="38" r="5" fill="{color}" opacity="0.6"/>
    <circle cx="58" cy="52" r="5" fill="{color}" opacity="0.6"/>
    <circle cx="42" cy="52" r="5" fill="{color}" opacity="0.6"/>
    <circle cx="37" cy="38" r="5" fill="{color}" opacity="0.6"/>
  </g>
  
  <!-- 花牌號碼（上方） -->
  <text x="50" y="75" font-family="serif" font-size="16" font-weight="bold" 
        text-anchor="middle" fill="#333333">{cn_name}</text>
  
  <!-- 英文名稱（下方） -->
  <text x="50" y="92" font-family="serif" font-size="10" 
        text-anchor="middle" fill="#666666" opacity="0.7">{en_name}</text>
  
  <!-- 版本標記 -->
  <text x="50" y="110" font-family="monospace" font-size="7" 
        text-anchor="middle" fill="#999999" opacity="0.5">FLOWER</text>
</svg>
'''
    return svg_template

def main():
    """主函式"""
    
    # 建立輸出目錄
    output_dir = Path.home() / 'Working/code/majong_taiwan_android/assets/tiles'
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"輸出目錄: {output_dir}")
    print("="*50)
    
    # 生成每張花牌
    for num, (cn_name, en_name, color) in FLOWERS.items():
        svg_content = generate_flower_svg(num, cn_name, en_name, color)
        
        # 檔案名稱遵循 riichi-mahjong-tiles 慣例
        filename = f"flower{num}.svg"
        filepath = output_dir / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(svg_content)
        
        print(f"✓ {filename:20} - {cn_name} ({en_name})")
    
    print("="*50)
    print(f"\n✅ 已生成 8 張花牌 SVG 檔案")
    print(f"位置: {output_dir}\n")
    
    # 列出生成的檔案
    print("生成的檔案:")
    for f in sorted(output_dir.glob('flower*.svg')):
        print(f"  - {f.name}")
    
    print("\n後續步驟:")
    print("1. 轉換 SVG 為 PNG（使用 inkscape 或 imagemagick）:")
    print(f"   for f in {output_dir}/flower*.svg; do")
    print(f"     convert -density 150 \"$f\" \"${{f%.svg}}.png\"")
    print("   done")
    print("\n2. 在 pubspec.yaml 中新增資源")
    print("3. 在遊戲代碼中引用花牌\n")

if __name__ == '__main__':
    main()
