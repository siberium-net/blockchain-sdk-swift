//
//  NowNodesBTCProvider.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BitcoinNowNodesProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    var host: String {
        ""
    }

    private let apiKey: String
    private let provider: NetworkProvider<BitcoinNowNodesTarget>
    
    init(configuration: NetworkProviderConfiguration, apiKey: String) {
        self.apiKey = apiKey
        self.provider = NetworkProvider<BitcoinNowNodesTarget>(configuration: configuration)
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        addressData(walletAddress: address)
            .tryMap { addressResponse in
                let transactions = addressResponse.transactions
                let unspentOutputs = transactions
                    .map { response in
                        var outputs = [BitcoinUnspentOutput]()
                        let filteredResponse = response.vout.filter({ $0.addresses.contains(address) && $0.spent == nil })
                        filteredResponse.forEach {
                            outputs.append(BitcoinUnspentOutput(transactionHash: response.blockHash, outputIndex: $0.n, amount: UInt64($0.value) ?? 0, outputScript: ""))
                            
                        }
                        return outputs
                    }
                    .reduce([BitcoinUnspentOutput](), +)
                
                let pendingRefs = addressResponse.transactions
                    .filter({ $0.confirmations == 0 })
                    .map { tx in
                        var source: String = .unknown
                        var destination: String = .unknown
                        var value: Decimal?
                        var isIncoming: Bool = false
                        
                        if let _ = tx.vin.first(where: { $0.addresses.contains(address) }), let txDestination = tx.vout.first(where: { $0.addresses.contains(address) }) {
                            destination = txDestination.addresses.first ?? .unknown
                            source = address
                            value = Decimal(string: txDestination.value) ?? 0
                        } else if let txDestination = tx.vout.first(where: { $0.addresses.contains(address) }), let txSources = tx.vin.first(where: { $0.addresses.contains(address) }) {
                            isIncoming = true
                            destination = address
                            source = txSources.addresses.first ?? .unknown
                            value = Decimal(string: txDestination.value) ?? 0
                        }
                        
                        let bitcoinInputs = tx.vin.compactMap { input in
                            BitcoinInput(sequence: input.sequence, address: address, outputIndex: input.n, outputValue: 0, prevHash: input.hex)
                        }
                        
                        return PendingTransaction(hash: tx.hex,
                                                  destination: destination,
                                                  value: (value ?? 0) / Blockchain.bitcoin(testnet: false).decimalValue,
                                                  source: source,
                                                  fee: Decimal(string: tx.fees),
                                                  date: Date(), // ???
                                                  isIncoming: isIncoming,
                                                  transactionParams: BitcoinTransactionParams(inputs: bitcoinInputs))
                    }
                
                return BitcoinResponse(balance: Decimal(string: addressResponse.balance) ?? 0, hasUnconfirmed: addressResponse.unconfirmedTxs != 0, pendingTxRefs: pendingRefs, unspentOutputs: unspentOutputs)
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        provider
            .requestPublisher(BitcoinNowNodesTarget(endpoint: .fees, apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockchainInfoFeeResponse.self)
            .tryMap { response throws -> BitcoinFee in
                let min = Decimal(response.regular)
                let normal = (Decimal(response.regular) * Decimal(1.2)).rounded(roundingMode: .down)
                let priority = Decimal(response.priority)
                
                return BitcoinFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: normal, prioritySatoshiPerByte: priority)
            }
            .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        provider
            .requestPublisher(BitcoinNowNodesTarget(endpoint: .send(txHex: transaction), apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        send(transaction: transaction)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> { // TODO: ??
        Just(0)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func addressData(walletAddress: String) -> AnyPublisher<BitcoinNowNodesAddressResponse, Error> {
        provider
            .requestPublisher(BitcoinNowNodesTarget(endpoint: .address(walletAddress: walletAddress), apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BitcoinNowNodesAddressResponse.self)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func unspentTxData(walletAddress: String) -> AnyPublisher<[BitcoinNowNodesUnspentTxResponse], Error> {
        provider
            .requestPublisher(BitcoinNowNodesTarget(endpoint: .txUnspents(walletAddress: walletAddress), apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map([BitcoinNowNodesUnspentTxResponse].self)
            .eraseError()
            .eraseToAnyPublisher()
    }
}
