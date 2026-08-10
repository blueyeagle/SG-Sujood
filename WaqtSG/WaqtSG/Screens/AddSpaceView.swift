import SwiftUI

struct AddSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var building = ""
    @State private var floorLandmark = ""
    @State private var walkTime = ""
    @State private var type: SpaceType = .musollah

    @State private var showMail = false
    @State private var showNoMailAlert = false
    @State private var showSubmitted = false

    private let recipient = "suhaime.jcs@gmail.com"

    private var mailSubject: String {
        "New prayer space: \(building.isEmpty ? "(unnamed)" : building)"
    }
    private var mailBody: String {
        """
        A Waqt SG user submitted a prayer space for review:

        Building / mall: \(building)
        Floor & landmark: \(floorLandmark)
        Walk from nearest MRT exit: \(walkTime)
        Type: \(type.rawValue)

        — Sent from Waqt SG
        """
    }

    private func submit() {
        if MailComposer.canSend {
            showMail = true
        } else if let url = MailFallback.url(to: recipient, subject: mailSubject, body: mailBody) {
            openURL(url) { accepted in
                if !accepted { showNoMailAlert = true }
            }
        } else {
            showNoMailAlert = true
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                HStack { BackHeader(); Spacer() }.padding(.top, 8)

                ScreenTitle(title: "Add a space")

                Text("Two facts are enough: where it is in the building, and how long it takes to walk there.")
                    .font(Font2.body(13.5))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)

                field(label: "Building or mall", text: $building, placeholder: "Suntec City")
                field(label: "Floor and landmark", text: $floorLandmark, placeholder: "B1, Tower 2 — behind the taxi stand lobby")
                field(label: "Walking time from the nearest MRT exit", text: $walkTime, placeholder: "7 minutes")

                VStack(alignment: .leading, spacing: Space.s3) {
                    CapsLabel("Type")
                    HStack(spacing: Space.s2) {
                        ForEach(SpaceType.allCases, id: \.self) { t in
                            FilterButton(title: t.rawValue, selected: type == t) { type = t }
                        }
                    }
                }

                // Photo drop
                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundStyle(Palette.mutedInk)
                    Text("add a photo of the entrance\nso the next person recognises it")
                        .font(Font2.body(12))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Palette.mutedInk)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.s8)
                .overlay(Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Palette.divider))

                PrimaryButton(title: "Submit for review") { submit() }
                    .disabled(building.isEmpty)
                    .opacity(building.isEmpty ? 0.5 : 1)

                Text("Your submission is emailed to the Waqt SG moderator, who checks new spaces within two days. You can confirm existing listings any time — that is what keeps the floor numbers right.")
                    .font(Font2.body(12))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showMail) {
            MailComposer(recipients: [recipient], subject: mailSubject, body: mailBody) {
                showMail = false
                showSubmitted = true
            }
            .ignoresSafeArea()
        }
        .alert("Submitted", isPresented: $showSubmitted) {
            Button("Done") { dismiss() }
        } message: {
            Text("Thanks — your prayer space was sent to the moderator for review.")
        }
        .alert("No mail account", isPresented: $showNoMailAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Set up Mail on this device, or email the details to \(recipient).")
        }
    }

    private func field(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font2.medium(13))
                .foregroundStyle(Palette.text)
            TextField(placeholder, text: text)
                .font(Font2.body(15))
                .foregroundStyle(Palette.text)
                .padding(.vertical, 12)
                .padding(.horizontal, Space.s3)
                .background(Palette.surface)
                .overlay(Rectangle().stroke(Palette.divider, lineWidth: 1))
        }
    }
}
