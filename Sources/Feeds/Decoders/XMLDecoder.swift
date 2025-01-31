//
//  XMLDecoder.swift
//
//  Created by Axel Martinez on 2/7/24.
//

import Foundation
import _FoundationEssentials

typealias Options = _FoundationEssentials.JSONDecoder.Options

fileprivate struct _XMLKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    init(index: Int) {
        self.stringValue = "[\(index)]"
        self.intValue = index
    }
}

struct XMLDecoder {
    /// The root element
    fileprivate let element: XMLTag
    
    /// The root element
    fileprivate let namespace: String?
    
    /// Options set on the top-level decoder.
    fileprivate let options: Options
    
    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any]
    
    /// Initializes `self` with the given top-level container and options.
    init(from element: XMLTag, with namespace: String? = nil, at codingPath: [CodingKey] = [], options: Options) {
        self.element = element
        self.namespace = namespace
        self.codingPath = codingPath
        self.options = options
        self.userInfo = [:]
    }
}

// MARK: - Decoder Methods

extension XMLDecoder: Decoder {
    @usableFromInline func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = KeyedContainer<Key>(decoder: self, codingPath: self.codingPath, element: self.element, namespace: self.namespace)
        return KeyedDecodingContainer(container)
    }
    
    @usableFromInline func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        var array: [XMLTag]?
        
        if let namespace = self.namespace {
            array = self.element.getChildren(withPrefix: namespace)
        } else if let name = self.codingPath.last?.stringValue {
            array = self.element.getChildren(withName: name)
        }
        
        guard let array = array else {
            throw DecodingError.valueNotFound(Date.self, .init(
                codingPath: self.codingPath,
                debugDescription: "Cannot get unkeyed decoding container -- found null value instead"
            ))
        }
        
        return UnkeyedContainer(decoder: self, codingPath: self.codingPath, array: array)
    }
    
    @usableFromInline func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
    
    @inline(__always)
    func checkNotNull(for codingKey: [CodingKey]) throws -> String  {
        if let value = self.element.value {
           return value
        }
        
        throw DecodingError.valueNotFound(String.self, .init(
            codingPath: codingKey,
            debugDescription: "Found null value"
        ))
    }
    
    func unwrap<T: Decodable>(as type: T.Type) throws -> T {
        if type == Date.self {
            return try self.unwrapDate() as! T
        }
        if type == Data.self {
            return try self.unwrapData() as! T
        }
        if type == URL.self {
            return try self.unwrapURL() as! T
        }
        if type == Decimal.self {
            return try self.unwrapDecimal() as! T
        }
        
        return try type.init(from: self)
    }
    
    private func unwrapDate() throws -> Date {
        switch options.dateDecodingStrategy {
        case .secondsSince1970:
            let double = try self.decode(Double.self)
            return Date(timeIntervalSince1970: double)
        case .millisecondsSince1970:
            let double = try self.decode(Double.self)
            return Date(timeIntervalSince1970: double / 1000.0)
        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                let string = try self.decode(String.self)
                guard let date = ISO8601DateFormatter().date(from: string) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                }
                return date
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
        case .custom(let closure):
            return try closure(self)
        default:
            return try Date(from: self)
        }
    }
    
    private func unwrapData() throws -> Data {
        let value = try checkNotNull(for: self.codingPath)
        
        switch options.dataDecodingStrategy {
        case .base64:
            guard let value = Data(base64Encoded: value, options: .ignoreUnknownCharacters) else {
                throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Could not decode \(Data.self)."))
            }
            return value
        case .custom(let closure):
            return try closure(self)
        default:
            return try Data(from: self)
        }
    }
    
    private func unwrapURL() throws -> URL {
        let value = try checkNotNull(for: self.codingPath)
        
        guard let url = URL(string: value) else {
            throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Could not decode \(URL.self)."))
        }
        
        return url
    }
    
    private func unwrapDecimal() throws -> Foundation.Decimal {
        let value = try checkNotNull(for: self.codingPath)
        
        guard let decimal = Foundation.Decimal(string: value) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Parsed number <\(value)> does not fit in \(Decimal.self)."))
        }
        
        return decimal
    }
    
    private func unwrapFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(
        from number: String,
        for additionalKey: CodingKey? = nil,
        as type: T.Type
    ) throws -> T {
        guard let floatingPoint = T(number), floatingPoint.isFinite else {
            var path = self.codingPath
            if let additionalKey = additionalKey {
                path.append(additionalKey)
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: path,
                debugDescription: "Parsed number <\(number)> does not fit in \(T.self)."))
        }
        
        var path = self.codingPath
        if let additionalKey = additionalKey {
            path.append(additionalKey)
        }
        
        return floatingPoint
    }
    
    private func unwrapFixedWidthInteger<T: FixedWidthInteger>(
        from number: String,
        for additionalKey: CodingKey? = nil,
        as type: T.Type
    ) throws -> T {
        if number.isEmpty {
            throw DecodingError.valueNotFound(type, .init(codingPath: self.codingPath, debugDescription: "Found empty string"))
        }
        
        // this is the fast pass. Number directly convertible to Integer
        if let integer = T(number) {
            return integer
        }
        
        // this is the really slow path... If the fast path has failed. For example for "34.0" as
        // an integer, we try to go through NSNumber
        if let nsNumber = NSNumber.fromJSONNumber(number) {
            if type == UInt8.self, NSNumber(value: nsNumber.uint8Value) == nsNumber {
                return nsNumber.uint8Value as! T
            }
            if type == Int8.self, NSNumber(value: nsNumber.int8Value) == nsNumber {
                return nsNumber.int8Value as! T
            }
            if type == UInt16.self, NSNumber(value: nsNumber.uint16Value) == nsNumber {
                return nsNumber.uint16Value as! T
            }
            if type == Int16.self, NSNumber(value: nsNumber.int16Value) == nsNumber {
                return nsNumber.int16Value as! T
            }
            if type == UInt32.self, NSNumber(value: nsNumber.uint32Value) == nsNumber {
                return nsNumber.uint32Value as! T
            }
            if type == Int32.self, NSNumber(value: nsNumber.int32Value) == nsNumber {
                return nsNumber.int32Value as! T
            }
            if type == UInt64.self, NSNumber(value: nsNumber.uint64Value) == nsNumber {
                return nsNumber.uint64Value as! T
            }
            if type == Int64.self, NSNumber(value: nsNumber.int64Value) == nsNumber {
                return nsNumber.int64Value as! T
            }
            if type == UInt.self, NSNumber(value: nsNumber.uintValue) == nsNumber {
                return nsNumber.uintValue as! T
            }
            if type == Int.self, NSNumber(value: nsNumber.intValue) == nsNumber {
                return nsNumber.intValue as! T
            }
        }
        
        var path = self.codingPath
        if let additionalKey = additionalKey {
            path.append(additionalKey)
        }
        
        throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Could not decode \(type)."))
    }
}

