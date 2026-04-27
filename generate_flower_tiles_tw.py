#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
台灣麻將花牌 SVG 生成腳本 - 手工繪製花卉圖案
春夏秋冬 + 梅蘭竹菊
"""

from pathlib import Path

# 花牌設計定義
FLOWERS = {
    '1': {
        'cn': '春', 'en': 'Spring', 'color': '#FF69B4',
        'flower': '''
        <!-- 梅花 - 春 -->
        <circle cx="50" cy="40" r="12" fill="#FF69B4" opacity="0.3"/>
        <circle cx="50" cy="40" r="3" fill="#FF1493"/>
        <circle cx="50" cy="28" r="4" fill="#FF69B4"/>
        <circle cx="62" cy="35" r="4" fill="#FF69B4"/>
        <circle cx="62" cy="45" r="4" fill="#FF69B4"/>
        <circle cx="38" cy="45" r="4" fill="#FF69B4"/>
        <circle cx="38" cy="35" r="4" fill="#FF69B4"/>
        <!-- 枝葉 -->
        <path d="M 50 52 Q 45 65 40 75" stroke="#228B22" stroke-width="2" fill="none"/>
        <ellipse cx="35" cy="78" rx="3" ry="5" fill="#228B22" transform="rotate(-30 35 78)"/>
        '''
    },
    '2': {
        'cn': '夏', 'en': 'Summer', 'color': '#FFD700',
        'flower': '''
        <!-- 荷花 - 夏 -->
        <circle cx="50" cy="40" r="14" fill="#FFD700" opacity="0.2"/>
        <!-- 花瓣 -->
        <ellipse cx="50" cy="27" rx="5" ry="8" fill="#FFD700"/>
        <ellipse cx="63" cy="33" rx="5" ry="8" fill="#FFD700" transform="rotate(60 63 33)"/>
        <ellipse cx="63" cy="47" rx="5" ry="8" fill="#FFD700" transform="rotate(120 63 47)"/>
        <ellipse cx="50" cy="53" rx="5" ry="8" fill="#FFD700"/>
        <ellipse cx="37" cy="47" rx="5" ry="8" fill="#FFD700" transform="rotate(-120 37 47)"/>
        <ellipse cx="37" cy="33" rx="5" ry="8" fill="#FFD700" transform="rotate(-60 37 33)"/>
        <!-- 中心 -->
        <circle cx="50" cy="40" r="5" fill="#FF8C00"/>
        <!-- 葉 -->
        <path d="M 50 55 Q 48 65 45 75" stroke="#228B22" stroke-width="2" fill="none"/>
        '''
    },
    '3': {
        'cn': '秋', 'en': 'Autumn', 'color': '#FF8C00',
        'flower': '''
        <!-- 菊花 - 秋 -->
        <circle cx="50" cy="40" r="3" fill="#FF6347"/>
        <!-- 外層花瓣 -->
        <circle cx="50" cy="20" r="3" fill="#FF8C00"/>
        <circle cx="65" cy="28" r="3" fill="#FF8C00"/>
        <circle cx="65" cy="42" r="3" fill="#FF8C00"/>
        <circle cx="50" cy="60" r="3" fill="#FF8C00"/>
        <circle cx="35" cy="52" r="3" fill="#FF8C00"/>
        <circle cx="35" cy="28" r="3" fill="#FF8C00"/>
        <!-- 中層花瓣 -->
        <circle cx="57" cy="24" r="3" fill="#FFA500"/>
        <circle cx="60" cy="35" r="3" fill="#FFA500"/>
        <circle cx="58" cy="50" r="3" fill="#FFA500"/>
        <circle cx="42" cy="54" r="3" fill="#FFA500"/>
        <circle cx="40" cy="40" r="3" fill="#FFA500"/>
        <circle cx="42" cy="26" r="3" fill="#FFA500"/>
        <!-- 葉 -->
        <path d="M 50 60 Q 52 70 50 80" stroke="#228B22" stroke-width="2" fill="none"/>
        '''
    },
    '4': {
        'cn': '冬', 'en': 'Winter', 'color': '#FFFFFF',
        'flower': '''
        <!-- 梅花 - 冬（白色） -->
        <circle cx="50" cy="40" r="10" fill="#E0E0E0"/>
        <circle cx="50" cy="40" r="3" fill="#FFD700"/>
        <!-- 五瓣 -->
        <circle cx="50" cy="28" r="4" fill="#F0F8FF"/>
        <circle cx="62" cy="34" r="4" fill="#F0F8FF"/>
        <circle cx="58" cy="48" r="4" fill="#F0F8FF"/>
        <circle cx="42" cy="48" r="4" fill="#F0F8FF"/>
        <circle cx="38" cy="34" r="4" fill="#F0F8FF"/>
        <!-- 雪花邊 -->
        <circle cx="50" cy="28" r="4" fill="none" stroke="#B0C4DE" stroke-width="1"/>
        <!-- 枝 -->
        <path d="M 50 52 Q 48 65 46 75" stroke="#696969" stroke-width="2" fill="none"/>
        '''
    },
    '5': {
        'cn': '梅', 'en': 'Plum', 'color': '#DC143C',
        'flower': '''
        <!-- 梅花 - 五瓣紅梅 -->
        <circle cx="50" cy="40" r="2" fill="#8B0000"/>
        <!-- 花瓣 -->
        <ellipse cx="50" cy="25" rx="5" ry="7" fill="#DC143C"/>
        <ellipse cx="62" cy="32" rx="5" ry="7" fill="#DC143C" transform="rotate(72 62 32)"/>
        <ellipse cx="60" cy="50" rx="5" ry="7" fill="#DC143C" transform="rotate(144 60 50)"/>
        <ellipse cx="40" cy="52" rx="5" ry="7" fill="#DC143C" transform="rotate(216 40 52)"/>
        <ellipse cx="38" cy="32" rx="5" ry="7" fill="#DC143C" transform="rotate(288 38 32)"/>
        <!-- 中心 -->
        <circle cx="50" cy="40" r="4" fill="#FFD700"/>
        <!-- 枝葉 -->
        <path d="M 50 52 Q 46 68 42 80" stroke="#2F4F4F" stroke-width="2" fill="none"/>
        <ellipse cx="38" cy="82" rx="3" ry="4" fill="#228B22"/>
        '''
    },
    '6': {
        'cn': '蘭', 'en': 'Orchid', 'color': '#9932CC',
        'flower': '''
        <!-- 蘭花 - 優雅紫蘭 -->
        <!-- 花瓣 -->
        <ellipse cx="50" cy="25" rx="6" ry="9" fill="#9932CC"/>
        <ellipse cx="50" cy="50" rx="5" ry="8" fill="#9932CC"/>
        <ellipse cx="38" cy="38" rx="4" ry="7" fill="#9932CC" transform="rotate(-40 38 38)"/>
        <ellipse cx="62" cy="38" rx="4" ry="7" fill="#9932CC" transform="rotate(40 62 38)"/>
        <!-- 中心唇瓣 -->
        <ellipse cx="50" cy="42" rx="4" ry="5" fill="#DA70D6"/>
        <ellipse cx="50" cy="43" rx="2" ry="2" fill="#FFD700"/>
        <!-- 莖 -->
        <path d="M 50 58 Q 49 70 48 80" stroke="#228B22" stroke-width="2" fill="none"/>
        <path d="M 48 75 L 45 72" stroke="#228B22" stroke-width="1" fill="none"/>
        '''
    },
    '7': {
        'cn': '竹', 'en': 'Bamboo', 'color': '#228B22',
        'flower': '''
        <!-- 竹子 - 綠竹葉 -->
        <!-- 主莖 -->
        <rect x="48" y="20" width="4" height="60" fill="#2F4F4F"/>
        <!-- 竹節 -->
        <line x1="47" y1="35" x2="53" y2="35" stroke="#1C1C1C" stroke-width="1"/>
        <line x1="47" y1="50" x2="53" y2="50" stroke="#1C1C1C" stroke-width="1"/>
        <!-- 葉子 -->
        <ellipse cx="40" cy="30" rx="3" ry="8" fill="#228B22" transform="rotate(-45 40 30)"/>
        <ellipse cx="60" cy="30" rx="3" ry="8" fill="#228B22" transform="rotate(45 60 30)"/>
        <ellipse cx="38" cy="45" rx="3" ry="8" fill="#228B22" transform="rotate(-50 38 45)"/>
        <ellipse cx="62" cy="45" rx="3" ry="8" fill="#228B22" transform="rotate(50 62 45)"/>
        <ellipse cx="40" cy="60" rx="3" ry="8" fill="#3CB371" transform="rotate(-40 40 60)"/>
        <ellipse cx="60" cy="60" rx="3" ry="8" fill="#3CB371" transform="rotate(40 60 60)"/>
        '''
    },
    '8': {
        'cn': '菊', 'en': 'Chrysanthemum', 'color': '#FFD700',
        'flower': '''
        <!-- 菊花 - 黃金菊 -->
        <!-- 中心 -->
        <circle cx="50" cy="40" r="4" fill="#FF8C00"/>
        <!-- 花瓣層層 -->
        <circle cx="50" cy="20" r="2.5" fill="#FFD700"/>
        <circle cx="65" cy="27" r="2.5" fill="#FFD700"/>
        <circle cx="70" cy="40" r="2.5" fill="#FFD700"/>
        <circle cx="65" cy="53" r="2.5" fill="#FFD700"/>
        <circle cx="50" cy="60" r="2.5" fill="#FFD700"/>
        <circle cx="35" cy="53" r="2.5" fill="#FFD700"/>
        <circle cx="30" cy="40" r="2.5" fill="#FFD700"/>
        <circle cx="35" cy="27" r="2.5" fill="#FFD700"/>
        <!-- 第二層 -->
        <circle cx="57" cy="24" r="2" fill="#FFA500"/>
        <circle cx="68" cy="32" r="2" fill="#FFA500"/>
        <circle cx="68" cy="48" r="2" fill="#FFA500"/>
        <circle cx="57" cy="56" r="2" fill="#FFA500"/>
        <circle cx="43" cy="56" r="2" fill="#FFA500"/>
        <circle cx="32" cy="48" r="2" fill="#FFA500"/>
        <circle cx="32" cy="32" r="2" fill="#FFA500"/>
        <circle cx="43" cy="24" r="2" fill="#FFA500"/>
        <!-- 葉 -->
        <path d="M 50 62 Q 52 73 50 83" stroke="#228B22" stroke-width="2" fill="none"/>
        '''
    }
}

def generate_flower_svg(num, data):
    """生成花牌 SVG"""
    svg = f'''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 120">
  <!-- 牌背 -->
  <rect width="100" height="120" fill="white" stroke="#333333" stroke-width="1.5" rx="3"/>
  
  <!-- 牌面背景 -->
  <rect x="3" y="3" width="94" height="114" fill="#f9f9f9" rx="2"/>
  
  <!-- 花牌裝飾邊框 -->
  <rect x="8" y="8" width="84" height="104" fill="none" stroke="{data['color']}" stroke-width="2"/>
  <rect x="10" y="10" width="80" height="100" fill="none" stroke="{data['color']}" stroke-width="0.5" opacity="0.5"/>
  
  <!-- 花卉圖案 -->
  <g>
    {data['flower']}
  </g>
  
  <!-- 花牌名稱（下方） -->
  <text x="50" y="100" font-family="serif" font-size="12" font-weight="bold" 
        text-anchor="middle" fill="#333333">{data['cn']}</text>
  
  <!-- 英文名稱 -->
  <text x="50" y="115" font-family="serif" font-size="8" 
        text-anchor="middle" fill="#666666" opacity="0.6">{data['en']}</text>
</svg>
'''
    return svg

def main():
    output_dir = Path('./assets/tiles')
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"輸出目錄: {output_dir}")
    print("="*60)
    
    for num, data in FLOWERS.items():
        svg_content = generate_flower_svg(num, data)
        filepath = output_dir / f"flower{num}.svg"
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(svg_content)
        
        print(f"✓ flower{num}.svg - {data['cn']} ({data['en']})")
    
    print("="*60)
    print(f"\n✅ 已生成 8 張花牌 SVG 檔案\n")

if __name__ == '__main__':
    main()
