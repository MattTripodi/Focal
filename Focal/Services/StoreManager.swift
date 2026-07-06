//
//  StoreManager.swift
//  Focal
//
//  Created by Matthew Tripodi on 7/5/26.
//

import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class StoreManager {

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var isPremium: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var purchaseError: String? = nil

    // MARK: - Constants

    static let premiumProductID = "com.matthewtripodi.focal.premium"

    // MARK: - Init

    init() {
        Task {
            await loadProducts()
            await refreshPurchaseStatus()
            await listenForTransactions()
        }
    }

    // MARK: - Products

//    func loadProducts() async {
//        isLoading = true
//        defer { isLoading = false }
//        do {
//            products = try await Product.products(for: [Self.premiumProductID])
//        } catch {
//            print("[Store] Failed to load products: \(error)")
//        }
//    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [Self.premiumProductID])
            print("[Store] Loaded \(products.count) product(s): \(products.map(\.id))")
        } catch {
            purchaseError = "Failed to load products: \(error.localizedDescription)"
            print("[Store] loadProducts error: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = products.first else {
            purchaseError = "Product unavailable. Try again later."
            return
        }

        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPremium = true
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Status

    func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                isPremium = true
                return
            }
        }
        isPremium = false
    }

    // MARK: - Transaction Listener

    /// Listens for transactions that complete outside the app
    /// (e.g. Ask to Buy approvals, subscription renewals).
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.premiumProductID {
                await transaction.finish()
                await refreshPurchaseStatus()
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):   return value
        case .unverified(_, let e): throw e
        }
    }

    // MARK: - Formatted Price

    var premiumPrice: String {
        products.first?.displayPrice ?? "$2.99"
    }
}
