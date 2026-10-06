import Foundation

/// Pitch-class names with sharps. Pitch class 0 is C and pitch class 11 is B.
enum NoteName {
    static let sharps = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// The pitch class (0 to 11) of a MIDI note number, including negative note numbers.
    static func pitchClass(of midi: Int) -> Int {
        ((midi % 12) + 12) % 12
    }
}

/// A scale as a root-relative set of semitone intervals. The names and the order follow the
/// Scale chooser in Ableton Live 12; the intervals are the standard definitions of each scale.
struct Scale: Identifiable, Hashable {
    let name: String
    let intervals: [Int]

    var id: String { name }

    static let all: [Scale] = [
        Scale(name: "Major", intervals: [0, 2, 4, 5, 7, 9, 11]),
        Scale(name: "Minor", intervals: [0, 2, 3, 5, 7, 8, 10]),
        Scale(name: "Dorian", intervals: [0, 2, 3, 5, 7, 9, 10]),
        Scale(name: "Mixolydian", intervals: [0, 2, 4, 5, 7, 9, 10]),
        Scale(name: "Lydian", intervals: [0, 2, 4, 6, 7, 9, 11]),
        Scale(name: "Phrygian", intervals: [0, 1, 3, 5, 7, 8, 10]),
        Scale(name: "Locrian", intervals: [0, 1, 3, 5, 6, 8, 10]),
        Scale(name: "Whole Tone", intervals: [0, 2, 4, 6, 8, 10]),
        Scale(name: "Half-whole Dim.", intervals: [0, 1, 3, 4, 6, 7, 9, 10]),
        Scale(name: "Whole-half Dim.", intervals: [0, 2, 3, 5, 6, 8, 9, 11]),
        Scale(name: "Minor Blues", intervals: [0, 3, 5, 6, 7, 10]),
        Scale(name: "Minor Pentatonic", intervals: [0, 3, 5, 7, 10]),
        Scale(name: "Major Pentatonic", intervals: [0, 2, 4, 7, 9]),
        Scale(name: "Harmonic Minor", intervals: [0, 2, 3, 5, 7, 8, 11]),
        Scale(name: "Harmonic Major", intervals: [0, 2, 4, 5, 7, 8, 11]),
        Scale(name: "Dorian #4", intervals: [0, 2, 3, 6, 7, 9, 10]),
        Scale(name: "Phrygian Dominant", intervals: [0, 1, 4, 5, 7, 8, 10]),
        Scale(name: "Melodic Minor", intervals: [0, 2, 3, 5, 7, 9, 11]),
        Scale(name: "Lydian Augmented", intervals: [0, 2, 4, 6, 8, 9, 11]),
        Scale(name: "Lydian Dominant", intervals: [0, 2, 4, 6, 7, 9, 10]),
        Scale(name: "Super Locrian", intervals: [0, 1, 3, 4, 6, 8, 10]),
        Scale(name: "8-Tone Spanish", intervals: [0, 1, 3, 4, 5, 6, 8, 10]),
        Scale(name: "Bhairav", intervals: [0, 1, 4, 5, 7, 8, 11]),
        Scale(name: "Hungarian Minor", intervals: [0, 2, 3, 6, 7, 8, 11]),
        Scale(name: "Hirajoshi", intervals: [0, 2, 3, 7, 8]),
        Scale(name: "In-Sen", intervals: [0, 1, 5, 7, 10]),
        Scale(name: "Iwato", intervals: [0, 1, 5, 6, 10]),
        Scale(name: "Kumoi", intervals: [0, 2, 3, 7, 9]),
        Scale(name: "Pelog Selisir", intervals: [0, 1, 3, 7, 8]),
        Scale(name: "Pelog Tembung", intervals: [0, 1, 5, 7, 8]),
        Scale(name: "Messiaen 3", intervals: [0, 2, 3, 4, 6, 7, 8, 10, 11]),
        Scale(name: "Messiaen 4", intervals: [0, 1, 2, 5, 6, 7, 8, 11]),
        Scale(name: "Messiaen 5", intervals: [0, 1, 5, 6, 7, 11]),
        Scale(name: "Messiaen 6", intervals: [0, 2, 4, 5, 6, 8, 10, 11]),
        Scale(name: "Messiaen 7", intervals: [0, 1, 2, 3, 5, 6, 7, 8, 9, 11]),
    ]

