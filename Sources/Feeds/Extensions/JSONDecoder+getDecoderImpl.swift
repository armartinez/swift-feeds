//
//  JSONDecoder+GetDecoderImpl.swift
//  swift-feeds
//
//  Created by Axel Martinez on 8/11/24.
//

import Foundation
import _FoundationEssentials

extension _FoundationEssentials.JSONDecoder {
    func getDecoderImpl(from data: Data) throws -> JSONDecoderImpl {
        return try Self.withUTF8Representation(of: data) { utf8Buffer -> JSONDecoderImpl in
            let map: JSONMap
            if self.allowsJSON5 {
                var scanner = JSON5Scanner(bytes: utf8Buffer, options: self.json5ScannerOptions)
                map = try scanner.scan()
            } else {
                var scanner = JSONScanner(bytes: utf8Buffer, options: self.scannerOptions)
                map = try scanner.scan()
            }
            let topValue = map.loadValue(at: 0)!
            let decoder = JSONDecoderImpl(userInfo: self.userInfo, from: map, codingPathNode: .root, options: self.options)
            
            decoder.push(value: topValue)
            
            return decoder
        }
    }
}
