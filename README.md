# Jod-Hai 💚

> บันทึกรายรับ-รายจ่ายอัจฉริยะ · Smart Expense Tracker for iOS

![iOS](https://img.shields.io/badge/iOS-26.0+-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-blue)
![SwiftData](https://img.shields.io/badge/SwiftData-✓-purple)

---

## Features

### 💬 Chat NLP
บันทึกรายจ่ายด้วยการพิมพ์ภาษาธรรมชาติ ทั้งไทยและอังกฤษ
- แยก **จำนวนเงิน** จากรูปแบบหลากหลาย — `65`, `2k`, `สองพัน`, `฿1,500`
- แยก **หมวดหมู่** อัตโนมัติจาก keyword
- ถามข้อมูลเพิ่มเติมเมื่อไม่ครบ (amount / category)
- รองรับ **รายรับ** — เงินเดือน, Freelance, ธุรกิจ, ลงทุน
- Chat ตอบเป็นภาษาไทยเสมอ

### 📊 Dashboard
- ยอดรายจ่ายรวมทั้งหมดและเดือนนี้
- Bar chart 7 วันล่าสุด พร้อม average line
- Top categories ranking
- Smart insights อัตโนมัติ

### 📋 Expenses
- รายการรายจ่ายทั้งหมด พร้อม filter
- Swipe ซ้าย → แก้ไข / Swipe ขวา → ลบ
- สแกนใบเสร็จด้วย Vision OCR
- เพิ่มรายจ่ายผ่าน Siri / App Shortcuts

### 💰 Budget
- ตั้งงบประมาณรายเดือนแยกตามหมวดหมู่
- Progress bar แสดง % ที่ใช้ไป (เขียว / ส้ม / แดง)
- **Smart Budget** — คำนวณงบอัตโนมัติตามกฎ 50/30/20 จากรายรับ
- Local notification เมื่อใช้งบ 80% และเกินงบ

### 🌐 Language Settings
- สลับภาษา UI ระหว่าง **ภาษาไทย** และ **English** ได้ใน Settings
- ค่าที่เลือกจะถูกจำไว้ข้ามการเปิดแอพ

### 🏠 Widget
- Small widget — ยอดรายจ่ายวันนี้ + ปุ่ม Quick Log
- Medium widget — ยอดรายจ่ายวันนี้, เดือนนี้ และรายการล่าสุด 3 อัน
- Lock screen accessory widget

---

## Architecture

```
JodHai/
├── App/
│   ├── Assets.xcassets/         # App icon & assets
│   ├── Intents/                 # App Intents & Siri Shortcuts
│   └── JodHaiApp.swift
│
├── Domain/                      # Business logic (no framework dependencies)
│   ├── Entities/                # Expense, Income, Budget, ChatMessage
│   ├── Repositories/            # Protocol definitions
│   ├── Services/                # NLPExpenseParser
│   └── UseCases/
│
├── Data/                        # SwiftData persistence
│   ├── Models/                  # ExpenseModel, IncomeModel, BudgetModel (@Model)
│   └── Repositories/            # Repository implementations
│
└── Presentation/
    ├── Theme/                   # DesignSystem, LanguageManager
    ├── ViewModels/              # @Observable ViewModels (@MainActor)
    └── Views/
        ├── Dashboard/
        ├── Expenses/
        ├── Budget/
        ├── Chat/
        └── Settings/

JodHaiWidget/                    # WidgetKit extension
```

**Pattern:** Clean Architecture — Domain → Data → Presentation (one-way dependency)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6.0 (strict concurrency) |
| UI | SwiftUI + iOS 26 Liquid Glass |
| Persistence | SwiftData |
| Charts | Swift Charts |
| OCR | Vision Framework |
| Shortcuts | App Intents |
| Widget | WidgetKit |
| Notifications | UNUserNotificationCenter |
| Project | XcodeGen |

---

## Requirements

- Xcode 26 Beta+
- iOS 26.0+
- Swift 6.0

---

## Getting Started

```bash
# 1. Clone
git clone https://github.com/StellarBearX/JodHai-AI-IOS.git
cd JodHai-AI-IOS

# 2. Generate Xcode project
brew install xcodegen
xcodegen generate

# 3. Open in Xcode
open JodHai.xcodeproj
```

เลือก Development Team ใน **Signing & Capabilities** สำหรับทั้ง `JodHai` และ `JodHaiWidgetExtension` targets แล้วกด Run

---

## Author

**Kunanan Wongsing**
