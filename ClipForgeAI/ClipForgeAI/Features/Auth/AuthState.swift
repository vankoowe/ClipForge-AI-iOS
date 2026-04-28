//
//  AuthState.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

enum AuthState: Equatable {
    case checkingSession
    case loggedOut
    case loggedIn(User)

    var user: User? {
        guard case .loggedIn(let user) = self else {
            return nil
        }

        return user
    }
}