    /// The absolute pitch classes of this scale on `root`.
    func pitchClasses(root: Int) -> Set<Int> {
        Set(intervals.map { (root + $0) % 12 })
    }
}

/// Two conventions number the octave that starts at middle C (MIDI note 60).
enum OctaveNaming: String, CaseIterable, Identifiable {
    case scientific = "Middle C = C4"
    case ableton = "Middle C = C3 (Ableton)"

    var id: Self { self }

    /// The octave number of MIDI notes 0 to 11.
    var lowestOctave: Int {
        switch self {
        case .scientific: -1
        case .ableton: -2
        }
    }

    /// The note name and octave number of a MIDI note number, for example "A4" for note 69.
    func name(of midi: Int) -> String {
        let pitchClass = NoteName.pitchClass(of: midi)
        let octave = (midi - pitchClass) / 12 + lowestOctave
        return NoteName.sharps[pitchClass] + String(octave)
    }
}

/// Twelve-tone equal temperament with A4 (MIDI note 69) at 440 Hz.
enum Pitch {
    static let referenceMIDI = 69
    static let referenceFrequency = 440.0
    static let middleC = 60

    /// f = 440 Hz x 2^((m - 69) / 12): each semitone multiplies the frequency by the twelfth root of 2.
    static func frequency(midi: Int) -> Double {
        referenceFrequency * pow(2, Double(midi - referenceMIDI) / 12)
    }

    /// The duration of one cycle in milliseconds.
    static func periodMilliseconds(midi: Int) -> Double {
        1000 / frequency(midi: midi)
    }

    /// The duration of one cycle in samples at `sampleRate`: the sample rate divided by the frequency.
    static func periodSamples(midi: Int, sampleRate: Double) -> Double {
        sampleRate / frequency(midi: midi)
    }
}

/// A frequency ratio in lowest terms, such as 5/4.
struct Ratio: Hashable, Comparable, CustomStringConvertible {
    let numerator: Int
    let denominator: Int

    init(_ numerator: Int, _ denominator: Int) {
        let divisor = Ratio.greatestCommonDivisor(numerator, denominator)
        self.numerator = numerator / divisor
        self.denominator = denominator / divisor
    }

    static let unison = Ratio(1, 1)

    var value: Double { Double(numerator) / Double(denominator) }

    var description: String { "\(numerator)/\(denominator)" }

    /// The same pitch class within one octave: the ratio multiplied or divided by 2 until
    /// 1 <= ratio < 2.
    var octaveReduced: Ratio {
        var numerator = self.numerator
        var denominator = self.denominator
        while numerator >= 2 * denominator { denominator *= 2 }
        while numerator < denominator { numerator *= 2 }
        return Ratio(numerator, denominator)
    }

    static func < (lhs: Ratio, rhs: Ratio) -> Bool {
        lhs.numerator * rhs.denominator < rhs.numerator * lhs.denominator
    }

    private static func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        b == 0 ? abs(a) : greatestCommonDivisor(b, a % b)
    }
}

/// How note frequencies are computed. Every just tuning is anchored on the root: the root keeps its
/// equal-tempered frequency and every other note is a ratio above it.
enum Tuning: String, CaseIterable, Identifiable {
    case equal = "Equal temperament"
    case fiveLimit = "Just intonation (5-limit, 12 notes)"
    case hexany = "Wilson hexany 1·3·5·7"
    case dekany = "Wilson dekany 1·3·5·7·9"
    case pentadekany = "Wilson pentadekany 1·3·5·7·9·11"
    case eikosany = "Wilson eikosany 1·3·5·7·9·11"

