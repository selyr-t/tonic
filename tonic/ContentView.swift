import SwiftUI

struct ContentView: View {
    @State private var root = 0
    @State private var scale = Scale.all[0]
    @State private var isCustom = false
    /// Absolute pitch classes selected on the keyboard.
    @State private var customPitchClasses: Set<Int> = []
    /// The MIDI note number at the center of the table. 60 is middle C.
    @State private var center = Pitch.middleC
    @State private var naming: OctaveNaming = .scientific
    @State private var tuning: Tuning = .equal
    /// A preset sample rate, or nil when "Other" is selected.
    @State private var presetRate: Int? = 48000
    @State private var customRate: Double = 48000

    private static let presetRates = [22050, 44100, 48000, 96000]

    private var sampleRate: Double {
        presetRate.map(Double.init) ?? customRate
    }

    private var isSampleRateValid: Bool {
        sampleRate.isFinite && sampleRate > 0
    }

    private var pitchClasses: Set<Int> {
        isCustom ? customPitchClasses : scale.pitchClasses(root: root)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                controls
                Divider()
                if tuning.usesTwelveKeys && pitchClasses.isEmpty {
                    ContentUnavailableView("Select at least one note on the keyboard",
                                           systemImage: "pianokeys")
                } else if !isSampleRateValid {
                    ContentUnavailableView("Enter a sample rate greater than zero",
                                           systemImage: "waveform")
                } else {
                    table
                }
            }
            .navigationTitle("tonic")
            // Wilson's structures have their own notes, so the keyboard does not apply to them.
            .onChange(of: tuning) { _, newTuning in
                if !newTuning.usesTwelveKeys { isCustom = false }
            }
            // The keyboard starts from the current scale, so that a custom scale is an edit of it.
            .onChange(of: isCustom) { _, isOn in
                if isOn && customPitchClasses.isEmpty {
                    customPitchClasses = scale.pitchClasses(root: root)
                }
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Tuning", selection: $tuning) {
                ForEach(Tuning.allCases) { tuning in
                    Text(tuning.rawValue).tag(tuning)
                }
            }
            .fixedSize()

            HStack {
                Picker("Root", selection: $root) {
                    ForEach(0..<12, id: \.self) { pitchClass in
                        Text(NoteName.sharps[pitchClass]).tag(pitchClass)
                    }
                }
                .fixedSize()
                // A just tuning needs a root even for a custom scale, because every ratio is
                // measured from the root.
                .disabled(isCustom && tuning == .equal)
                Picker("Scale", selection: $scale) {
                    ForEach(Scale.all) { scale in
                        Text(scale.name).tag(scale)
                    }
                }
                .fixedSize()
                .disabled(isCustom || !tuning.usesTwelveKeys)
                Spacer(minLength: 0)
            }

            HStack {
                Toggle("Custom scale", isOn: $isCustom)
                    .toggleStyle(CheckboxStyle())
                    .disabled(!tuning.usesTwelveKeys)
                Spacer(minLength: 8)
                if presetRate == nil {
                    TextField("Sample rate", value: $customRate, format: .number)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .frame(maxWidth: 80)
                }
                Picker("Sample rate", selection: $presetRate) {
                    ForEach(Self.presetRates, id: \.self) { rate in
                        Text("\(rate) Hz").tag(Optional(rate))
                    }
                    Text("Other").tag(Int?.none)
                }
                .labelsHidden()
                .fixedSize()
            }

            if isCustom {
                KeyboardPicker(selection: $customPitchClasses)
                    .frame(maxWidth: 420)
            }

            HStack {
                Text("Center")
                Picker("Center note", selection: centerPitchClass) {
                    ForEach(0..<12, id: \.self) { pitchClass in
                        Text(NoteName.sharps[pitchClass]).tag(pitchClass)
                    }
                }
                .labelsHidden()
                .fixedSize()
                Stepper(value: centerOctave, in: naming.lowestOctave...(naming.lowestOctave + 10)) {
                    Text("Octave \(centerOctave.wrappedValue)")
                        .monospacedDigit()
                }
                .fixedSize()
                Spacer(minLength: 0)
            }

