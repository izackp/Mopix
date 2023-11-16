//
//  File.swift
//  
//
//  Created by Isaac Paul on 11/15/23.
//

import Foundation

protocol DataSource {
    func fetch(_ url:URL) throws -> [UInt8]
    func searchByName(_ name:String) -> URL?
    func canHandle(_ url:URL) -> Bool
}

public class CombinedDataSource : DataSource {
    func searchByName(_ name: String) -> URL? {
        for eachSource in sources {
            let found = try eachSource.searchByName(name)
            if (found != nil) {
                return found
            }
        }
        return nil
    }
    
    //Can probably do something like the below and use maps in the future
    //func register(_ protocol:String, _ source:DataSource)
    var sources:[DataSource] = []
    
    func fetch(_ url: URL) throws -> [UInt8] {
        for eachSource in sources {
            if (eachSource.canHandle(url)) {
                return try eachSource.fetch(url)
            }
        }
        throw GenericError("Combined DataSource cannot handle: \(url)")
    }
    
    func canHandle(_ url:URL) -> Bool {
        return true
    }
}
