//
//  ProfileView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 07.05.26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let user: User?
    let isRefreshing: Bool
    let refreshAction: () -> Void
    let logoutAction: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProfileHeader(user: user)

                    ProfileStatusCard(user: user, isRefreshing: isRefreshing, refreshAction: refreshAction)

                    ProfileDetailsCard(user: user)

                    Button(role: .destructive) {
                        logoutAction()
                        dismiss()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ProfileHeader: View {
    let user: User?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.06, green: 0.45, blue: 0.47).opacity(0.12))

                Text(initial)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(user?.name?.nilIfEmpty ?? "ClipForge user")
                    .font(.title3.weight(.bold))

                Text(user?.email ?? "No email available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var initial: String {
        let source = user?.email ?? user?.name ?? "C"
        return String(source.prefix(1)).uppercased()
    }
}

private struct ProfileStatusCard: View {
    let user: User?
    let isRefreshing: Bool
    let refreshAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Account status", systemImage: "person.badge.shield.checkmark")
                    .font(.headline.weight(.bold))

                Spacer()

                StatusBadge(title: statusTitle, tint: statusTint)
            }

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: refreshAction) {
                Label(isRefreshing ? "Refreshing" : "Refresh Status", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(isRefreshing)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var statusTitle: String {
        user?.isEmailVerified == false ? "Unverified" : "Verified"
    }

    private var statusTint: Color {
        user?.isEmailVerified == false ? .orange : .green
    }

    private var statusMessage: String {
        if user?.isEmailVerified == false {
            return "Verify your email before uploading and processing videos."
        }

        return "Uploads and processing are available for this account."
    }
}

private struct ProfileDetailsCard: View {
    let user: User?

    var body: some View {
        VStack(spacing: 0) {
            ProfileDetailRow(title: "Role", value: user?.role?.nilIfEmpty ?? "User")

            Divider()

            ProfileDetailRow(title: "User ID", value: user?.id ?? "Unavailable")

            if let createdAt = user?.createdAt {
                Divider()

                ProfileDetailRow(title: "Created", value: createdAt.shortDisplay)
            }
        }
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProfileDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    ProfileView(
        user: User(id: "user_123", email: "ivan@example.com", isEmailVerified: true, createdAt: Date()),
        isRefreshing: false,
        refreshAction: {},
        logoutAction: {}
    )
}
