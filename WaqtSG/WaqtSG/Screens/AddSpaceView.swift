import SwiftUI

struct AddSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var building = ""
    @State private var floorLandmark = ""
    @State private var walkTime = ""
    @State private var type: SpaceType = .musollah

    @State private var showSubmitted = false      // backend accepted
    @State private var showOpenedGitHub = false    // fallback: browser issue opened
    @State private var showFailAlert = false
    @State private var submitting = false

    // Submissions are logged to "Prayer Space for Review.xlsx" in the repo. The app opens a
    // prefilled GitHub issue (no secret token in the app); a GitHub Action parses it and
    // appends a row to the workbook. Requires the user to be signed in to GitHub.
    private let repoSlug = "blueyeagle/SG-Sujood"

    private var issueTitle: String {
        "[Space] \(building.isEmpty ? "(unnamed)" : building)"
    }
    private var issueBody: String {
        """
        Building / mall: \(building)
        Floor & landmark: \(floorLandmark)
        Walk from nearest MRT exit: \(walkTime)
        Type: \(type.rawValue)

        _Submitted from Waqt SG — a moderator will review before it's added._
        """
    }

    private func githubIssueURL() -> URL? {
        var comps = URLComponents(string: "https://github.com/\(repoSlug)/issues/new")
        comps?.queryItems = [
            URLQueryItem(name: "title", value: issueTitle),
            URLQueryItem(name: "body", value: issueBody),
        ]
        return comps?.url
    }

    private func submit() {
        // Preferred: POST to the backend (anyone can submit, no GitHub account).
        if SubmissionService.isConfigured {
            submitting = true
            Task {
                let ok = await SubmissionService.submit(
                    building: building, floor: floorLandmark, walk: walkTime, type: type.rawValue)
                submitting = false
                if ok { showSubmitted = true } else { openGitHubFallback() }
            }
        } else {
            openGitHubFallback()
        }
    }

    // Fallback when no backend is set (or it's unreachable): open a prefilled GitHub issue.
    private func openGitHubFallback() {
        guard let url = githubIssueURL() else { showFailAlert = true; return }
        openURL(url) { accepted in
            if accepted { showOpenedGitHub = true } else { showFailAlert = true }
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

                PrimaryButton(title: submitting ? "Submitting…" : "Submit for review") { submit() }
                    .disabled(building.isEmpty || submitting)
                    .opacity(building.isEmpty || submitting ? 0.5 : 1)

                Text("Your submission goes to the moderator's review workbook. A moderator checks new spaces within two days.")
                    .font(Font2.body(12))
                    .foregroundStyle(Palette.mutedInk)
                    .lineSpacing(2)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.s8)
        }
        .background(Palette.bg)
        .navigationBarBackButtonHidden(true)
        .alert("Submitted", isPresented: $showSubmitted) {
            Button("Done") { dismiss() }
        } message: {
            Text("Thanks — your prayer space was sent to the moderator's review workbook.")
        }
        .alert("Opening GitHub", isPresented: $showOpenedGitHub) {
            Button("Done") { dismiss() }
        } message: {
            Text("Tap “Submit new issue” on the page that just opened to log your space to the review workbook.")
        }
        .alert("Couldn't submit", isPresented: $showFailAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Could not send your submission. Check your connection and try again.")
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
