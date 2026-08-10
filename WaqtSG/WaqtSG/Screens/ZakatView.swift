import SwiftUI

struct ZakatView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var nisab: NisabStore
    @Environment(\.openURL) private var openURL
    @State private var editing = false

    private var lowestBalance: Double { state.lowestBalance }
    private var aboveNisab: Bool { lowestBalance >= nisab.current.value }
    private var zakatDue: Double { state.zakatDue }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                bodySection
            }
        }
        .background(Palette.bg)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $editing) { ZakatEditSheet() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            HStack { BackHeaderDark(); Spacer() }
                .padding(.top, 56)

            CapsLabel("Kadar nisab · \(nisab.current.month)", color: Palette.accent400)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(nisab.current.formatted)
                    .font(Font2.condensed(62))
                    .foregroundStyle(Palette.paperInk)
                    .monospacedDigit()
                Text("SGD")
                    .font(Font2.body(15))
                    .foregroundStyle(Palette.paperInkMuted)
                    .padding(.leading, 4)
            }

            Text("The value of 86 grams of gold, published monthly by MUIS. Wealth held above this figure for a full haul is subject to zakat harta.")
                .font(Font2.body(13.5))
                .foregroundStyle(Palette.paperInkMuted)
                .lineSpacing(3)

            Text(sourceLine)
                .font(Font2.body(11))
                .foregroundStyle(Palette.paperInkMuted)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.bottom, Space.s6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.accent900)
    }

    private var sourceLine: String {
        switch nisab.origin {
        case .remote:  return "Updated from MUIS config"
        case .cached:  return "From last synced MUIS figure"
        case .bundled: return "Built-in figure · syncing latest…"
        }
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: Space.s6) {
            endOfHaul
            holding
            history
            VStack(spacing: Space.s3) {
                PrimaryButton(title: "Pay zakat") {
                    if let url = URL(string: "https://pay.zakat.sg/") { openURL(url) }
                }
                GhostButton(title: "Set a reminder for \(state.longDate(state.haulEnd))") {}
            }
            Text("Figures are an estimate for planning. Confirm the current nisab and your zakat with MUIS before paying.")
                .font(Font2.body(12))
                .foregroundStyle(Palette.mutedInk)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.s6)
        .padding(.bottom, Space.s8)
    }

    private var endOfHaul: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("End of haul")
            Text(state.haulCountdown)
                .font(Font2.condensed(36))
                .foregroundStyle(Palette.text)
                .monospacedDigit()
            Text("Haul began \(state.longDate(state.haulStartDate)) · completes \(state.longDate(state.haulEnd))")
                .font(Font2.body(12.5))
                .foregroundStyle(Palette.mutedInk)
            ProgressRail(fraction: state.haulFraction)
                .padding(.vertical, 4)
            HStack {
                Text("Day \(state.haulDay)")
                    .font(Font2.body(12.5)).foregroundStyle(Palette.mutedInk)
                Spacer()
                Text("\(state.haulTotalDays) days · one lunar year")
                    .font(Font2.body(12.5)).foregroundStyle(Palette.mutedInk)
            }
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .blueprint()
    }

    private var holding: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack {
                CapsLabel("Your holding")
                Spacer()
                Button { editing = true } label: { CapsLabel("Edit", color: Palette.accent700) }
                    .buttonStyle(.plain)
            }
            HStack(spacing: 0) {
                cell(label: "Lowest balance", big: money(lowestBalance),
                     note: aboveNisab ? "Held above nisab all haul" : "Below nisab this haul",
                     tag: aboveNisab ? "Above nisab" : "Below nisab")
                Rectangle().fill(Palette.divider).frame(width: 1)
                cell(label: "Zakat at 2.5%", big: aboveNisab ? money(zakatDue) : "—",
                     note: aboveNisab ? "Payable on \(state.longDate(state.haulEnd))" : "None due below nisab",
                     tag: "Zakat harta")
            }
            .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
    }

    private func cell(label: String, big: String, note: String, tag: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CapsLabel(label, size: 10)
            Text(big)
                .font(Font2.condensed(28))
                .foregroundStyle(Palette.text)
                .monospacedDigit()
            Text(note)
                .font(Font2.body(12))
                .foregroundStyle(Palette.mutedInk)
            Text(tag)
                .font(Font2.medium(10))
                .tracking(0.5)
                .foregroundStyle(Palette.accent700)
                .padding(.vertical, 3).padding(.horizontal, 7)
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
    }

    private var history: some View {
        // Show the most recent 12 months; the full series stays in nisab.json.
        let recent = Array(nisab.history.prefix(12))
        return VStack(alignment: .leading, spacing: Space.s3) {
            CapsLabel("Recent months")
            VStack(spacing: 0) {
                ForEach(Array(recent.enumerated()), id: \.offset) { idx, row in
                    if idx > 0 { Hairline() }
                    HStack {
                        Text(row.month).font(Font2.body(14)).foregroundStyle(Palette.text)
                        Spacer()
                        Text(row.formatted).font(Font2.body(14)).foregroundStyle(Palette.text).monospacedDigit()
                    }
                    .padding(.horizontal, Space.s4)
                    .padding(.vertical, 12)
                }
            }
            .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
    }

    private func money(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return "$" + (f.string(from: NSNumber(value: v)) ?? "\(Int(v))")
    }
}

// Editable, persisted zakat inputs: lowest balance + haul start. End of haul is derived.
struct ZakatEditSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var balanceText = ""
    @State private var haulStart = Date()

    private var computedEnd: Date {
        Calendar.current.date(byAdding: .day, value: state.haulTotalDays, to: haulStart) ?? haulStart
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Lowest balance held (SGD)") {
                    TextField("e.g. 24000", text: $balanceText)
                        .keyboardType(.decimalPad)
                }
                Section("Start of haul") {
                    DatePicker("Haul began", selection: $haulStart, displayedComponents: .date)
                    LabeledContent("End of haul", value: state.longDate(computedEnd))
                    Text("End of haul is one lunar year (354 days) after the start.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleaned = balanceText.replacingOccurrences(of: ",", with: "")
                            .replacingOccurrences(of: "$", with: "")
                        if let v = Double(cleaned) { state.lowestBalance = v }
                        state.haulStartDate = haulStart
                        dismiss()
                    }
                }
            }
            .onAppear {
                balanceText = String(Int(state.lowestBalance))
                haulStart = state.haulStartDate
            }
        }
    }
}
