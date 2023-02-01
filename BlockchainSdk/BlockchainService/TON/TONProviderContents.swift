//
//  TONProviderContent.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TONWalletInfo: Codable {
    
    /// Is chain transaction wallet
    let wallet: Bool
    
    /// Balance in string value
    let balance: String
    
    /// State of wallet
    let account_state: String
    
    /// Sequence number transations
    let seqno: Int
    
    /// Identifier type wallet
    let wallet_id: UInt
    
    /// Type of wallet
    let wallet_type: String
    
}

struct TONFee: Codable {
    
    struct SourceFees: Codable {
        /// Is a charge for importing messages from outside the blockchain.
        /// Every time you make a transaction, it must be delivered to the validators who will process it.
        let in_fwd_fee: Decimal
        
        /// Is the amount you pay for storing a smart contract in the blockchain.
        /// In fact, you pay for every second the smart contract is stored on the blockchain.
        let storage_fee: Decimal
        
        /// Is the amount you pay for executing code in the virtual machine.
        /// The larger the code, the more fees must be paid.
        let gas_fee: Decimal
        
        /// Stands for a charge for sending messages outside the TON
        let fwd_fee: Decimal
    }
    
    // MARK: - Properties
    
    /// Fees model
    let source_fees: SourceFees
    
}

struct TONSendBoc: Codable {}

struct TONSeqno: Codable {
    
    struct Stack: Codable {
        let num: String
    }
    
    // MARK: - Properties
    
    /// Container seqno number
    let stack: [[Stack]]
    
}