            Picker("Octave numbers", selection: $naming) {
                ForEach(OctaveNaming.allCases) { naming in
                    Text(naming.rawValue).tag(naming)
                }
            }
            .labelsHidden()
            .fixedSize()
        }
        .pickerStyle(.menu)
        .padding()
    }

    /// The center note's pitch class; changing it keeps the octave.
    private var centerPitchClass: Binding<Int> {
        Binding(
            get: { NoteName.pitchClass(of: center) },
            set: { center = center - NoteName.pitchClass(of: center) + $0 })
    }

    /// The center note's octave number in the selected naming; changing it keeps the pitch class.
    /// The stepper's range keeps the center within MIDI notes 0 to 131.
    private var centerOctave: Binding<Int> {
        Binding(
            get: { (center - NoteName.pitchClass(of: center)) / 12 + naming.lowestOctave },
            set: { center = ($0 - naming.lowestOctave) * 12 + NoteName.pitchClass(of: center) })
    }

    private var contents: TableContents {
        if tuning.usesTwelveKeys {
            return TableContents.twelveKeys(center: center,
                                            pitchClasses: pitchClasses,
                                            root: isCustom && tuning == .equal ? nil : root,
                                            tuning: tuning,
                                            naming: naming)
        }
        return TableContents.ratios(tuning.ratios, root: root, center: center, naming: naming)
    }

    private var table: some View {
        let contents = contents
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    row(label: Text("Note"), hertz: Text("Hz"), milliseconds: Text("ms"),
                        samples: Text("samples"), isHighlighted: false)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Divider()
                    ForEach(contents.rows) { note in
                        row(label: label(for: note),
                            hertz: Text(note.frequency, format: Self.numberFormat),
                            milliseconds: Text(1000 / note.frequency, format: Self.numberFormat),
                            samples: Text(sampleRate / note.frequency, format: Self.samplesFormat),
                            isHighlighted: note.id == contents.centerID)
                            .foregroundStyle(note.isInScale ? HierarchicalShapeStyle.primary
                                                            : HierarchicalShapeStyle.secondary)
                            .id(note.id)
                    }
                }
            }
            .onAppear { proxy.scrollTo(contents.centerID, anchor: .center) }
            .onChange(of: center) { proxy.scrollTo(contents.centerID, anchor: .center) }
            .onChange(of: tuning) { proxy.scrollTo(contents.centerID, anchor: .center) }
        }
    }

    /// At most six significant digits, because the values span from about 0.01 to about 67,000.
    private static let numberFormat = FloatingPointFormatStyle<Double>.number
        .precision(.significantDigits(1...6))

    /// Every whole sample and up to two decimal places, because a delay is set in samples and the
    /// fractional part shows how far a whole-sample delay is from the exact period.
    private static let samplesFormat = FloatingPointFormatStyle<Double>.number
        .precision(.fractionLength(0...2))

    /// The captions sit under the note name, so that the note column stays narrow.
    private func label(for note: TableRow) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(note.name)
                .fontWeight(note.isRoot ? .bold : .regular)
            if !note.captions.isEmpty {
                Text(note.captions.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// One table row: a fixed-width note column and three value columns that share the rest.
    /// The vertical padding is on each cell rather than on the row, so that the column
    /// separators run the full height of the row and meet the separators of the next row.
    private func row(label: some View, hertz: Text, milliseconds: Text, samples: Text,
                     isHighlighted: Bool) -> some View {
        HStack(spacing: 0) {
            label
                .padding(.vertical, 8)
                .padding(.trailing, 8)
                // Just tunings add a ratio and a cents value under each name, which need more width.
                .frame(width: tuning == .equal ? 72 : 104, alignment: .leading)
            ForEach(Array([hertz, milliseconds, samples].enumerated()), id: \.offset) { _, value in
                ColumnSeparator()
                value
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // The row is as tall as its tallest cell, and each separator fills that height.
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
        .background(isHighlighted ? Color.accentColor.opacity(0.18) : Color.clear)
    }
}

/// A vertical line one physical pixel wide that fills the height of its row, so that the lines
/// of consecutive rows join into one line per column.
struct ColumnSeparator: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(.separator)
            .frame(width: 1 / displayScale)
    }
}

/// One octave of piano keys. Each key toggles its pitch class in `selection`.
struct KeyboardPicker: View {
    @Binding var selection: Set<Int>

    private static let whiteKeys = [0, 2, 4, 5, 7, 9, 11]
    /// Each black key's pitch class and the number of white keys to its left.
    private static let blackKeys: [Int: Int] = [1: 1, 3: 2, 6: 4, 8: 5, 10: 6]

    var body: some View {
        GeometryReader { geometry in
            let whiteWidth = geometry.size.width / 7
            let blackWidth = whiteWidth * 0.6
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(Self.whiteKeys, id: \.self) { pitchClass in
                        key(pitchClass, isBlack: false)
                            .frame(width: whiteWidth, height: geometry.size.height)
                    }
                }
                ForEach(Self.blackKeys.keys.sorted(), id: \.self) { pitchClass in
                    key(pitchClass, isBlack: true)
                        .frame(width: blackWidth, height: geometry.size.height * 0.6)
                        .offset(x: whiteWidth * Double(Self.blackKeys[pitchClass]!) - blackWidth / 2)
                }
            }
        }
        .frame(height: 110)
    }

    private func key(_ pitchClass: Int, isBlack: Bool) -> some View {
        let isOn = selection.contains(pitchClass)
        return Button {
            if isOn {
                selection.remove(pitchClass)
            } else {
                selection.insert(pitchClass)
            }
        } label: {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(isOn ? Color.accentColor : (isBlack ? Color.black : Color.white))
                Rectangle()
                    .strokeBorder(Color.gray, lineWidth: 1)
                Text(NoteName.sharps[pitchClass])
                    .font(.caption2)
                    .foregroundStyle(isOn || isBlack ? Color.white : Color.black)
                    .padding(.bottom, 4)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A checkbox that draws the same on iPhone and on the Mac. SwiftUI's own checkbox style
/// exists only on macOS.
struct CheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? Color.accentColor : Color.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
