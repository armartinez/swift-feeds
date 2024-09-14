//
//  XMLTag.swift
//
//
//  Created by Axel Martinez on 4/9/24.
//

import Foundation

/// Represents a xml tag`
class XMLTag {
    var name: String
    var prefix: String?
    var attributes: [String: String]
    var value: String?
    var children: [XMLTag]?
    var qualifiedName: String {
        if let prefix = prefix {
            return "\(prefix):\(name)"
        }
        return name
    }
    
    init(name: String, prefix: String? = nil, attributes: [String : String], value: String? = nil, children: [XMLTag]? = nil) {
        self.name = name
        self.prefix = prefix
        self.attributes = attributes
        self.value = value
        self.children = children
    }
    
    /// Returns all children with the specified name
    func getChildren(withName name: String) -> [XMLTag]? {
        return self.children?.filter({ $0.name == name })
    }
    
    /// Returns all children with the specified prefix
    func getChildren(withPrefix prefix: String) -> [XMLTag]? {
        return self.children?.filter({ $0.prefix == prefix })
    }

    /// Retrieves all values associated with the xml tag as a dictionary
    func getChildrenDictionary() -> [String: XMLTag]? {
        return self.children?.reduce(into: [String: XMLTag]()) { key,element in
            if key[element.name] == nil {
                key[element.name] = element
            }
        }
    }
    
    /// Retrieves all values associated with the xml tag as a dictionary
    func getChildrenDictionary(withPrefix prefix: String) -> [String: XMLTag]? {
        return self.children?.reduce(into: [String: XMLTag]()) { key,element in
            if element.prefix == prefix, key[element.name] == nil {
                key[element.name] = element
            }
        }
    }
    
    /// Retrieves all namespacces
    func getNamespaces() -> Set<String>? {
        return self.children?.reduce(into: Set()) { set,element in
            if let prefix = element.prefix {
                set.insert(prefix)
            }
        }
    }
}
