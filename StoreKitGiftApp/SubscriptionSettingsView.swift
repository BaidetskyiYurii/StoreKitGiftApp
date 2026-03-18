//
//  SubscriptionSettingsView.swift
//  StoreKitGiftApp
//
//  Created by Baidetskyi Yurii on 05.01.2025.
//

import SwiftUI
import StoreKit

struct SubscriptionSettingsView: View {
    @State private var showManageSubscriptions = false
    
    var body: some View {
        VStack {
            Text("Premium content was purchased!")
                .foregroundStyle(.white)
                .font(.title2)
                .padding(.vertical)
            
            Text("Manage your subscription")
                .foregroundStyle(.white)
                .font(.headline)
                .padding()
            
            Button("Cancel Subscription") {
                showManageSubscriptions = true
            }
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(8)
            .padding()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .foregroundColor(Color.indigo)
        }
        .padding(20)
        .padding(.top, 20)
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
    }
}

#Preview {
    SubscriptionSettingsView()
}
