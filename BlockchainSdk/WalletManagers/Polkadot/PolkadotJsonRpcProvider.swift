//
//  PolkadotJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class PolkadotJsonRpcProvider: HostProvider {
    let host: String
    private let network: PolkadotNetwork
    private let provider: MoyaProvider<PolkadotTarget> = .init(plugins: [NetworkLoggerPlugin()])
    
    init(network: PolkadotNetwork) {
        self.network = network
        self.host = network.url.hostOrUnknown
    }
    
    func blockhash(_ type: PolkadotBlockhashType) -> AnyPublisher<String, Error> {
        requestPublisher(for: .blockhash(type: type, network: network))
    }
    
    func accountNextIndex(_ address: String) -> AnyPublisher<Int, Error> {
        requestPublisher(for: .accountNextIndex(address: address, network: network))
    }
    
    func runtimeVersion() -> AnyPublisher<PolkadotRuntimeVersion, Error> {
        requestPublisher(for: .runtimeVersion(network: network))
    }
    
#warning("TODO")
    func submitExtrinsic(_ extrinsic: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .submitExtrinsic(extrinsic: extrinsic, network: network))
    }
    
    private func requestPublisher<T: Codable>(for target: PolkadotTarget) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(PolkadotJsonRpcResponse<T>.self)
            .map(\.result)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
