//
//  NaturalLanguageReminderParser.swift
//  The Chalkboard
//
//  Created by Israel Manzo on 4/27/26.
//

import Foundation

struct NaturalLanguageReminderParseResult {
    let cleanedText: String
    let dueDate: Date?
    let dueTimeMinutes: Int?
}

enum NaturalLanguageReminderParser {
    static func parse(_ text: String, calendar: Calendar = .current) -> NaturalLanguageReminderParseResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return NaturalLanguageReminderParseResult(cleanedText: "", dueDate: nil, dueTimeMinutes: nil)
        }

        let detector: NSDataDetector? = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let ns = trimmed as NSString
        let fullRange = NSRange(location: 0, length: ns.length)

        let matches: [NSTextCheckingResult] = detector?.matches(in: trimmed, options: [], range: fullRange) ?? []
        let dateMatches = matches.filter { $0.resultType == .date && $0.range.location != NSNotFound && $0.range.length > 0 }

        let detected: (date: Date, hasExplicitTime: Bool, range: NSRange)? = {
            for m in dateMatches {
                guard let d = m.date else { continue }
                let matchText = ns.substring(with: m.range).lowercased()
                let hasTime = containsExplicitTime(in: matchText)
                return (d, hasTime, m.range)
            }
            return nil
        }()

        let cleanedText: String = {
            guard !dateMatches.isEmpty else { return normalizeTitle(trimmed) }

            let mutable = NSMutableString(string: trimmed)
            for r in dateMatches.map(\.range).sorted(by: { $0.location > $1.location }) {
                if r.location != NSNotFound, NSMaxRange(r) <= mutable.length {
                    mutable.replaceCharacters(in: r, with: "")
                }
            }
            return normalizeTitle(mutable as String)
        }()

        guard let detected else {
            return NaturalLanguageReminderParseResult(cleanedText: cleanedText, dueDate: nil, dueTimeMinutes: nil)
        }

        let dueDate = calendar.startOfDay(for: detected.date)
        let dueTimeMinutes: Int? = {
            guard detected.hasExplicitTime else { return nil }
            let comps = calendar.dateComponents([.hour, .minute], from: detected.date)
            guard let h = comps.hour, let m = comps.minute else { return nil }
            return h * 60 + m
        }()

        return NaturalLanguageReminderParseResult(cleanedText: cleanedText, dueDate: dueDate, dueTimeMinutes: dueTimeMinutes)
    }
}

private extension NaturalLanguageReminderParser {
    static func containsExplicitTime(in loweredMatchText: String) -> Bool {
        if loweredMatchText.contains(":") { return true }
        if loweredMatchText.contains("am") || loweredMatchText.contains("pm") { return true }
        if loweredMatchText.contains("noon") || loweredMatchText.contains("midnight") { return true }
        if loweredMatchText.contains("morning") || loweredMatchText.contains("afternoon") || loweredMatchText.contains("evening") { return true }
        if loweredMatchText.contains("tonight") { return true }
        if loweredMatchText.range(of: #"\b(at|@)\s*\d{1,2}(\:\d{2})?\b"#, options: .regularExpression) != nil { return true }
        return false
    }

    static func normalizeTitle(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        s = stripLeadingCommandPhrases(s)
        s = stripTrailingConnectors(s)
        s = collapseWhitespace(s)
        s = s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "—–-,:;.")))
        return s
    }

    static func stripLeadingCommandPhrases(_ text: String) -> String {
        let patterns = [
            #"^\s*(remind me to)\s+"#,
            #"^\s*(remind me)\s+"#,
            #"^\s*(remember to)\s+"#,
            #"^\s*(don['’]?t forget to)\s+"#,
            #"^\s*(please)\s+"#
        ]

        var s = text
        for p in patterns {
            if let re = try? NSRegularExpression(pattern: p, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: (s as NSString).length)
                s = re.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "")
            }
        }

        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.lowercased().hasPrefix("to ") {
            s = String(s.dropFirst(3))
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func stripTrailingConnectors(_ text: String) -> String {
        var s = text
        let patterns = [
            #"\s+\b(at|on|by|around|in)\b\s*$"#,
            #"\s*[,\-–—]\s*$"#
        ]

        for _ in 0..<3 {
            var changed = false
            for p in patterns {
                if let re = try? NSRegularExpression(pattern: p, options: [.caseInsensitive]) {
                    let range = NSRange(location: 0, length: (s as NSString).length)
                    let updated = re.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "")
                    if updated != s {
                        s = updated
                        changed = true
                    }
                }
            }
            if !changed { break }
        }

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func collapseWhitespace(_ text: String) -> String {
        guard let re = try? NSRegularExpression(pattern: #"\s+"#, options: []) else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return re.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

