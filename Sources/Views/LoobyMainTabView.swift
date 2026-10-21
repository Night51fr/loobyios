import SwiftUI

public struct LoobyMainTabView: View {
    @EnvironmentObject var vm: LoobyViewModel

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                topLoobyHeader

                TabView(selection: $vm.selectedTab) {
                    // TAB 0: Présentation Animée Looby v2 (21/11/2026)
                    LoobyShowcaseHomeView()
                        .environmentObject(vm)
                        .tabItem {
                            Label("Looby v2", systemImage: "infinity")
                        }
                        .tag(0)

                    // TAB 1: Viple Live ID vs Ancien Viple ID + Projet Livria
                    LoobyVipleIdAndLivriaView()
                        .environmentObject(vm)
                        .tabItem {
                            Label("Viple ID & Livria", systemImage: "sparkles.rectangle.stack.fill")
                        }
                        .tag(1)

                    // TAB 2: Commerces Locaux du Grand Est (B2C) & Simulateur Pro
                    LoobyGrandEstB2CExplorerView()
                        .environmentObject(vm)
                        .tabItem {
                            Label("Grand Est B2C", systemImage: "storefront.fill")
                        }
                        .tag(2)

                    // TAB 3: Espace Mes Commandes (Livria & Looby) & Compte Viple Live ID
                    LoobyOrdersAndAccountView()
                        .environmentObject(vm)
                        .tabItem {
                            Label("Mes Commandes", systemImage: "shippingbox.fill")
                        }
                        .tag(3)

                    // TAB 4: CGU Officielles de la Marketplace Looby B2C
                    LoobyLegalCGUView()
                        .environmentObject(vm)
                        .tabItem {
                            Label("CGU Looby", systemImage: "doc.text.fill")
                        }
                        .tag(4)
                }
                .tint(LoobyPalette.infinityCyan)
            }

            // Floating Toast & Error Notifications
            VStack(spacing: 8) {
                if let toast = vm.toastMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(LoobyPalette.infinityMint)
                        Text(toast)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Spacer()
                        Button {
                            vm.toastMessage = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(LoobyPalette.cardElevated.opacity(0.97))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(LoobyPalette.infinityMint.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
                    .padding(.horizontal, 16)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let err = vm.errorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(LoobyPalette.livriaCoral)
                        Text(err)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                        Spacer()
                        Button {
                            vm.errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color(red: 0.28, green: 0.08, blue: 0.12).opacity(0.97))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, vm.toastMessage == nil ? 64 : 4)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $vm.showLoginSheet) {
            LoobyVipleLiveIdAuthSheet()
                .environmentObject(vm)
        }
    }

    // MARK: - Top Header Bar

    private var topLoobyHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image("LoobyLogo")
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("Looby")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("v2 • 21/11/2026")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(LoobyPalette.infinityMint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(LoobyPalette.infinityMint.opacity(0.16))
                            .clipShape(Capsule())
                    }
                    Text("Marketplace B2C des Commerces du Grand Est")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LoobyPalette.textSecondary)
                }
            }

            Spacer()

            Button {
                if vm.isAuthenticated {
                    vm.selectedTab = 3
                } else {
                    vm.showLoginSheet = true
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: vm.isAuthenticated ? "person.crop.circle.fill.badge.checkmark" : "person.badge.key.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(vm.isAuthenticated ? vm.currentUser.displayName : "Connexion")
                        .font(.system(size: 11.5, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(LoobyPalette.infinityGradient)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(LoobyPalette.cardBg)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LoobyPalette.border)
                .frame(height: 1)
        }
    }
}
