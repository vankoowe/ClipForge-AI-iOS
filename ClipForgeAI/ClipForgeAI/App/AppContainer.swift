//
//  AppContainer.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Combine
import Foundation

@MainActor
final class AppContainer: ObservableObject {
    private let tokenStore: KeychainTokenStore
    private let configuration: APIConfiguration

    private lazy var apiClient: any APIClientProtocol = APIClient(
        configuration: configuration,
        authStore: tokenStore
    )

    private lazy var uploadClient: any UploadClientProtocol = UploadClient(
        urlSession: .shared
    )

    lazy var authService: any AuthServiceProtocol = AuthService(
        apiClient: apiClient,
        tokenStore: tokenStore
    )

    lazy var passwordResetService: any PasswordResetServiceProtocol = PasswordResetService(
        apiClient: apiClient
    )

    lazy var videoService: any VideoServiceProtocol = VideoService(
        apiClient: apiClient
    )

    lazy var uploadService: any UploadServiceProtocol = UploadService(
        apiClient: apiClient,
        uploadClient: uploadClient
    )

    lazy var jobService: any JobServiceProtocol = JobService(
        apiClient: apiClient
    )

    lazy var clipService: any ClipServiceProtocol = ClipService(
        apiClient: apiClient
    )

    lazy var authViewModel = AuthViewModel(authService: authService)

    convenience init() {
        self.init(configuration: .current, tokenStore: KeychainTokenStore())
    }

    init(configuration: APIConfiguration, tokenStore: KeychainTokenStore) {
        self.configuration = configuration
        self.tokenStore = tokenStore
    }
}
