//
//  File.swift
//  
//
//  Created by Isaac Paul on 11/15/23.
//

import Foundation

public protocol IDataSource {
    func fetch(_ url:URL) throws -> [UInt8]
    func searchItemByName(_ name:String) -> URL?
    func canHandle(_ url:URL) -> Bool
}

public class CombinedDataSource : IDataSource {
    //Can probably do something like the below and use maps in the future
    //func register(_ protocol:String, _ source:DataSource)
    var sources:[IDataSource] = []
    
    public init(_ dataSources:[IDataSource]) {
        self.sources = dataSources
    }
    
    public func searchItemByName(_ name: String) -> URL? {
        for eachSource in sources {
            let found = eachSource.searchItemByName(name)
            if (found != nil) {
                return found
            }
        }
        return nil
    }
    
    public func fetch(_ url: URL) throws -> [UInt8] {
        for eachSource in sources {
            if (eachSource.canHandle(url)) {
                return try eachSource.fetch(url)
            }
        }
        throw GenericError("Combined DataSource cannot handle: \(url)")
    }
    
    public func canHandle(_ url:URL) -> Bool {
        return true
    }
}