// MARK: Single Value Container

extension XMLDecoder: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        self.element.value == nil
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        let value = try checkNotNull(for: self.codingPath)
                
        guard let result = Bool(value) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Could not decode \(Bool.self).")
            )
        }
        
        return result
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try checkNotNull(for: self.codingPath)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        return try decodeFloatingPoint()
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        return try decodeFloatingPoint()
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try decodeFixedWidthInteger()
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try self.unwrap(as: type)
    }
    
    @inline(__always) private func decodeFixedWidthInteger<T: FixedWidthInteger>() throws -> T {
        let value = try checkNotNull(for: self.codingPath)
        return try self.unwrapFixedWidthInteger(from: value, as: T.self)
    }
    
    @inline(__always) private func decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() throws -> T {
        let value = try checkNotNull(for: self.codingPath)
        return try self.unwrapFloatingPoint(from: value, as: T.self)
    }
}

// MARK: Keyed Container

extension XMLDecoder {
    struct KeyedContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
        /// A reference to the encoder we're reading from.
        private let decoder: XMLDecoder
        
        /// A reference to the nodes we're reading from.
        private let attributes: [String: String]
        
        /// A reference to the nodes we're reading from.
        private let elements: [String: XMLTag]
        
        /// A reference to all supported namespaces
        private let namespaces: Set<String>
        
        /// The path of coding keys taken to get to this point in decoding.
        private(set) public var codingPath: [CodingKey]
        
        // MARK: - Initialization
        
        /// Initializes `self` with the given references.
        fileprivate init(decoder: XMLDecoder, codingPath: [CodingKey], element: XMLTag, namespace: String? = nil) {
            self.decoder = decoder
            self.codingPath = codingPath
            self.attributes = element.attributes
            self.namespaces = element.getNamespaces() ?? []
            
            if let namespace = namespace {
                self.elements = element.getChildrenDictionary(withPrefix: namespace) ?? [:]
            } else {
                self.elements = element.getChildrenDictionary() ?? [:]
            }
        }
        
        // MARK: KeyedDecodingContainerProtocol Implementation
        
        var allKeys: [K] {
            self.attributes.keys.compactMap { K(stringValue: $0) } +
            self.elements.keys.compactMap { K(stringValue: $0) } +
            self.namespaces.compactMap { K(stringValue: $0)}
        }
        
        func contains(_ key: K) -> Bool {
            return self.elements[key.stringValue] != nil ||
            self.attributes[key.stringValue] != nil ||
            self.namespaces.contains(key.stringValue) ||
            self.decoder.element.name == key.stringValue
        }
        
