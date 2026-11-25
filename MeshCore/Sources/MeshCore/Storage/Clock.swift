import Foundation

public typealias NowMs = () -> Int64

public func systemNowMs() -> Int64 {
    return Int64(Date().timeIntervalSince1970 * 1000)
}
