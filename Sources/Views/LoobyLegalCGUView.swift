import SwiftUI

public struct LoobyLegalCGUView: View {
    @EnvironmentObject var vm: LoobyViewModel

    private var filteredArticles: [LoobyLegalArticle] {
        let q = vm.cguSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return vm.legalArticles }
        return vm.legalArticles.filter { art in
            art.title.lowercased().contains(q)
            || art.number.lowercased().contains(q)
            || art.paragraphs.contains { $0.lowercased().contains(q) }
        }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Card
                LoobyGlassCard(borderColor: LoobyPalette.goldAmber.opacity(0.45)) {
                    HStack {
                        LoobyBadgePill(text: "DOCUMENT OFFICIEL VIPLE SAS", color: LoobyPalette.goldAmber)
                        Spacer()
                        LoobyBadgePill(text: "VERSION 2.0 • 21/11/2026", color: LoobyPalette.infinityCyan)
                    }

                    Text("Conditions Générales d'Utilisation (CGU) de la Marketplace Looby")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Applicables à la nouvelle plateforme B2C réunissant les commerces locaux du Grand Est (ouverture commerciale le 21/11/2026) et à l'utilisation du compte unique Viple Live ID.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(LoobyPalette.textSecondary)

                    // Acceptance Status Pill
                    HStack(spacing: 10) {
                        Image(systemName: vm.cguAccepted ? "checkmark.seal.fill" : "doc.badge.clock")
                            .font(.system(size: 20))
                            .foregroundStyle(vm.cguAccepted ? LoobyPalette.infinityMint : LoobyPalette.goldAmber)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(vm.cguAccepted ? "CGU Looby v2 acceptées" : "Prenez connaissance des nouvelles CGU B2C")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                            Text(vm.cguAccepted
                                 ? "Horodatage : \(vm.cguAcceptedDateString)"
                                 : "Passage d'une plateforme C2C à une marketplace B2C des commerces du Grand Est")
                                .font(.system(size: 11.5))
                                .foregroundStyle(LoobyPalette.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(LoobyPalette.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if !vm.cguAccepted {
                        Button {
                            vm.acceptLoobyCGU()
                        } label: {
                            Label("J'ai lu et j'accepte les CGU de la Marketplace Looby v2", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(LoobyPalette.infinityGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                // Search inside CGU
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LoobyPalette.infinityCyan)
                    TextField("Rechercher un article (ex: Grand Est, B2C, rétractation, Viple Live ID)…", text: $vm.cguSearchQuery)
                        .foregroundStyle(.white)
                }
                .padding(12)
                .background(LoobyPalette.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(LoobyPalette.border, lineWidth: 1))

                // Articles List
                ForEach(filteredArticles) { art in
                    LoobyGlassCard {
                        HStack {
                            Label("\(art.number) — \(art.title)", systemImage: art.icon)
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                        }

                        LoobyBadgePill(text: art.summaryBadge, color: LoobyPalette.infinityMint)

                        ForEach(art.paragraphs, id: \.self) { para in
                            Text(para)
                                .font(.system(size: 12.5))
                                .foregroundStyle(LoobyPalette.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(LoobyPalette.bgPrimary.ignoresSafeArea())
    }
}
