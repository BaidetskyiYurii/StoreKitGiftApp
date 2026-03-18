//
//  StoreKitManager.swift
//  StoreKitGiftApp
//
//  Created by Baidetskyi Yurii on 23.12.2024.
//

import Foundation
import StoreKit

public enum PurchaseState {
    case purchased
    case pending
    case cancelled
    case failed
    
    var alertTitle: String {
        switch self {
        case .purchased:
            "Success"
        case .pending:
            "Oops..."
        case .cancelled:
            "Error"
        case .failed:
            "Failed"
        }
    }
    
    var alertMessage: String {
        switch self {
        case .purchased:
            "Product was successfully purchased"
        case .pending:
            "Some action is pending"
        case .cancelled:
            "Purchase was cancelled"
        case .failed:
            "Something went wrong"
        }
    }
}

public enum StoreError: Error {
    case failedVerification
}

final class StoreKitManager: ObservableObject {
    @Published private(set) var purchasedProducts : [Product] = []
    
    @Published private(set) var nonConsumableProducts: [Product] = []
    @Published private(set) var consumableProducts: [Product] = []
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    @Published private(set) var purchasedState: PurchaseState = .cancelled
    @Published public var isShowAlert: Bool = false
    
    var updateListenerTask: Task<Void, Never>? = nil
    
    //maintain a plist of products
    let productIds: [String] = [
        "com.volpis.StoreKitGiftApp.newYearGift1",
        "com.volpis.StoreKitGiftApp.adsFree",
        "com.volpis.StoreKitGiftApp.monthly",
        "com.volpis.StoreKitGiftApp.yearly"
    ]
    
    init() {
        updateListenerTask = listenForTransactions()
        
        //create async operation
        Task {
            await requestProducts()
            
            //deliver the products that the customer purchased
            try await updateCustomerProductStatus()
        }
        
    }
    
    //denit transaction listener on exit or app close
    deinit {
        updateListenerTask?.cancel()
    }
    
    //listen for transactions - start this early in the app
    func listenForTransactions() -> Task<Void, Never> {
        return Task { [weak self] in
            guard let self else { return }
            
            // Iterate through any transactions that don't come from a direct call to 'purchase()'
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    print("listenForTransactions \(transaction)")
                    
                    // The transaction is verified, deliver the content to the user
                    try await self.updateCustomerProductStatus()
                    
                    if transaction.productType == .consumable {
                        if let gift = self.consumableProducts.first(where: { $0.id == transaction.productID }) {
                            await MainActor.run { [weak self] in
                                guard let self = self else { return }
                                AppConfig.giftWasBought = true
                                self.purchasedProducts.append(gift)
                            }
                        } else {
                            print("Consumable item was not found")
                        }
                    }
                    
                    // Always finish a transaction
                    await transaction.finish()
                } catch {
                    // StoreKit has a transaction that fails verification, don't deliver content to the user
                    print("Transaction failed verification \(error)")
                }
            }
            
            for await result in Transaction.unfinished {
                print("unfinished result \(result)")
            }
        }
    }
    
    // request the products in the background
    @MainActor
    func requestProducts() async {
        do {
            //using the Product static method products to retrieve the list of products
            let allProducts = try await Product.products(for: productIds)
            
            for product in allProducts {
                switch product.type {
                case .autoRenewable:
                    subscriptions.append(product)
                case .consumable:
                    consumableProducts.append(product)
                case .nonConsumable:
                    nonConsumableProducts.append(product)
                default: break
                }
            }
        } catch {
            print("Failed - error retrieving products \(error)")
        }
    }
    
    //Generics - check the verificationResults
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //check if JWS passes the StoreKit verification
        switch result {
        case .unverified:
            //failed verificaiton
            throw StoreError.failedVerification
        case .verified(let signedType):
            //the result is verified, return the unwrapped value
            return signedType
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async throws {
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: {$0.id == transaction.productID}) {
                        
                        if !purchasedSubscriptions.contains(where: { $0.id == subscription.id}) {
                            purchasedSubscriptions.append(subscription)
                        }
                        
                        print(purchasedSubscriptions.count)
                    }
                case .nonConsumable:
                    if let adsFree = nonConsumableProducts.first(where: { $0.id == transaction.productID}) {
                        purchasedProducts.append(adsFree)
                    }
                    
                case .consumable:
                    // should handle consumable manualy
                    break
                default:
                    break
                }
                //Always finish a transaction.
                await transaction.finish()
            } catch {
                print("failed updating products")
                throw error
            }
        }
    }
    
    @MainActor
    func purchase(_ product: Product) async throws -> Transaction? {
        // Make a purchase request
        let result = try await product.purchase()
        
        // Check the result
        switch result {
        case .success(let verificationResult):
            do {
                // Verify the transaction using JWT
                let transaction = try checkVerified(verificationResult)
                
                // Deliver the content to the user
                try await updateCustomerProductStatus()
                
                
                if transaction.productType == .consumable {
                    if let gift = consumableProducts.first(where: { $0.id == transaction.productID }) {
                        AppConfig.giftWasBought = true
                        purchasedProducts.append(gift)
                    } else {
                        print("Consumable item was not found")
                    }
                }
                
                // Always finish the transaction to avoid duplicates
                await transaction.finish()
                
                print("Transaction completed: \(transaction)")
                purchasedState = .purchased
                isShowAlert = true
                return transaction
            } catch {
                print("Error verifying transaction: \(error.localizedDescription)")
                purchasedState = .failed
                isShowAlert = true
                throw error
            }
        case .userCancelled:
            // Handle when the user cancels the purchase
            print("Purchase cancelled by user.")
            purchasedState = .cancelled
            isShowAlert = true
            return nil
            
        case .pending:
            // Handle pending purchases (e.g., approvals or family sharing)
            print("Purchase is pending. Awaiting further action.")
            purchasedState = .pending
            isShowAlert = true
            return nil
            
        @unknown default:
            // Handle any future cases introduced by Apple
            print("Unhandled case detected. Please update the code.")
            purchasedState = .failed
            isShowAlert = true
            return nil
        }
    }
    
    func isPurchased(_ product: Product) -> Bool {
        return purchasedProducts.contains(product)
    }
}
