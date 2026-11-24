import SwiftUI

// MARK: - Onglet 4 : RDV Clients, Disponibilités, Horaires Pro Lundi–Dimanche & Mode Vacances (`ScheduleAndAvailabilityView.swift` • Swift 6)

private enum ScheduleSubSection: String, CaseIterable, Identifiable, Sendable {
    case primary = "primary"
    case hours = "hours"
    case vacation = "vacation"

    var id: String { rawValue }
}

public struct ScheduleAndAvailabilityView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel

    @State private var selectedSection: ScheduleSubSection = .primary

    // États brouillons Horaires & Disponibilités
    @State private var openingSummaryDraft: String = ""
    @State private var isClosedOverrideDraft: Bool = false
    @State private var closureReasonDraft: String = ""
    @State private var scheduleDraft: [TakerDaySchedule] = []
    @State private var availabilitiesDraft: [TakerAvailabilitySlot] = []
    @State private var isSavingHours: Bool = false

    // Ajout rapide de créneau de disponibilité Particulier
    @State private var newSlotDayLabel: String = "Soirée (Lun–Ven)"
    @State private var newSlotStart: String = "17:30"
    @State private var newSlotEnd: String = "20:30"
    @State private var newSlotAcceptsDeliveries: Bool = true
    @State private var newSlotAcceptsPickups: Bool = true

    // États brouillons Mode Vacances / Congés
    @State private var vacationEnabledDraft: Bool = false
    @State private var vacationStartDraft: String = ""
    @State private var vacationEndDraft: String = ""
    @State private var vacationMessageDraft: String = ""
    @State private var allowExistingPickupsOnlyDraft: Bool = true
    @State private var isSavingVacation: Bool = false

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                adaptiveSubTabPicker

                switch selectedSection {
                case .primary:
                    if vm.isProMode {
                        proExceptionClosureSection
                    } else {
                        particulierAppointmentsSection
                    }
                case .hours:
                    if vm.isParticulierMode {
                        particulierAvailabilitySlotsSection
                    }
                    weeklyScheduleEditorSection
                case .vacation:
                    vacationModeEditorSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
        .loobyTakerScreenBackground()
        .navigationTitle(vm.isProMode ? "Horaires & Congés" : "RDV, Dispos & Vacances")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncDraftsFromActiveRelay()
        }
        .onChange(of: vm.activeRelay) { _, _ in
            syncDraftsFromActiveRelay()
        }
    }

    private var adaptiveSubTabPicker: some View {
        HStack(spacing: 8) {
            sectionChip(
                .primary,
                title: vm.isProMode ? "Statut Boutique" : "RDV Clients",
                icon: vm.isProMode ? "door.left.hand.open" : "calendar.badge.clock"
            )
            sectionChip(
                .hours,
                title: vm.isProMode ? "Horaires Lun–Dim" : "Mes Dispos",
                icon: "clock.fill"
            )
            sectionChip(
                .vacation,
                title: vm.isProMode ? "Congés" : "Vacances",
                icon: "sun.horizon.fill"
            )
        }
    }

    private func sectionChip(_ section: ScheduleSubSection, title: String, icon: String) -> some View {
        let selected = selectedSection == section
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                selectedSection = section
            }
            LoobyTakerHaptics.impact(0)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(selected ? LoobyTakerPalette.amberPrimary : LoobyTakerPalette.cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(selected ? Color.clear : LoobyTakerPalette.border, lineWidth: 1)
            )
            .foregroundStyle(selected ? .white : LoobyTakerPalette.inkSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 1A. Mode Particulier : Gestion Complète des Rendez-Vous Clients (`RDV`)

    private var particulierAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rendez-vous de retrait clients")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                    Text("Convenez d'un créneau précis avec chaque acheteur pour lui remettre son colis contre son Code PIN.")
                        .font(.system(size: 12))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
                Spacer()
            }

            Button {
                vm.prefilledAppointmentParcel = vm.inStockParcels.first
                vm.isShowingAppointmentComposer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                    Text("Donner un RDV de retrait à un client")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(LoobyTakerPalette.goldCoralHorizontal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if vm.appointments.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)
                    Text("Aucun rendez-vous planifié")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                    Text("Appuyez sur « Donner un RDV de retrait » pour proposer un horaire à un client ayant un colis en stock.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .loobyTakerCard()
            } else {
                ForEach(vm.appointments) { appt in
                    appointmentCard(appt)
                }
            }
        }
    }

    private func appointmentCard(_ appt: TakerAppointment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appt.customerName)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                    Text("Colis \(appt.vipleBarcode)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(LoobyTakerPalette.amberDeep)
                }
                Spacer()
                Text(appt.status)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(appointmentStatusColor(appt.status).opacity(0.15)))
                    .foregroundStyle(appointmentStatusColor(appt.status))
            }

            HStack(spacing: 14) {
                Label(appt.slotDate.isEmpty ? "Aujourd'hui" : appt.slotDate, systemImage: "calendar")
                Label(appt.timeRangeLabel, systemImage: "clock.fill")
                if !appt.customerPhone.isEmpty {
                    Label(appt.customerPhone, systemImage: "phone.fill")
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(LoobyTakerPalette.inkSecondary)

            if !appt.notes.isEmpty {
                Text(appt.notes)
                    .font(.system(size: 12))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
            }

            // Boutons rapides de changement de statut RDV
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Confirmé", "Reporté", "Honoré", "Annulé"], id: \.self) { targetStatus in
                        if appt.status != targetStatus {
                            Button {
                                Task {
                                    await vm.changeAppointmentStatus(appointment: appt, newStatus: targetStatus)
                                }
                            } label: {
                                Text(targetStatus)
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(appointmentStatusColor(targetStatus).opacity(0.14)))
                                    .foregroundStyle(appointmentStatusColor(targetStatus))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .loobyTakerCard(padding: 14)
    }

    private func appointmentStatusColor(_ status: String) -> Color {
        switch status {
        case "Confirmé", "Honoré": return LoobyTakerPalette.emerald
        case "Reporté": return LoobyTakerPalette.amberPrimary
        case "Annulé": return LoobyTakerPalette.danger
        default: return LoobyTakerPalette.proCobalt
        }
    }

    // MARK: - 1B. Mode Pro : Bouton Rapide « Dire que nous sommes fermés »

    private var proExceptionClosureSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: isClosedOverrideDraft ? "door.left.hand.closed" : "checkmark.seal.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(isClosedOverrideDraft ? LoobyTakerPalette.danger : LoobyTakerPalette.emerald)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isClosedOverrideDraft ? "Boutique signalée FERMÉE" : "Boutique OUVERTE aux clients")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)
                        Text("Ce statut s'affiche immédiatement sur Livria Store, Livria Marketplace et Viple Delivery.")
                            .font(.system(size: 12))
                            .foregroundStyle(LoobyTakerPalette.inkSecondary)
                    }
                }

                Toggle(isOn: $isClosedOverrideDraft) {
                    Text("Dire que nous sommes fermés exceptionnellement")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .tint(LoobyTakerPalette.danger)

                TextField("Motif affiché aux clients (ex: Fermeture exceptionnelle jusqu'à 16h)", text: $closureReasonDraft)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LoobyTakerPalette.cardSubtle))

                Button {
                    Task {
                        isSavingHours = true
                        _ = await vm.saveRelayHoursAndClosure(
                            openingHoursSummary: openingSummaryDraft,
                            isCurrentlyClosedOverride: isClosedOverrideDraft,
                            closureReason: isClosedOverrideDraft ? closureReasonDraft : "",
                            weeklySchedule: scheduleDraft,
                            availabilities: availabilitiesDraft
                        )
                        isSavingHours = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSavingHours {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: isClosedOverrideDraft ? "hand.raised.fill" : "checkmark.circle.fill")
                        }
                        Text(isClosedOverrideDraft ? "Publier la fermeture immédiate" : "Confirmer l'ouverture de la boutique")
                            .font(.system(size: 14.5, weight: .black, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isClosedOverrideDraft ? LoobyTakerPalette.danger : LoobyTakerPalette.emerald)
                    )
                    .foregroundStyle(.white)
                }
                .disabled(isSavingHours)
            }
            .loobyTakerCard()
        }
    }

    // MARK: - 2. Créneaux de Disponibilités (Particulier) & Planning Hebdomadaire Lundi–Dimanche

    private var particulierAvailabilitySlotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mes créneaux de présence (Livreurs & Clients)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            Text("Indiquez quand vous êtes présent à domicile pour recevoir les livreurs Viple Delivery / UPS et accueillir les retraits clients.")
                .font(.system(size: 12.5))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)

            ForEach(availabilitiesDraft) { slot in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(slot.dayLabel)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)
                        Text("\(slot.startTime) – \(slot.endTime)")
                            .font(.system(size: 12.5, weight: .black, design: .monospaced))
                            .foregroundStyle(LoobyTakerPalette.amberDeep)
                        HStack(spacing: 8) {
                            if slot.acceptsDeliveries {
                                Label("Livreurs OK", systemImage: "truck.box.fill")
                            }
                            if slot.acceptsCustomerPickups {
                                Label("Retraits clients OK", systemImage: "person.fill.checkmark")
                            }
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LoobyTakerPalette.emerald)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        availabilitiesDraft.removeAll { $0.id == slot.id }
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(LoobyTakerPalette.danger)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 13).fill(LoobyTakerPalette.cardSubtle))
            }

            Divider()

            Text("Ajouter un créneau de disponibilité")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            TextField("Libellé (ex: Mercredi après-midi, Soirées Lun-Ven…)", text: $newSlotDayLabel)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.cardSubtle))

            HStack(spacing: 10) {
                TextField("Début (17:30)", text: $newSlotStart)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.cardSubtle))
                TextField("Fin (20:30)", text: $newSlotEnd)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.cardSubtle))
            }

            HStack(spacing: 14) {
                Toggle("Livreurs", isOn: $newSlotAcceptsDeliveries)
                    .font(.system(size: 12, weight: .bold))
                Toggle("Clients", isOn: $newSlotAcceptsPickups)
                    .font(.system(size: 12, weight: .bold))
            }

            Button {
                let added = TakerAvailabilitySlot(
                    dayLabel: newSlotDayLabel.isEmpty ? "Disponibilité" : newSlotDayLabel,
                    startTime: newSlotStart,
                    endTime: newSlotEnd,
                    acceptsDeliveries: newSlotAcceptsDeliveries,
                    acceptsCustomerPickups: newSlotAcceptsPickups
                )
                availabilitiesDraft.append(added)
                LoobyTakerHaptics.impact(0)
            } label: {
                Label("Ajouter ce créneau à ma liste", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.amberSoft))
                    .foregroundStyle(LoobyTakerPalette.amberDeep)
            }
            .buttonStyle(.plain)
        }
        .loobyTakerCard()
    }

    private var weeklyScheduleEditorSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(vm.isProMode ? "Horaires d'ouverture de la boutique (Lundi à Dimanche)" : "Planning hebdomadaire indicatif")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            VStack(alignment: .leading, spacing: 5) {
                Text("Résumé public affiché sur la carte des Points Relais")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                TextField("Ex : Lun–Sam 09h00–12h30 & 14h00–19h00", text: $openingSummaryDraft)
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
            }

            ForEach($scheduleDraft) { $day in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle(isOn: $day.isOpen) {
                            Text(day.dayName)
                                .font(.system(size: 14.5, weight: .black, design: .rounded))
                                .foregroundStyle(LoobyTakerPalette.ink)
                        }
                        .tint(LoobyTakerPalette.emerald)
                    }

                    if day.isOpen {
                        HStack(spacing: 8) {
                            Text("Matin")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                                .frame(width: 48, alignment: .leading)
                            TextField("09:00", text: $day.morningStart)
                                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                .padding(7)
                                .background(RoundedRectangle(cornerRadius: 8).fill(LoobyTakerPalette.cardSurface))
                            Text("→")
                                .foregroundStyle(LoobyTakerPalette.inkMuted)
                            TextField("12:30", text: $day.morningEnd)
                                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                .padding(7)
                                .background(RoundedRectangle(cornerRadius: 8).fill(LoobyTakerPalette.cardSurface))
                        }

                        Toggle("Coupure méridienne (après-midi distinct)", isOn: $day.hasAfternoonBreak)
                            .font(.system(size: 11.5, weight: .semibold))
                            .tint(LoobyTakerPalette.amberPrimary)

                        if day.hasAfternoonBreak {
                            HStack(spacing: 8) {
                                Text("Après-m.")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                                    .frame(width: 48, alignment: .leading)
                                TextField("14:00", text: $day.afternoonStart)
                                    .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                    .padding(7)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(LoobyTakerPalette.cardSurface))
                                Text("→")
                                    .foregroundStyle(LoobyTakerPalette.inkMuted)
                                TextField("19:00", text: $day.afternoonEnd)
                                    .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                    .padding(7)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(LoobyTakerPalette.cardSurface))
                            }
                        }
                    } else {
                        Text("Fermé toute la journée")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LoobyTakerPalette.inkMuted)
                    }
                }
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 13).fill(LoobyTakerPalette.cardSubtle))
            }

            Button {
                Task {
                    isSavingHours = true
                    _ = await vm.saveRelayHoursAndClosure(
                        openingHoursSummary: openingSummaryDraft,
                        isCurrentlyClosedOverride: isClosedOverrideDraft,
                        closureReason: closureReasonDraft,
                        weeklySchedule: scheduleDraft,
                        availabilities: availabilitiesDraft
                    )
                    isSavingHours = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isSavingHours {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text("Enregistrer mes horaires & disponibilités")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LoobyTakerPalette.goldCoralHorizontal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isSavingHours)
        }
        .loobyTakerCard()
    }

    // MARK: - 3. Mode Vacances / Congés Programmés (`POST /taker/relay/vacation`)

    private var vacationModeEditorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(LoobyTakerPalette.amberPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.isProMode ? "Congés & Fermeture programmée" : "Mode vacances Taker")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                    Text("Suspendez automatiquement les nouvelles expéditions vers votre relais pendant votre absence.")
                        .font(.system(size: 12))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
            }

            Toggle(isOn: $vacationEnabledDraft) {
                Text("Activer le mode vacances / congés")
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
            }
            .tint(LoobyTakerPalette.amberPrimary)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date de début")
                        .font(.system(size: 12, weight: .bold))
                    TextField("2026-12-20", text: $vacationStartDraft)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date de reprise")
                        .font(.system(size: 12, weight: .bold))
                    TextField("2027-01-04", text: $vacationEndDraft)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Message affiché aux clients")
                    .font(.system(size: 12, weight: .bold))
                TextField("Ex : En congés jusqu'au 4 janvier, merci et belles fêtes !", text: $vacationMessageDraft, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
            }

            Toggle(isOn: $allowExistingPickupsOnlyDraft) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Autoriser uniquement le retrait des colis déjà en stock")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("Bloque les nouvelles commandes vers votre relais tout en permettant de remettre vos derniers colis avant le départ.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
            }
            .tint(LoobyTakerPalette.emerald)

            Button {
                Task {
                    isSavingVacation = true
                    _ = await vm.saveVacationMode(
                        enabled: vacationEnabledDraft,
                        startDate: vacationStartDraft,
                        endDate: vacationEndDraft,
                        message: vacationMessageDraft,
                        allowExistingPickupsOnly: allowExistingPickupsOnlyDraft
                    )
                    isSavingVacation = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isSavingVacation {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "sun.max.fill")
                    }
                    Text("Enregistrer la configuration vacances")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LoobyTakerPalette.goldCoralHorizontal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isSavingVacation)
        }
        .loobyTakerCard()
    }

    private func syncDraftsFromActiveRelay() {
        guard let r = vm.activeRelay else { return }
        openingSummaryDraft = r.openingHoursSummary
        isClosedOverrideDraft = r.isCurrentlyClosedOverride
        closureReasonDraft = r.closureReason
        scheduleDraft = r.weeklySchedule.isEmpty ? TakerDaySchedule.defaultWeek(isPro: r.isPro) : r.weeklySchedule
        availabilitiesDraft = r.availabilities

        vacationEnabledDraft = r.vacationMode.enabled
        vacationStartDraft = r.vacationMode.startDate
        vacationEndDraft = r.vacationMode.endDate
        vacationMessageDraft = r.vacationMode.message
        allowExistingPickupsOnlyDraft = r.vacationMode.allowExistingPickupsOnly
    }
}

