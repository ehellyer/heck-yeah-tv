// H264Parser.swift
// Heck Yeah TV
//
// Minimal Annex-B parser to detect IDR frames (NAL type 5).

import Foundation

final class H264Parser {
    private let onIDR: () -> Void
    private var buffer = Data()

    init(onIDR: @escaping () -> Void) {
        self.onIDR = onIDR
    }

    func consume(_ es: Data) {
        // Append and scan using index-based access only
        if !es.isEmpty { buffer.append(es) }

        var i = 0
        let base = buffer.startIndex

        while i + 4 <= buffer.count {
            var start = -1
            var next = -1

            // find start (0x000001 or 0x00000001)
            while i + 3 < buffer.count {
                let i0 = buffer.index(base, offsetBy: i)
                let i1 = buffer.index(i0, offsetBy: 1)
                let i2 = buffer.index(i0, offsetBy: 2)

                let b0 = buffer[i0]
                let b1 = buffer[i1]
                let b2 = buffer[i2]

                if b0 == 0x00 && b1 == 0x00 && b2 == 0x01 {
                    start = i + 3
                    i += 3
                    break
                } else if i + 4 < buffer.count {
                    let i3 = buffer.index(i0, offsetBy: 3)
                    let b3 = buffer[i3]
                    if b0 == 0x00 && b1 == 0x00 && b2 == 0x00 && b3 == 0x01 {
                        start = i + 4
                        i += 4
                        break
                    }
                }
                i += 1
            }

            if start < 0 { break }

            // find next start
            var j = i
            while j + 3 < buffer.count {
                let j0 = buffer.index(base, offsetBy: j)
                let j1 = buffer.index(j0, offsetBy: 1)
                let j2 = buffer.index(j0, offsetBy: 2)
                let b0 = buffer[j0]
                let b1 = buffer[j1]
                let b2 = buffer[j2]

                if b0 == 0x00 && b1 == 0x00 && b2 == 0x01 {
                    next = j
                    break
                }
                if j + 4 < buffer.count {
                    let j3 = buffer.index(j0, offsetBy: 3)
                    let b3 = buffer[j3]
                    if b0 == 0x00 && b1 == 0x00 && b2 == 0x00 && b3 == 0x01 {
                        next = j
                        break
                    }
                }
                j += 1
            }

            let end = (next >= 0) ? next : buffer.count
            if start < end {
                // NALU slice [start, end)
                let sIdx = buffer.index(base, offsetBy: start)
                let eIdx = buffer.index(base, offsetBy: end)
                let nalu = buffer[sIdx..<eIdx]
                if let first = nalu.first {
                    let nalType = first & 0x1F
                    if nalType == 5 {
                        onIDR()
                    }
                }
            }

            i = end
        }

        // keep tail
        if i > 0 {
            buffer.removeFirst(i)
        }
    }
}