    var id: Self { self }

    /// True for the tunings that assign one frequency to each of the 12 keys, so that the
    /// Ableton scales and the keyboard apply.
    var usesTwelveKeys: Bool { self == .equal || self == .fiveLimit }

    /// The combination product set for Erv Wilson's structures: every product of `choose` distinct
    /// factors. A hexany takes 2 of 4 factors (6 notes); a dekany 2 of 5 (10 notes); a pentadekany
    /// 2 of 6 (15 notes); an eikosany 3 of 6 (20 notes).
    var combinationProductSet: (factors: [Int], choose: Int)? {
        switch self {
        case .equal, .fiveLimit: nil
        case .hexany: ([1, 3, 5, 7], 2)
        case .dekany: ([1, 3, 5, 7, 9], 2)
        case .pentadekany: ([1, 3, 5, 7, 9, 11], 2)
        case .eikosany: ([1, 3, 5, 7, 9, 11], 3)
        }
    }

    /// The octave-reduced ratios of a combination product set, lowest first. Every product is
    /// divided by the smallest product, so that the smallest product becomes 1/1 on the root.
    var ratios: [Ratio] {
        guard let set = combinationProductSet else { return [] }
        let factors = set.factors
        var products: [Int] = []
        func collect(from start: Int, remaining: Int, product: Int) {
            if remaining == 0 {
                products.append(product)
                return
            }
            for index in start..<factors.count {
                collect(from: index + 1, remaining: remaining - 1, product: product * factors[index])
            }
        }
        collect(from: 0, remaining: set.choose, product: 1)
        let base = products.min() ?? 1
        return Set(products.map { Ratio($0, base).octaveReduced }).sorted()
    }

    /// The 5-limit just ratios for the 12 semitones above the root, indexed by semitone. They are
    /// the 12 points 3^a x 5^b with a in -1...2 and b in -1...1, a block of 4 fifths by 3 major
    /// thirds on the 5-limit lattice: 1/1, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 9/5, 15/8.
    static let fiveLimitRatios: [Ratio] = {
        var bySemitone = [Ratio](repeating: .unison, count: 12)
        for a in -1...2 {
            for b in -1...1 {
                let numerator = (a > 0 ? Tuning.power(3, a) : 1) * (b > 0 ? Tuning.power(5, b) : 1)
                let denominator = (a < 0 ? Tuning.power(3, -a) : 1) * (b < 0 ? Tuning.power(5, -b) : 1)
                let ratio = Ratio(numerator, denominator).octaveReduced
                let semitone = Int((1200 * log2(ratio.value) / 100).rounded()) % 12
                bySemitone[semitone] = ratio
            }
        }
        return bySemitone
    }()

    private static func power(_ base: Int, _ exponent: Int) -> Int {
        (0..<exponent).reduce(1) { product, _ in product * base }
    }
}

extension Pitch {
    /// The 5-limit just frequency of a MIDI note: the equal-tempered frequency of the root at or
    /// below the note, multiplied by the just ratio of the interval from that root.
    static func justFrequency(midi: Int, root: Int) -> Double {
        let semitones = NoteName.pitchClass(of: midi - root)
        return frequency(midi: midi - semitones) * Tuning.fiveLimitRatios[semitones].value
    }

    /// The deviation of `frequency` from the nearest equal-tempered note, in cents
    /// (1200 x log2 of the frequency ratio), and that note's MIDI number.
    static func nearestNote(to frequency: Double) -> (midi: Int, cents: Double) {
        let midi = Int((Double(referenceMIDI) + 12 * log2(frequency / referenceFrequency)).rounded())
        return (midi, 1200 * log2(frequency / self.frequency(midi: midi)))
    }