        func decodeNil(forKey key: K) throws -> Bool {
            let value = try getValue(forKey: key)
            return value == ""
        }
        
        func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
            let value = try getValue(forKey: key)
            
            guard let bool = Bool(value) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: self.decoder.codingPath,
                    debugDescription: "Could not decode \(Bool.self)."
                ))
            }
            
            return bool
        }
        
        func decode(_ type: String.Type, forKey key: K) throws -> String {
            return try getValue(forKey: key)
        }
        
        func decode(_: Double.Type, forKey key: K) throws -> Double {
            try decodeFloatingPoint(key: key)
        }
        
        func decode(_: Float.Type, forKey key: K) throws -> Float {
            try decodeFloatingPoint(key: key)
        }
        
        func decode(_: Int.Type, forKey key: K) throws -> Int {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: Int8.Type, forKey key: K) throws -> Int8 {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: Int16.Type, forKey key: K) throws -> Int16 {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: Int32.Type, forKey key: K) throws -> Int32 {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: Int64.Type, forKey key: K) throws -> Int64 {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: UInt.Type, forKey key: K) throws -> UInt {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: UInt8.Type, forKey key: K) throws -> UInt8 {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: UInt16.Type, forKey key: K) throws -> UInt16 {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: UInt32.Type, forKey key: K) throws -> UInt32 {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode(_: UInt64.Type, forKey key: K) throws -> UInt64 {
            try decodeFixedWidthInteger(key: key)
        }
        
        func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
            let newDecoder: XMLDecoder
            
            if type is any Collection.Type {
                newDecoder = try decoderForKeyOfCollection(key)
            } else {
                newDecoder = try decoderForKey(key)
            }
            
            return try newDecoder.unwrap(as: type)
        }
        
        private func decoderForKey(_ key: K) throws -> XMLDecoder {
            var newPath = self.codingPath
            newPath.append(key)
            
            if let element = self.elements[key.stringValue] {
                return XMLDecoder(from: element,at: newPath,options: self.decoder.options)
            }
            
            if self.namespaces.contains(key.stringValue) {
                return XMLDecoder(from: self.decoder.element,with: key.stringValue, at: newPath,options: self.decoder.options)
            }
            
            throw DecodingError.dataCorrupted(.init(
                codingPath: self.codingPath,
                debugDescription: "Can't create decoder with value associated with key \(key) (\"\(key.stringValue)\")."
            ))
        }
        
        private func decoderForKeyOfCollection(_ key: K) throws -> XMLDecoder {
            var newPath = self.codingPath
            newPath.append(key)
            
            return XMLDecoder(from: self.decoder.element, at: newPath,options: self.decoder.options)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            try decoderForKey(key).container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
            try decoderForKey(key).unkeyedContainer()
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
        
        func superDecoder(forKey key: K) throws -> Decoder {
            fatalError()
        }
        
        @inline(__always) private func getValue<LocalKey: CodingKey>(forKey key: LocalKey) throws -> String {
            if let value = attributes[key.stringValue] {
                return value
            }
            
            if let value = elements[key.stringValue]?.value {
                return value
            }
            
            guard let value = self.decoder.element.value else {
                throw DecodingError.keyNotFound(key, .init(
                    codingPath: self.codingPath,
                    debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."
                ))
            }
            
            return value
        }
        
        @inline(__always) private func decodeFixedWidthInteger<T: FixedWidthInteger>(key: Self.Key) throws -> T {
            let value = try getValue(forKey: key)
            return try self.decoder.unwrapFixedWidthInteger(from: value, for: key, as: T.self)
        }
        
        @inline(__always) private func decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(key: K) throws -> T {
            let value = try getValue(forKey: key)
            return try self.decoder.unwrapFloatingPoint(from: value, for: key, as: T.self)
        }
    }
}

// MARK: Unkeyed Container

extension XMLDecoder {
    struct UnkeyedContainer: UnkeyedDecodingContainer {
        /// A reference to the decoder we're reading from.
        private let decoder: XMLDecoder
        
        /// The container's filtered children nodes.
        private var array: [XMLTag]
        
        /// The path of coding keys taken to get to this point in decoding.
        var codingPath: [CodingKey]
        
        var currentIndex: Int
        
        /// Initializes `self` by referencing the given decoder and container.
        fileprivate init(decoder: XMLDecoder, codingPath: [CodingKey], array: [XMLTag]) {
            self.decoder = decoder
            self.codingPath = codingPath
            self.currentIndex = 0
            self.array = array
        }
        
        // MARK: - UnkeyedDecodingContainer Methods
        
        public var count: Int? {
            return self.array.count
        }
        
        public var isAtEnd: Bool {
            return self.currentIndex >= self.count!
        }
        
