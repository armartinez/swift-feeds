//
//  XMLReader.swift
//
//
//  Created by Axel Martinez on 4/9/24.
//

import Foundation

class XMLReader: NSObject {
    var nodes: [XMLTag] = []
    var currentNode: XMLTag?
    var namespacesMapping: [String: String] = [:]
    
    func read(
        with data: Data,
        shouldProcessNamespaces: Bool = true,
        shouldReportNamespacePrefixes: Bool = true
    ) throws -> XMLTag {
        let xmlParser = XMLParser(data: data)
        xmlParser.shouldProcessNamespaces = shouldProcessNamespaces
        xmlParser.shouldReportNamespacePrefixes = shouldReportNamespacePrefixes
        xmlParser.delegate = self
        
        if xmlParser.parse(), let root = self.nodes.first {
            return root
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: [],
            debugDescription: "Error parsing XML",
            underlyingError: xmlParser.parserError
        ))
    }
}

// MARK: - XMLParser delegate

extension XMLReader: XMLParserDelegate {
    
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        var prefix: String? = nil
        
        if let namespaceURI = namespaceURI {
            prefix = namespacesMapping[namespaceURI]
        }
        
        let newNode = XMLTag(name: elementName, prefix: prefix, attributes: attributeDict, children: [])
        
        if let currentNode = currentNode {
            self.nodes.append(currentNode)
        }
        
        self.currentNode = newNode
    }

    func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI: String) {
        if !prefix.isEmpty {
            self.namespacesMapping[toURI] = prefix
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let value = self.currentNode?.value {
            self.currentNode?.value = value + string
        } else  {
            self.currentNode?.value = string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let currentNode = currentNode {
            self.nodes.last?.children?.append(currentNode)
            self.currentNode = nil
        } else if self.nodes.count > 1, let node = self.nodes.popLast() {
            self.nodes.last?.children?.append(node)
        }
    }
}