    static func formatCents(_ cents: Double) -> String {
        cents.formatted(.number.precision(.fractionLength(1)).sign(strategy: .always())) + "¢"
    }
}

/// One row of the table.
struct TableRow: Identifiable {
    let id: Int
    let frequency: Double
    /// A note name for the 12-key tunings, or a ratio for Wilson's structures.
    let name: String
    let captions: [String]
    let isRoot: Bool
    let isInScale: Bool
}

/// The rows of the table and the identifier of the row at its center.
struct TableContents {
    let rows: [TableRow]
    let centerID: Int

    /// Eight octaves on each side of the center note.
    static let semitonesEachSide = 8 * 12

    /// Every note in `pitchClasses` within eight octaves of `center`, highest first. The center
    /// note is always included, so that the table has a reference row even when the center is
    /// not in the scale. `root` is nil for a custom scale in equal temperament, which has no root.
    static func twelveKeys(center: Int, pitchClasses: Set<Int>, root: Int?, tuning: Tuning,
                           naming: OctaveNaming) -> TableContents {
        let range = (center - semitonesEachSide)...(center + semitonesEachSide)
        let rows: [TableRow] = range.reversed().compactMap { midi in
            let pitchClass = NoteName.pitchClass(of: midi)
            let isInScale = pitchClasses.contains(pitchClass)
            guard isInScale || midi == center else { return nil }

            var captions: [String] = []
            var frequency = Pitch.frequency(midi: midi)
            if tuning == .fiveLimit, let root {
                frequency = Pitch.justFrequency(midi: midi, root: root)
                let ratio = Tuning.fiveLimitRatios[NoteName.pitchClass(of: midi - root)]
                let cents = 1200 * log2(frequency / Pitch.frequency(midi: midi))
                captions.append("\(ratio) \(Pitch.formatCents(cents))")
            }
            if pitchClass == root { captions.append("root") }
            if midi == Pitch.middleC { captions.append("middle C") }
            if !isInScale { captions.append("not in scale") }

            return TableRow(id: midi, frequency: frequency, name: naming.name(of: midi),
                            captions: captions, isRoot: pitchClass == root, isInScale: isInScale)
        }
        return TableContents(rows: rows, centerID: center)
    }

    /// Every ratio of a Wilson structure, in every octave whose frequency lies within eight octaves
    /// of `center`, highest first. 1/1 sits on the root's equal-tempered frequency. The center row
    /// is the row nearest in frequency to the center note.
    static func ratios(_ ratios: [Ratio], root: Int, center: Int,
                       naming: OctaveNaming) -> TableContents {
        let lowest = Pitch.frequency(midi: center - semitonesEachSide)
        let highest = Pitch.frequency(midi: center + semitonesEachSide)
        let rootFrequency = Pitch.frequency(midi: Pitch.middleC + root)

        var rows: [TableRow] = []
        for octave in -10...10 {
            for (index, ratio) in ratios.enumerated() {
                let frequency = rootFrequency * ratio.value * pow(2, Double(octave))
                guard frequency >= lowest * 0.999_999, frequency <= highest * 1.000_001 else { continue }
                let nearest = Pitch.nearestNote(to: frequency)
                let caption = "≈ \(naming.name(of: nearest.midi)) \(Pitch.formatCents(nearest.cents))"
                rows.append(TableRow(id: (octave + 20) * 100 + index,
                                     frequency: frequency,
                                     name: ratio.description,
                                     captions: ratio == .unison ? [caption, "root"] : [caption],
                                     isRoot: ratio == .unison,
                                     isInScale: true))
            }
        }
        rows.sort { $0.frequency > $1.frequency }

        let centerFrequency = Pitch.frequency(midi: center)
        let centerRow = rows.min { abs(log2($0.frequency / centerFrequency))
                                   < abs(log2($1.frequency / centerFrequency)) }
        return TableContents(rows: rows, centerID: centerRow?.id ?? 0)
    }
}
