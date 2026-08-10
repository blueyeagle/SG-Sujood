import SwiftUI

struct AddSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var building = ""
    @State private var floorLandmark = ""
    @State private var walkTime = ""
    @State private var type: SpaceType = .musollah

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

                PrimaryButton(title: "Submit for review") { dismiss() }

                Text("A moderator checks new spaces within two days. You can confirm existing listings any time — that is what keeps the floor numbers right.")
                    .font(Font2.body(12))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
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
