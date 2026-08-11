import SwiftUI

struct DzikirView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack {
            Palette.accent900.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack { BackHeaderDark(); Spacer() }
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, 8)

                // Preset chips
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Space.s2) {
                    ForEach(Array(SampleData.dzikir.enumerated()), id: \.element.id) { idx, phrase in
                        chip(idx: idx, phrase: phrase)
                    }
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.s4)

                Spacer()

                // Tap target — the whole centre area
                counterArea

                Spacer()

                bottomBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .contentShape(Rectangle())
    }

    private func chip(idx: Int, phrase: DzikirPhrase) -> some View {
        let selected = state.dzikirIndex == idx
        return Button { state.selectDzikir(idx) } label: {
            Text("\(phrase.name.uppercased()) \(phrase.target)")
                .font(Font2.medium(11))
                .tracking(0.8)
                .foregroundStyle(selected ? Palette.accent900 : Palette.paperInk.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Palette.accent : Color.clear)
                .overlay(Rectangle().stroke(selected ? Color.clear : Palette.accent400.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var counterArea: some View {
        Button { state.tapDzikir() } label: {
            VStack(spacing: Space.s3) {
                CapsLabel(state.currentDzikir.name, color: Palette.accent400, size: 12)
                Text(state.currentDzikir.meaning)
                    .font(Font2.body(14))
                    .foregroundStyle(Palette.paperInkMuted)

                Text("\(state.dzikirCount)")
                    .font(Font2.condensed(132))
                    .foregroundStyle(Palette.paperInk)
                    .monospacedDigit()

                Text("of \(state.currentDzikir.target)")
                    .font(Font2.body(15))
                    .foregroundStyle(Palette.paperInkMuted)

                ProgressRail(fraction: Double(state.dzikirCount) / Double(state.currentDzikir.target), onDark: true)
                    .frame(width: 200)
                    .padding(.top, Space.s2)

                CapsLabel("Tap anywhere to count", color: Palette.paperInkMuted, size: 10)
                    .padding(.top, Space.s3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Hairline(onDark: true)
            HStack {
                Text("Full rounds completed today · \(state.dzikirRounds)")
                    .font(Font2.body(12.5))
                    .foregroundStyle(Palette.paperInkMuted)
                Spacer()
                barButton("Undo") { state.undoDzikir() }
                barButton("Reset") { state.resetDzikir() }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.vertical, Space.s3)
        }
    }

    private func barButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(Font2.medium(10.5))
                .tracking(1)
                .foregroundStyle(Palette.paperInk)
                .padding(.vertical, 8).padding(.horizontal, 14)
                .overlay(Rectangle().stroke(Palette.accent400.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
