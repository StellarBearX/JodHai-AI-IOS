import SwiftUI

struct SettingsView: View {
    @Environment(LanguageManager.self) private var lang
    @AppStorage("notifications_enabled") private var notificationsEnabled = true

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.91, green: 0.97, blue: 0.86).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        languageCard
                        notificationsCard
                        aboutCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(lang.t("ตั้งค่า", "Settings"))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    // MARK: - Language Card
    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(lang.t("ภาษา", "Language"), systemImage: "globe")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.matchaGreen)

            HStack(spacing: 10) {
                ForEach(AppLanguage.allCases, id: \.self) { option in
                    let isSelected = lang.language == option
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            lang.language = option
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(option.flag)
                                .font(.system(size: 28))
                            Text(option.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isSelected ? Color.matchaGreen : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSelected ? Color.matchaGreen.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? Color.matchaGreen.opacity(0.4) : Color.black.opacity(0.06), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(lang.t("หมายเหตุ: Chat จะตอบเป็นภาษาไทยเสมอ", "Note: Chat always responds in Thai"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 20)
    }

    // MARK: - Notifications Card
    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(lang.t("การแจ้งเตือน", "Notifications"), systemImage: "bell.badge.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.matchaGreen)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(lang.t("แจ้งเตือนงบประมาณ", "Budget Alerts"))
                        .font(.subheadline.weight(.medium))
                    Text(lang.t("เมื่อใช้จ่ายถึง 80% หรือเกินงบ", "When spending reaches 80% or over budget"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .tint(Color.matchaGreen)
                    .labelsHidden()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 20)
    }

    // MARK: - About Card
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(lang.t("เกี่ยวกับ", "About"), systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.matchaGreen)

            HStack {
                Text(lang.t("เวอร์ชัน", "Version"))
                    .font(.subheadline)
                Spacer()
                Text(appVersion)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Divider().opacity(0.4)

            HStack {
                Text("Jod-Hai")
                    .font(.subheadline)
                Spacer()
                Text(lang.t("บันทึกรายรับ-รายจ่ายอัจฉริยะ", "Smart expense tracker"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 20)
    }
}