// MARK: - Feuille de Création / Modification d'un RDV Client (`POST /taker/appointments/save`)

public struct AppointmentComposerSheet: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    public let initialParcel: TakerParcel?

    @State private var selectedParcelId: String = ""
    @State private var vipleBarcode: String = ""
    @State private var customerName: String = ""
    @State private var customerPhone: String = ""
    @State private var customerEmail: String = ""
    @State private var slotDate: String = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }()
    @State private var startTime: String = "18:00"
    @State private var endTime: String = "18:30"
    @State private var status: String = "Confirmé"
    @State private var notes: String = ""
    @State private var isSubmitting: Bool = false

    public init(initialParcel: TakerParcel?) {
        self.initialParcel = initialParcel
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if !vm.inStockParcels.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sélectionner un colis en stock")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Picker("Colis", selection: $selectedParcelId) {
                                Text("Choisir un colis…").tag("")
                                ForEach(vm.inStockParcels) { p in
                                    Text("\(p.recipientName) (\(p.vipleBarcode))").tag(p.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedParcelId) { _, newId in
                                if let found = vm.parcels.first(where: { $0.id == newId }) {
                                    applyParcel(found)
                                }
                            }
                        }
                        .loobyTakerCard(padding: 13)
                    }

                    VStack(alignment: .leading, spacing: 11) {
                        Text("Code Viple Delivery (VD-…)")
                            .font(.system(size: 12, weight: .bold))
                        TextField("VD-2026-84920", text: $vipleBarcode)
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        Text("Nom du client")
                            .font(.system(size: 12, weight: .bold))
                        TextField("Nom complet", text: $customerName)
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        HStack(spacing: 10) {
                            TextField("Téléphone", text: $customerPhone)
                                .keyboardType(.phonePad)
                                .padding(11)
                                .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                            TextField("E-mail", text: $customerEmail)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding(11)
                                .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                        }

                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date du RDV")
                                    .font(.system(size: 12, weight: .bold))
                                TextField("2026-11-24", text: $slotDate)
                                    .padding(11)
                                    .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Début")
                                    .font(.system(size: 12, weight: .bold))
                                TextField("18:00", text: $startTime)
                                    .padding(11)
                                    .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fin")
                                    .font(.system(size: 12, weight: .bold))
                                TextField("18:30", text: $endTime)
                                    .padding(11)
                                    .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                            }
                        }

                        Picker("Statut initial", selection: $status) {
                            Text("Proposé").tag("Proposé")
                            Text("Confirmé").tag("Confirmé")
                        }
                        .pickerStyle(.segmented)

                        TextField("Consignes pour le client (interphone, code portail…)", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                    }
                    .loobyTakerCard()

                    Button {
                        Task {
                            isSubmitting = true
                            let ok = await vm.saveCustomerAppointment(
                                appointmentId: nil,
                                parcelId: selectedParcelId,
                                vipleBarcode: vipleBarcode,
                                customerName: customerName.isEmpty ? "Client Livria" : customerName,
                                customerPhone: customerPhone,
                                customerEmail: customerEmail,
                                slotDate: slotDate,
                                startTime: startTime,
                                endTime: endTime,
                                status: status,
                                notes: notes
                            )
                            isSubmitting = false
                            if ok {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text("Envoyer & enregistrer ce RDV client")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LoobyTakerPalette.goldCoralHorizontal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .disabled(isSubmitting)
                }
                .padding(18)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Donner un RDV client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
            .onAppear {
                if let p = initialParcel {
                    applyParcel(p)
                }
            }
        }
    }

    private func applyParcel(_ p: TakerParcel) {
        selectedParcelId = p.id
        vipleBarcode = p.vipleBarcode
        customerName = p.recipientName
        customerPhone = p.recipientPhone
        customerEmail = p.recipientEmail
    }
}
