//
//  File.swift
//  
//
//  Created by Isaac Paul on 6/8/23.
//

import SDL2
import Foundation

//TODO: For logging events and exporting to a chrome://tracing compatible format
public class EventTimeline : Codable {
    enum EventType : String, Codable {
        case begin = "B"
        case end = "E"
        case instant = "i"
        case complete = "X"
        case mark = "R"
    }
    struct EventItem : Codable {
        let name:String
        let ph:EventType
        let ts:UInt64
        let tid:Int
        let pid:Int
        let dur:UInt64
        let cat:String
        
        static func simple(_ name:String, _ ph:EventType, _ mircoSecond:UInt64) -> EventItem{
            return EventItem(name: name, ph: ph, ts: mircoSecond, tid: 0, pid: 0, dur: 0, cat: "cat")
        }
    }
    
    var isOff = true
    
    var traceEvents:[EventItem] = []
    public var displayTimeUnit:String = "ms"
    
    public var start:UInt64 = SDL_GetPerformanceCounter()
    
    func addEventNow(_ name:String, _ ph:EventType) {
        if (isOff) { return }
        let time = SDL_GetPerformanceCounter() - start
        let microSeconds = time / (SDL_GetPerformanceFrequency() / 1000000)
        traceEvents.append(EventItem.simple(name, ph, microSeconds))

    }
    
    public func startEvent(_ name:String) {
        addEventNow(name, .begin)
    }
    
    public func endEvent(_ name:String) {
        addEventNow(name, .end)
    }
    
    public func instantEvent(_ name:String) {
        addEventNow(name, .instant)
    }
    
    public func measure(_ name:String, _ block:() throws ->()) rethrows {
        let newStart = SDL_GetPerformanceCounter() - start
        try block()
        
        if (isOff) { return }
        let duration = (SDL_GetPerformanceCounter() - start) - newStart
        let toMircoSeconds = (SDL_GetPerformanceFrequency() / 1000000)
        let microSeconds = newStart / toMircoSeconds
        let durMicroSeconds = duration / toMircoSeconds
        let ms = durMicroSeconds / 1000
        
        traceEvents.append(EventItem(name: name, ph: .complete, ts: microSeconds, tid: 0, pid: 0, dur: durMicroSeconds, cat: "cat"))
        if (ms > 17) {
            traceEvents.append(EventItem.simple("LONG", .mark, microSeconds+durMicroSeconds+1))
        }
    }
    
    func writeToFile(_ url:URL) throws {
        if (isOff) { return }
        let encoder = JSONEncoder()
        let content = try encoder.encode(self)
        print("writing to: \(url)")
        try content.write(to: url)
        print("writing complete")
    }
}