        private func decodeStringAtCurrentIndex() throws -> String? {
            guard !self.isAtEnd else {
                throw DecodingError.valueNotFound(String.self, .init(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
            }
            return self.array[currentIndex].value
        }
        
        mutating func decodeNil() throws -> Bool {
            let decoded = try self.decodeStringAtCurrentIndex()
            return decoded == nil
        }
        
        mutating func decode(_ type: Bool.Type) throws -> Bool {
            guard let string = try self.decodeStringAtCurrentIndex(), let value = Bool(string)  else {
                throw DecodingError.valueNotFound(type, .init(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) but found empty node instead."))
            }
            return value
        }
        
        mutating func decode(_ type: String.Type) throws -> String {
            let decoded = try self.decodeStringAtCurrentIndex() ?? ""
            self.currentIndex += 1
            return decoded
        }
        
        mutating func decode(_: Double.Type) throws -> Double {
            try decodeFloatingPoint()
        }
        
        mutating func decode(_: Float.Type) throws -> Float {
            try decodeFloatingPoint()
        }
        
        mutating func decode(_: Int.Type) throws -> Int {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: Int8.Type) throws -> Int8 {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: Int16.Type) throws -> Int16 {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: Int32.Type) throws -> Int32 {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: Int64.Type) throws -> Int64 {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: UInt.Type) throws -> UInt {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: UInt8.Type) throws -> UInt8 {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: UInt16.Type) throws -> UInt16 {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: UInt32.Type) throws -> UInt32 {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode(_: UInt64.Type) throws -> UInt64 {
            try decodeFixedWidthInteger()
        }
        
        mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            let newDecoder = try decoderForNextElement(ofType: type)
            let result = try newDecoder.unwrap(as: type)
            
            // Because of the requirement that the index not be incremented unless
            // decoding the desired result type succeeds, it can not be a tail call.
            // Hopefully the compiler still optimizes well enough that the result
            // doesn't get copied around.
            self.currentIndex += 1
            return result
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            let decoder = try decoderForNextElement(ofType: KeyedDecodingContainer<NestedKey>.self)
            let container = try decoder.container(keyedBy: type)
            
            self.currentIndex += 1
            return container
        }
        
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            let decoder = try decoderForNextElement(ofType: UnkeyedDecodingContainer.self)
            let container = try decoder.unkeyedContainer()
            
            self.currentIndex += 1
            return container
        }
        
        mutating func superDecoder() throws -> Decoder {
            let decoder = try decoderForNextElement(ofType: Decoder.self)
            self.currentIndex += 1
            return decoder
        }
        
        private mutating func decoderForNextElement<T>(ofType: T.Type) throws -> XMLDecoder {
            let element = try self.getNextElement(ofType: T.self)
            let newPath = self.codingPath + [_XMLKey(index: self.currentIndex)]
            
            return XMLDecoder(from: element,at: newPath,options: self.decoder.options)
        }
        
        @inline(__always)
        private func getNextElement<T>(ofType: T.Type) throws -> XMLTag {
            guard !self.isAtEnd else {
                var message = "Unkeyed container is at end."
                if T.self == UnkeyedContainer.self {
                    message = "Cannot get nested unkeyed container -- unkeyed container is at end."
                }
                if T.self == Decoder.self {
                    message = "Cannot get superDecoder() -- unkeyed container is at end."
                }
                
                var path = self.codingPath
                path.append(_XMLKey(index: self.currentIndex))
                
                throw DecodingError.valueNotFound(T.self, .init(
                    codingPath: path, debugDescription: message, underlyingError: nil)
                )
            }
            return self.array[self.currentIndex]
        }
        
        @inline(__always) private mutating func decodeFixedWidthInteger<T: FixedWidthInteger>() throws -> T {
            let element = try self.getNextElement(ofType: T.self)
            let key = _XMLKey(index: self.currentIndex)
            
            guard let number = element.value else {
                throw DecodingError.valueNotFound(String.self, .init(
                    codingPath: self.codingPath,
                    debugDescription: "Could not decode \(T.self).")
                )
            }
            
            let result = try self.decoder.unwrapFixedWidthInteger(from: number, for: key, as: T.self)
            self.currentIndex += 1
            return result
        }
        
        @inline(__always) private mutating func decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() throws -> T {
            let element = try self.getNextElement(ofType: T.self)
            let key = _XMLKey(index: self.currentIndex)
            
            guard let number = element.value else {
                throw DecodingError.valueNotFound(String.self, .init(
                    codingPath: self.codingPath,
                    debugDescription: "Could not decode \(T.self).")
                )
            }
            
            let result = try self.decoder.unwrapFloatingPoint(from: number, for: key, as: T.self)
            self.currentIndex += 1
            return result
        }
    }
}
