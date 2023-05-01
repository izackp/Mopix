//
//  FileManager.swift
//  TestGame
//
//  Created by Isaac Paul on 5/3/22.
//

import Foundation

public extension FileManager {
    func documentDirectory() throws -> URL {
        guard let documentsURL = self.urls(for: .applicationDirectory, in: .userDomainMask).first else {
            throw GenericError("Could not retrieve document directory")
        }
        return documentsURL
    }
}
