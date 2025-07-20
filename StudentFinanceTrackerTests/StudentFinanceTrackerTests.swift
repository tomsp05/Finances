//
//  StudentFinanceTrackerTests.swift
//  StudentFinanceTrackerTests
//
//  Created by Tom Speake on 4/14/25.
//

import Testing
@testable import StudentFinanceTracker

struct StudentFinanceTrackerTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testPoolAssignmentFunctionality() async throws {
        // Test pool assignment functionality
        let viewModel = FinanceViewModel()
        
        // Create a test account
        let testAccount = Account(name: "Test Account", type: .current, initialBalance: 1000.0)
        viewModel.accounts.append(testAccount)
        
        // Create test pools
        let testPools = [
            Pool(name: "Savings Pool", amount: 500.0, color: "Blue"),
            Pool(name: "Bills Pool", amount: 300.0, color: "Red")
        ]
        viewModel.saveAccountPools(testAccount.id, pools: testPools)
        
        // Create a test transaction
        let testTransaction = Transaction(
            date: Date(),
            amount: 100.0,
            description: "Test Transaction",
            fromAccount: .current,
            toAccount: nil,
            fromAccountId: testAccount.id,
            toAccountId: nil,
            type: .expense,
            categoryId: UUID()
        )
        viewModel.transactions.append(testTransaction)
        
        // Test that pools can be loaded
        let loadedPools = viewModel.getAccountPools(testAccount.id)
        #expect(loadedPools?.count == 2)
        #expect(loadedPools?.first?.name == "Savings Pool")
        
        // Test pool assignment
        var updatedTransaction = testTransaction
        updatedTransaction.poolId = testPools.first?.id
        viewModel.updateTransaction(updatedTransaction)
        
        // Verify assignment worked
        let assignedTransactions = viewModel.getTransactionsForPool(testPools.first?.id ?? UUID())
        #expect(assignedTransactions.count >= 1)
    }
    
    @Test func testTransactionFilterWithPools() async throws {
        // Test that our new pool filtering works
        let filterState = TransactionFilterState()
        
        // Test initial state
        #expect(filterState.selectedPools.isEmpty)
        #expect(!filterState.hasActiveFilters)
        
        // Test with pool filter added
        var modifiedFilter = filterState
        modifiedFilter.selectedPools.insert(UUID())
        #expect(modifiedFilter.hasActiveFilters)
        #expect(!modifiedFilter.selectedPools.isEmpty)
    }

}
