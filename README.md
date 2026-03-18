# 🎁 StoreKitGiftApp — StoreKit 2 In-App Purchases Demo

> A focused iOS demo covering all three StoreKit product types — consumable, non-consumable, and auto-renewable subscriptions — with JWS transaction verification, real-time transaction listener, and subscription management.

![Platform](https://img.shields.io/badge/Platform-iOS%2016%2B-blue?style=flat)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple?style=flat)
![StoreKit](https://img.shields.io/badge/Framework-StoreKit%202-black?style=flat)

---

## 📱 What It Does

StoreKitGiftApp is a focused demo of the modern **StoreKit 2 API** — showing how to implement all three in-app purchase product types in a single app, with proper transaction verification and a persistent transaction listener running for the app's lifetime.

**Products implemented:**
- 🎁 **Consumable** — one-time New Year's gift purchase
- 🚫 **Non-consumable** — permanent Ads Free unlock
- 🔄 **Auto-renewable subscriptions** — Monthly and Yearly plans with introductory offer display

---

## ✨ Features

**StoreKit Core**
- `Product.products(for:)` async product fetching
- `product.purchase()` with full result handling (`.success`, `.userCancelled`, `.pending`, `@unknown default`)
- JWS transaction verification via `VerificationResult` — `checkVerified(_:)` generic helper
- `Transaction.updates` async sequence — real-time listener for external transactions (family sharing, renewals, refunds)
- `Transaction.currentEntitlements` — restores purchased products on launch
- `transaction.finish()` always called to prevent duplicate delivery

**Product Types**
- **Consumable** — tracked manually via `AppConfig.giftWasBought` (UserDefaults), since consumables don't appear in `currentEntitlements`
- **Non-consumable** — restored automatically via `currentEntitlements` on every launch
- **Auto-renewable subscriptions** — introductory offer period displayed, active subscription detected and gated

**Subscription Management**
- `.manageSubscriptionsSheet(isPresented:)` — native Apple subscription management sheet
- Active subscription state shows `SubscriptionSettingsView` instead of paywall

**Purchase State**
- `PurchaseState` enum with `.purchased`, `.pending`, `.cancelled`, `.failed`
- Auto-dismissing alert with state-specific title and message

**Custom `@propertyWrapper`**
- Generic `Storage<T: Codable>` property wrapper for type-safe `UserDefaults` persistence
- Used to persist consumable purchase state across launches

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|------------|
| Payments | StoreKit 2 — `Product`, `Transaction`, `VerificationResult` |
| UI Framework | SwiftUI |
| Persistence | Custom `@propertyWrapper` over `UserDefaults` |
| Async | `async/await`, `AsyncSequence` (`Transaction.updates`) |
| Min Deployment | iOS 16.0 |
| Swift | 5.9 |

---

## 🏗 Project Structure

```
StoreKitGiftApp/
├── StoreKitManager.swift          # All StoreKit 2 logic — fetch, purchase, verify, listen
├── AllProductView.swift           # Main UI — consumable, non-consumable, subscriptions
├── SubscriptionSettingsView.swift # Post-purchase subscription management screen
├── Storage.swift                  # Generic @propertyWrapper for UserDefaults
└── StoreKitGiftAppApp.swift       # @main entry point
```

---

## 🔑 Key Implementation Details

### Transaction Listener — started at init, cancelled at deinit
```swift
init() {
    updateListenerTask = listenForTransactions()
    Task {
        await requestProducts()
        try await updateCustomerProductStatus()
    }
}

deinit {
    updateListenerTask?.cancel()
}
```

### JWS Verification — generic helper
```swift
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified: throw StoreError.failedVerification
    case .verified(let signedType): return signedType
    }
}
```

### Consumable Handling
Consumables don't appear in `Transaction.currentEntitlements` — they must be tracked manually:
```swift
if transaction.productType == .consumable {
    AppConfig.giftWasBought = true
    purchasedProducts.append(gift)
}
```

### Custom UserDefaults Property Wrapper
```swift
@propertyWrapper
public struct Storage<T: Codable> {
    public var wrappedValue: T {
        get { /* JSONDecoder from UserDefaults */ }
        set { /* JSONEncoder to UserDefaults */ }
    }
}

// Usage
@Storage(key: "giftWasBought", defaultValue: false)
static public var giftWasBought: Bool
```

---

## 🚀 Getting Started

### Requirements
- Xcode 15+
- iOS 16.0+ simulator or device
- StoreKit configuration file (included in project) for sandbox testing

### Setup
```bash
git clone https://github.com/BaidetskyiYurii/StoreKitGiftApp.git
cd StoreKitGiftApp
open StoreKitGiftApp/StoreKitGiftApp.xcodeproj
```

> **Testing purchases:** Use the StoreKit configuration file in Xcode to test all product types in the simulator without a real App Store account.

---

## 💡 Why This Project

StoreKit 2 introduced a completely new async/await-based API in iOS 15 — replacing the delegate-heavy StoreKit 1 with a much cleaner model. This demo shows the full integration: fetching products, handling all purchase outcomes, verifying transactions cryptographically, and listening for background transaction updates. The consumable/non-consumable/subscription distinction requires different handling for each type, which is all covered here.

---

## 👨‍💻 Author

**Yurii Baidetskyi** — iOS Engineer  
[LinkedIn](https://linkedin.com/in/yuriibaidetskyi) · [GitHub](https://github.com/BaidetskyiYurii)
