# tonic

*tonic* is a SwiftUI app that lists the diatonic notes of a selected scale across eight octaves above and below a center note. The app converts pitch into its corresponding frequency in Hz, its period in milliseconds, and its period in samples as a reference table. Identical to `chron` This is intended as a convenience for users needing pitch-to-time conversions on hand for musical or other general purpose audio tools. Users can choose a scale or build their own on a keyboard, switch between equal temperament and several just-intonation tunings, and choose the sample rate that the samples column is calculated at to match their current project.


## Features

- **Scale Selection:** A root (C to B) and a scale are chosen from dropdown menus. The scale names and their order follow the Scale chooser in Ableton Live 12, from Major, Minor, and the church modes to the Messiaen modes, for 35 scales in total.

- **Custom Scales:** Checking "Custom scale" grays out the scale menus and reveals a one-octave keyboard. Each key adds or removes its note, and the keyboard starts from the notes of the current scale, so that a custom scale is an edit of it.

- **Center Note:** A note menu and an octave stepper set the center of the table, which defaults to middle C. The table lists every note of the scale within eight octaves ($\pm 96$ semitones) of the center note, and the center note always has a row, even when it is not in the scale.

- **Octave Numbering:** A dropdown menu switches the note names between scientific pitch notation (middle C $=$ C4) and Ableton's numbering (middle C $=$ C3).

- **Tunings:** A dropdown menu selects how the frequencies are calculated:
    - **Equal temperament:** every semitone is $2^{1/12}$ of an octave.
    - **Just intonation (5-limit, 12 notes):** each key is a just ratio above the root, with the root at its equal-tempered frequency.
    - **Wilson combination product sets:** Erv Wilson's hexany, dekany, pentadekany, and eikosany, which replace the 12 keys with their own notes. *The scale menu and the keyboard do not apply to these tunings*.

- **Custom Samplerates:** A dropdown menu provides standard samplerates ($22050$, $44100$, $48000$, or $96000$) as well as the option for custom rates to be entered when "Other" is selected.

- **Clean Table Formatting:** The table scrolls with the center note appearing highlighted at the center. Each row is captioned with "root", "middle C", or "not in scale" where they apply, and the just tunings add each note's ratio and its offset in cents from equal temperament.

## How the values are calculated

Every column is computed from the frequency $f$ of a note. In equal temperament, a note with MIDI number $m$ has the frequency

$$f = 440 \cdot 2^{(m - 69)/12} \text{ Hz},$$

where $m = 69$ is A4 and $m = 60$ is middle C. Each column then converts that frequency into its own unit:

| Column | Value |
|---|---|
| Hz | $f$ |
| ms | $1000 / f$ |
| samples | $f_s / f$ |

The ms and samples columns are the length of one cycle of the note, so a delay set to either value with feedback resonates at the note's frequency.

### Just intonation (5-limit, 12 notes)

The root keeps its equal-tempered frequency, and every other note is the root's frequency multiplied by the ratio of its interval above the root:

| Semitones | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ratio | $\frac{1}{1}$ | $\frac{16}{15}$ | $\frac{9}{8}$ | $\frac{6}{5}$ | $\frac{5}{4}$ | $\frac{4}{3}$ | $\frac{45}{32}$ | $\frac{3}{2}$ | $\frac{8}{5}$ | $\frac{5}{3}$ | $\frac{9}{5}$ | $\frac{15}{8}$ |
| Cents from equal | $0$ | $+11.7$ | $+3.9$ | $+15.6$ | $-13.7$ | $-2.0$ | $-9.8$ | $+2.0$ | $+13.7$ | $-15.6$ | $+17.6$ | $-11.7$ |

The ratios are the twelve products $3^a \cdot 5^b$ with $a$ from $-1$ to $2$ and $b$ from $-1$ to $1$, each reduced to one octave. The offset in cents is $1200 \log_2 (f_{\text{just}} / f_{\text{equal}})$.

### Wilson combination product sets

A combination product set multiplies every choice of $k$ factors from a list of factors:

| Tuning | Factors | $k$ | Notes |
|---|---|---|---|
| Hexany | 1, 3, 5, 7 | 2 | 6 |
| Dekany | 1, 3, 5, 7, 9 | 2 | 10 |
| Pentadekany | 1, 3, 5, 7, 9, 11 | 2 | 15 |
| Eikosany | 1, 3, 5, 7, 9, 11 | 3 | 20 |

Each product is divided by the smallest product, so that the smallest product becomes $\frac{1}{1}$ on the root, and is then reduced to one octave. The hexany, for example, becomes $\frac{1}{1}$, $\frac{7}{6}$, $\frac{5}{4}$, $\frac{35}{24}$, $\frac{5}{3}$, $\frac{7}{4}$. The rows are labeled by ratio, and each row is captioned with its nearest equal-tempered note and the offset in cents.

At a root of C and a 48 kHz sampling rate:

| Row | Tuning | Hz | ms | samples | Caption |
|---|---|---|---|---|---|
| A4 | Equal | 440 | 2.27273 | 109.09 | |
| C4 (root) | Equal | 261.626 | 3.82226 | 183.47 | middle C |
| E4 | Equal | 329.628 | 3.03373 | 145.62 | |
| E4 | Just (5-limit) | 327.032 | 3.05781 | 146.77 | $\frac{5}{4}$, $-13.7$¢ |
| G4 | Just (5-limit) | 392.438 | 2.54817 | 122.31 | $\frac{3}{2}$, $+2.0$¢ |
| $\frac{7}{4}$ | Hexany | 457.845 | 2.18415 | 104.84 | ≈ A#4, $-31.2$¢ |

## Assumptions

- A4 is tuned to 440 Hz.
- Note names use sharps only (A# rather than B♭).
- The just tunings keep the root at its equal-tempered frequency, and every other note is a ratio above it.
- The scale list follows the names in Ableton Live 12's Scale chooser. Ableton does not publish the intervals of each scale, so the intervals are the standard definitions of each scale and should be checked against Live before they are relied on.

## Requirements

- Xcode 16 or later
- macOS 15.0 or later

## Building

1. Clone the repository and open `tonic.xcodeproj` in Xcode.
2. Select the `tonic` target, open Signing & Capabilities, and select a team. A free Apple Account appears as a Personal Team.
3. Select My Mac as the run destination, and choose Product > Run.

## Project structure

| File | Contents |
|---|---|
| `tonicApp.swift` | The app entry point (`@main`), the splash window, and the main window. |
| `SplashView.swift` | `SplashView` (the splash window on macOS) and `SplashGate` (the splash screen on iPhone). |
| `ContentView.swift` | The menus, the keyboard (`KeyboardPicker`), the checkbox style, and the table. |
| `ScaleMath.swift` | `Scale` (the scale list), `OctaveNaming`, `Pitch` (frequencies and cents), `Ratio` and `Tuning` (the just tunings), and `TableContents` (the rows of the table). |
