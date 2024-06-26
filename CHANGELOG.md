# Change Log
## [8.2.0](https://github.com/armartinez/FeedParser/releases/tag/8.2.0)
### Updated
- Updated parseAsync() to use URLSession for remote URLs.
- Raised minimum targets to macOS 12, iOS 15, tvOS 12, watchOS 4
- Implemented async/await for asychronous operations

## [8.1.1](https://github.com/nmdias/FeedParser/releases/tag/8.1.1)
### Fixed
- Avoid reencoding all incoming data to UTF-8
  - [#83](https://github.com/nmdias/FeedKit/pull/83) by [GarthSnyder](https://github.com/GarthSnyder)

## [8.1.0](https://github.com/nmdias/FeedParser/releases/tag/8.1.0)
### Added
- Support for Swift 4.2
- Added public initializers to the RSS and Atom Feed Models
- Added support for the `media:title`, `media:description`, `media:player` and `media:thumbnails` xml elements within the `media:content` element in the Media namespace Models
  - [#66](https://github.com/nmdias/FeedKit/issues/66) reported by [sglushchenko](https://github.com/sglushchenko)
- Added support for the `itunes:type`, `ìtunes:episodeType`, `itunes:season`, and `itunes:episode` elements
  - [#61](https://github.com/nmdias/FeedKit/pull/61) by [George Cox](https://github.com/gcox)
- Added public initializers to the JSON Feed Model
  - [#58](https://github.com/nmdias/FeedKit/pull/58) by [Lauri Koli](https://github.com/lauri-koli-vincit)

### Updated
- FeedParser initializers no longer failable
- Adopted Codable conformance for mapping JSON feeds
- Removed verbose output pod lib lint in travis

### Fixed
- Update Package.swift to support Swift 4.2
  - [#80](https://github.com/nmdias/FeedKit/pull/80) by [Wilson Gramer](https://github.com/Wilsonator5000)  
- Correct line endings and file permissions
  - [#77](https://github.com/nmdias/FeedKit/pull/77) by [Eiot](https://github.com/Eitot)  
- Fixed date formatter strings
  - [#64](https://github.com/nmdias/FeedKit/pull/64) by [P W](https://github.com/hactar)

## [8.0.0](https://github.com/nmdias/FeedParser/releases/tag/8.0.0)
### Updated
- FeedParser initializers no longer failable

### Fixed
- Null parser for feed:// protocol
  - [#50](https://github.com/nmdias/FeedKit/pull/50) reported by [revolter](https://github.com/revolter)  
- Fixed unexpected upfront fetching of data for url causing UI hang
  - [#45](https://github.com/nmdias/FeedKit/pull/45) reported by [bhlvoong](https://github.com/bhlvoong)  

## [7.1.1](https://github.com/nmdias/FeedParser/releases/tag/7.1.1)
### Updated
- Parse all RSS and ATOM dates permissively
  - [#56](https://github.com/nmdias/FeedKit/pull/56) by [GarthSnyder](https://github.com/GarthSnyder)
- Reattempt parsing of RFC822 dates without day prefix
  - [#55](https://github.com/nmdias/FeedKit/pull/55) by [GarthSnyder](https://github.com/GarthSnyder)
- Strip leading and trailing whitespace before parsing dates
  - [#54](https://github.com/nmdias/FeedKit/pull/54) by [GarthSnyder](https://github.com/GarthSnyder)
- Terminate XML parsing as soon as a complete feed is received
  - [#53](https://github.com/nmdias/FeedKit/pull/53) by [GarthSnyder](https://github.com/GarthSnyder)
- Allow parsing from an InputStream containing XML
  - [#52](https://github.com/nmdias/FeedKit/pull/52) by [GarthSnyder](https://github.com/GarthSnyder)
- Faster and more robust feed type determination
  - [#51](https://github.com/nmdias/FeedKit/pull/51) by [GarthSnyder](https://github.com/GarthSnyder)

### Fixed
- Detect existing data encoding and convert to UTF-8 before parsing
  - [#43](https://github.com/nmdias/FeedKit/pull/43) by [CD1212](https://github.com/CD1212)  

## [7.1.0](https://github.com/nmdias/FeedParser/releases/tag/7.1.0)
### Added
- Support for Xcode 9.3 w/Swift 4.1

## [7.0.1](https://github.com/nmdias/FeedParser/releases/tag/7.0.1)
### Fixed
- Fixed 'characters' is deprecated for Swift 4.0.2 #41

## [7.0.0](https://github.com/nmdias/FeedParser/releases/tag/7.0.0)
### Added
- Support for Swift 4 and Xcode 9

## [6.2.0](https://github.com/nmdias/FeedParser/releases/tag/6.1.2)
### Added
- Support for the RSS 0.90 specification

## [6.1.3](https://github.com/nmdias/FeedParser/releases/tag/6.1.2)
### Fixed
- `parseAsync` no longer assumes that the user wants the result closure back to the Main queue.
### Updated
- Documentation

## [6.1.2](https://github.com/nmdias/FeedParser/releases/tag/6.1.2)
### Fixed
- parseAsync now  defaults to the global queue and correctly bring the result back to the main thread
  - [Fixed](https://github.com/nmdias/FeedKit/pull/35) by [dkcas11](https://github.com/dkcas11) 
- Missing pubDate data after parsing RSS feed
  - [Reported](https://github.com/nmdias/FeedKit/issues/31) by [jamesokelly](https://github.com/jamesokelly) 
- Media namespace not available on AtomFeed
  - [Reported](https://github.com/nmdias/FeedKit/issues/34) by [valeriomazzeo](https://github.com/valeriomazzeo) 

### Updated
- Documentation Style
- Normalized internal method signatures
- Rearranged folders structure

## [6.1.1](https://github.com/nmdias/FeedParser/releases/tag/6.1.1)
### Fixed
- Removed non utf-8 characters from test files

## [6.1.0](https://github.com/nmdias/FeedParser/releases/tag/6.1.0)
### Added
- Linux Support
- FeedKit.paw

### Fixed
- Support for Swift Package Manager
- Reverted removal of Foundation imports
- Fixed 'Error' is not convertible to 'NSError' on Linux
- Fixed use of undeclared type 'DispatchQueue' when build in Linux

### Updated
- Access control modifiers
- Improved Documentation

## [6.0.2](https://github.com/nmdias/FeedParser/releases/tag/6.0.2)
### Added
- Cocoadocs styles yml
### Updated
- Documentation

## [6.0.1](https://github.com/nmdias/FeedParser/releases/tag/6.0.1)
### Updated
- Excluded tests from the SPM

## [6.0.0](https://github.com/nmdias/FeedParser/releases/tag/6.0.0)
### Added
- Asynchronous feed parsing
- iTunes Podcasting Tags Namespace
- Media Namespace
- JSON Feed Support
- Equatable Models (RSS, Atom and JSON)
- Unit Tests

### Updated
- Examples with asynchronous feed parsing
- Unit tests with asynchronous feed parsing
- Documentation

### Fixed
- Fixed crashes when trying to parse a feed URL offline #4

### Removed
- Support for Input Streams

## [5.1.0](https://github.com/nmdias/FeedParser/releases/tag/5.1.0)
### Added
- Abort Parsing method

### Fixed
- Completion block executing twice on failure

## [5.0.0](https://github.com/nmdias/FeedParser/releases/tag/5.0.0)
### Added
- Support for Swift 3.0

## [4.1.0](https://github.com/nmdias/FeedParser/releases/tag/4.1.0)
### Added
- Support for Xcode 8 (Swift 2.3)

## [4.0.0](https://github.com/nmdias/FeedParser/releases/tag/4.0.0)
The `FeedParser` framework has been renamed `FeedKit` to prevent conflicts between the `FeedParser` module and the `FeedParser` class naming

## [3.1.0](https://github.com/nmdias/FeedParser/releases/tag/3.1.0)
### Added
- Dates support
 - RFC822
 - RFC3999
 - ISO8601

## [3.0.0](https://github.com/nmdias/FeedParser/releases/tag/3.0.0)
### Added
- Support for Atom feeds according to RFC 4287
- Unit tests for the Atom specification
- Parse error handling
- Parse error handling unit tests
- NSData initializer
- NSInputStream initializer
- Parse performance unit tests

### Updated
- Unit tests for the RSS specification
- Unit tests for the Content Module specification
- Unit tests for the Dublin Core Module specification
- Unit tests for the Syndication Module specification
- Tracking of the current XML DOM element being parsed with improved type safety
- Consistent use of integer values to aid code interoperability
- Syndication module Update Period mapping reliability
- Consistency to the `Given`, `When`, `Then` unit test pattern

### Removed
- Types of the RSS feed model dropped the explicit version `2` 
- Internal helper `Debug.log(_)`
- Usage of `assertionFailure(_)`

### Fixed
- Issue where the `module 'FeedParser' was not compiled for testing` when testing Release builds
- Issue where both Atom and RSS models were initialized despite the type of feed being parsed
- Issue where the `syndication` namespace was not initialized properly causing child elements to also be `nil`

## [2.1.0](https://github.com/nmdias/FeedParser/releases/tag/2.1.0)
### Added
- watchOS Support
- Automated Tests and Builds for Travic-CI
- Copyright notices 
- Improved README instructions and readability

### Fixed
- An issue where Tests would fail when running in release mode

## [2.0.0](https://github.com/nmdias/FeedParser/releases/tag/2.0.0)
Iris has been renamed `FeedParser` to better reflect it's purpose and discoverability.

## [1.1.1](https://github.com/nmdias/FeedParser/releases/tag/1.1.1)
### Added
- Tests for the `RSS2` model
- Tests for the `Content Module` model
- Tests for the `DublinCore Module` model
- Tests for the `Syndication Module` model

## [1.1.0](https://github.com/nmdias/FeedParser/releases/tag/1.1.0)
### Added
- Support for SPM
- Support for Cocoapods

## [1.0.0](https://github.com/nmdias/FeedParser/releases/tag/1.0.0)
### Added
- Initial Release of Iris
