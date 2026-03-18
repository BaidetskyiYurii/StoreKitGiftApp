//
//  AllProductView.swift
//  StoreKitGiftApp
//
//  Created by Baidetskyi Yurii on 23.12.2024.
//

import SwiftUI
import StoreKit

struct AllProductView: View {
    @StateObject var storeKit = StoreKitManager()
    
    @State private var selectedSubscriptionProduct: Product?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                giftView
                
                subscriptionsView
            }
        }
        .background(Color.black)
        .alert(storeKit.purchasedState.alertTitle, isPresented: $storeKit.isShowAlert) {
            Button("OK", role: .cancel) {
                withAnimation {
                    storeKit.isShowAlert = false
                }
            }
        } message: {
            Text(storeKit.purchasedState.alertMessage)
        }
        .onChange(of: storeKit.isShowAlert) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        storeKit.isShowAlert = false
                    }
                }
            }
        }
        .onChange(of: storeKit.purchasedSubscriptions) { newValue in
            print("new purchasedSubscriptions \(newValue.count)")
        }
    }
}

private extension AllProductView {
    
    @ViewBuilder
    var adsFree: some View {
        if let adsFreeProduct = storeKit.nonConsumableProducts.first {
            let isPurchased = storeKit.isPurchased(adsFreeProduct)
            HStack {
                Spacer()
                
                Button {
                    if !isPurchased {
                        Task {
                            try await storeKit.purchase(adsFreeProduct)
                        }
                    }
                } label: {
                    Text(isPurchased ? "ADs Free plan was bought successfully" : "Buy ADs Free app for $\(adsFreeProduct.price)")
                        .foregroundStyle(.white)
                        .font(.headline)
                        .padding(10)
                        .background(Color.indigo)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    var giftView: some View {
        if let gift = storeKit.consumableProducts.first {
            let isPurchased = AppConfig.giftWasBought
            
            Image(.gift)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 350,
                       height: 450)
                .overlay(alignment: .top) {
                    adsFree
                }
                .overlay(alignment: .bottom) {
                    Button {
                        if !isPurchased {
                            Task {
                                try await storeKit.purchase(gift)
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            
                            Text(isPurchased ? "New Year's gift was bought successfully!" : "Buy New Year's gift for only $\(gift.price)")
                                .bold()
                                .foregroundStyle(.white)
                                .padding(5)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                    }
                    .frame(height: 70)
                    .background(Color.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal, 40)
                }
        }
    }
    
    func createSubscriptionButton(for product: Product) -> some View {
        let isSelected = selectedSubscriptionProduct == product
        return Button {
            withAnimation {
                selectedSubscriptionProduct = product
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.displayName)
                        .font(.title)
                        .foregroundStyle(.white)
                    
                    Text(product.displayPrice)
                        .font(isSelected ? .headline : .subheadline)
                        .foregroundStyle(isSelected ? .blue : .white)
                    
                    if let introductoryOffer = product.subscription?.introductoryOffer {
                        Text("Try \(introductoryOffer.period) free")
                            .font(isSelected ? .headline : .subheadline)
                            .foregroundStyle(isSelected ? .purple : .white)
                    }
                    
                    Spacer()
                }
                .frame(height: 100)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .indigo : .white, lineWidth: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    var subscriptionsView: some View {
        if storeKit.purchasedSubscriptions.isEmpty {
            HStack(spacing: 10) {
                ForEach(storeKit.subscriptions) { subscription in
                    createSubscriptionButton(for: subscription)
                }
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            
            Button {
                if let selectedSubscriptionProduct {
                    Task {
                        try await storeKit.purchase(selectedSubscriptionProduct)
                    }
                }
            } label: {
                let subscriptionInfo = selectedSubscriptionProduct?.description
                let defaultText = "Select plan and subscribe"
                Text(subscriptionInfo ?? defaultText)
                    .foregroundStyle(.white)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(15)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .foregroundColor(Color.purple)
                    }
                    .padding(.horizontal, 20)
            }
        } else {
            SubscriptionSettingsView()
        }
    }
}

#Preview {
    AllProductView()
}
