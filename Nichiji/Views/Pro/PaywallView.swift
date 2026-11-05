import SwiftUI

/*--------------------------------presenter-------------------------------*/

extension View {
    /// Presents the paywall while `feature` is set. Only a tapped Pro feature sets it.
    func paywallSheet(feature: Binding<ProFeature?>) -> some View {
        sheet(item: feature) { item in
            PaywallView(feature: item)
        }
    }
}

/*---------------------------------sheet----------------------------------*/

struct PaywallView: View {
    let feature: ProFeature

    @Environment(ProAccessModel.self) private var proAccess: ProAccessModel?
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    var body: some View {
        Group {
            if let proAccess {
                PaywallContent(model: PaywallModel(feature: feature, access: proAccess))
            } else {
                Text(PaywallCopy.unavailable)
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInkMuted)
                    .padding(LayoutTokens.screenMarginRegular)
            }
        }
        // A presented sheet does not follow the root's live scheme change, so it applies its own.
        .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.nichijiSurfaceRaised)
    }
}

/*--------------------------------content---------------------------------*/

private struct PaywallContent: View {
    @State private var model: PaywallModel
    @Environment(\.dismiss) private var dismiss

    init(model: PaywallModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: LayoutTokens.space24) {
                    intro
                    featureCard
                    Text(PaywallCopy.freeNote)
                        .font(.nichijiCallout)
                        .foregroundColor(.nichijiInkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, LayoutTokens.screenMarginRegular)
                .padding(.bottom, LayoutTokens.space24)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actions
        }
        .background(Color.nichijiSurfaceRaised.ignoresSafeArea())
        .task {
            if model.isUnlocked {
                dismiss()
            } else {
                await model.load()
            }
        }
        .onChange(of: model.isUnlocked) { _, isUnlocked in
            if isUnlocked { dismiss() }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(PaywallCopy.notNow) {
                dismiss()
            }
            .font(.uiText(size: 14, weight: .medium))
            .foregroundColor(.nichijiInk)
            .padding(.horizontal, LayoutTokens.space12)
            .minTouchTarget()
        }
        .padding(.trailing, LayoutTokens.space12)
        .padding(.top, LayoutTokens.space16)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: LayoutTokens.space8) {
            Text(PaywallCopy.title)
                .font(.nichijiTitle)
                .foregroundColor(.nichijiInk)
                .accessibilityAddTraits(.isHeader)
            Text(PaywallCopy.reason(for: model.feature))
                .font(.nichijiBody)
                .foregroundColor(.nichijiInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(PaywallCopy.oneTime)
                .font(.nichijiCallout)
                .foregroundColor(.nichijiInkMuted)
        }
    }

    private var featureCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(PaywallCopy.features(leading: model.feature).enumerated()), id: \.element) { index, item in
                if index > 0 {
                    Divider().overlay(Color.nichijiHairline)
                }
                PaywallFeatureRow(feature: item)
            }
        }
        .padding(.horizontal, LayoutTokens.space16)
        .cardBackground(cornerRadius: LayoutTokens.cornerRadiusMedium, fill: .nichijiSurface, stroke: .nichijiHairline)
    }

    private var actions: some View {
        VStack(spacing: LayoutTokens.space12) {
            if let message = model.message {
                Text(PaywallCopy.text(for: message))
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }

            PrimaryButton(title: model.primaryTitle, isEnabled: model.isPrimaryEnabled) {
                Task { await model.primaryTapped() }
            }

            Button(model.phase == .restoring ? PaywallCopy.restoring : PaywallCopy.restore) {
                Task { await model.restore() }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!model.isRestoreEnabled)

            Text(PaywallCopy.familySharing)
                .font(.nichijiCaption)
                .foregroundColor(.nichijiInkSubtle)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, LayoutTokens.screenMarginRegular)
        .padding(.top, LayoutTokens.space16)
        .padding(.bottom, LayoutTokens.space8)
        .background(Color.nichijiSurfaceRaised)
    }
}

/*----------------------------------row-----------------------------------*/

private struct PaywallFeatureRow: View {
    let feature: ProFeature

    var body: some View {
        HStack(alignment: .top, spacing: LayoutTokens.space12) {
            Image(systemName: PaywallCopy.symbol(for: feature))
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.nichijiVermilion)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(PaywallCopy.name(for: feature))
                    .font(.nichijiBody)
                    .foregroundColor(.nichijiInk)
                Text(PaywallCopy.detail(for: feature))
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, LayoutTokens.space12)
        .frame(minHeight: 60)
        .accessibilityElement(children: .combine)
    }
}
