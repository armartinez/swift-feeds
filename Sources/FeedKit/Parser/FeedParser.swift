//
//  FeedParser.swift
//
//  Copyright (c) 2016 - 2018 Nuno Manuel Dias
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Dispatch
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An RSS and Atom feed parser. `FeedParser` uses `Foundation`'s `XMLParser`.
public class FeedParser {
    private var data: Data?
    private var url: URL?
    private var xmlStream: InputStream?

    /// A FeedParser handler provider.
    var parser: FeedParserProtocol?

    /// Initializes the parser with the JSON or XML content referenced by the given URL.
    ///
    /// - Parameter URL: URL whose contents are read to produce the feed data
    public init(URL: URL) {
        self.url = URL
    }

    /// Initializes the parser with the xml or json contents encapsulated in a
    /// given data object.
    ///
    /// - Parameter data: XML or JSON data
    public init(data: Data) {
        self.data = data
    }

    /// Initializes the parser with the XML contents encapsulated in a
    /// given InputStream.
    ///
    /// - Parameter xmlStream: An InputStream that yields XML data.
    public init(xmlStream: InputStream) {
        self.xmlStream = xmlStream
    }

    /// Starts parsing the feed.
    ///
    /// - Returns: The parsed `Result`.
    public func parse() -> Result<Feed, ParserError> {
        if data == nil, let url = url, url.isFileURL {
            do {
                data = try Data(contentsOf: url)
            } catch {
                return .failure(.internalError(reason: error.localizedDescription))
            }
        }

        if let data = data {
            guard let feedDataType = FeedDataType(data: data) else {
                return .failure(.feedNotFound)
            }
            switch feedDataType {
            case .json: parser = JSONFeedParser(data: data)
            case .xml:  parser = XMLFeedParser(data: data)
            }
            return parser!.parse()
        }

        if let xmlStream = xmlStream {
            parser = XMLFeedParser(stream: xmlStream)
            return parser!.parse()
        }

        return .failure(.internalError(reason: "Fatal error. Unable to parse from the initialized state."))
    }

    /// Starts parsing the feed asynchronously.
    /// Required when parsing remote URLs.
    ///
    /// - Returns: The parsed `Result`.
    public func parseAsync() async throws -> Result<Feed, ParserError> {
        if let url = url {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.data = data
                } else {
                    return .failure(.internalError(reason: "Unexpected HTTP Response: "+httpResponse.description))
                }
            }
        }

        return self.parse()
    }

    /// Stops parsing XML feeds.
    public func abortParsing() {
        guard let xmlFeedParser = parser as? XMLFeedParser else { return }
        xmlFeedParser.xmlParser.abortParsing()
    }
}
