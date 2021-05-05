//
//  EthereumResponse.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct EthereumInfoResponse {
    let balance: Decimal
    let tokenBalances: [Token: Decimal]
    let txCount: Int
    let pendingTxCount: Int
}

struct EthereumFeeResponse {
    let fees: [Decimal]
    let gasLimit: BigUInt
}

struct EthereumResponse: Codable {
    let jsonRpc: String
    let id: Int?
    let result: String?
    let error: EthereumError?
    
    private enum CodingKeys: String, CodingKey {
        case jsonRpc = "jsonrpc"
        case id, result, error
    }
}

struct EthereumError: Codable {
    let code: Int?
    let message: String?
    
    var error: Error {
        NSError(domain: message ?? .unknown, code: code ?? -1, userInfo: nil)
    }
}
