//
//  SerializationTests.swift
//  UnitTests
//
//  Created by Isaac Paul on 8/2/22.
//

import XCTest

class ClassStr : Codable, ExpressibleByString {
    let value:String
    required init(_ value: String) throws {
        self.value = value
    }
}

class ClassInt : Codable, ExpressibleByInteger {
    let value:Int64
    required init(_ value: Int64) throws {
        self.value = value
    }
}

class ClassFloat: Codable, ExpressibleByFloat {
    let value:Float
    required init(_ value: Float) throws {
        self.value = value
    }
}

class ExpCombo: Codable, ExpressibleByFloat, ExpressibleByInteger, ExpressibleByString {
    let valueInt:Int64?
    let valueFloat:Float?
    let valueString:String?
    
    init() {
        valueInt = nil
        valueString = nil
        valueFloat = nil
    }
    
    required init(_ value: Int64) throws {
        valueInt = value
        valueString = nil
        valueFloat = nil
    }
    
    required init(_ value: String) throws {
        valueInt = nil
        valueString = value
        valueFloat = nil
    }
    
    required init(_ value: Float) throws {
        valueInt = nil
        valueString = nil
        valueFloat = value
    }
}

class ExpComboChild:ExpCombo {
    let dummyInfo:Int
    
    private enum CodingKeys: String, CodingKey {
        case dummyInfo
    }
    
    override init() {
        dummyInfo = 1
        super.init()
    }
    
    required init(_ value: Int64) throws {
        fatalError("init(_:) has not been implemented")
    }
    
    required init(_ value: String) throws {
        fatalError("init(_:) has not been implemented")
    }
    
    required init(_ value: Float) throws {
        fatalError("init(_:) has not been implemented")
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dummyInfo = try container.decode(Int.self, forKey: .dummyInfo)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dummyInfo, forKey: .dummyInfo)
        try super.encode(to: encoder)
    }
}

class SampleClass : Codable {
    let normalStr:String
    let normalInt:Int
    let testStr:ClassStr
    let testInt:ClassInt
    let testFloat:ClassFloat
    let testCombo1:ExpCombo //str
    let testCombo2:ExpCombo // int
    let testCombo3:ExpCombo //float
    let testCombo4:ExpCombo //obj
    let testCombo4Ref:ExpCombo //obj
    let testChildObj:ExpCombo //obj
    let testChildObjRef:ExpCombo //obj
    let testChildObjNoType:ExpComboChild //obj
    let listEx:[ExpCombo]
    /*
    enum CodingKeys: CodingKey {
        case normalStr
        case normalInt
        case testStr
        case testInt
        case testFloat
        case testCombo1
        case testCombo2
        case testCombo3
        case testCombo4
        case testCombo4Ref
        case testChildObj
        case testChildObjRef
        case testChildObjNoType
        case listEx
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        //let idk = try container.decode(ClassStr.self, forKey: .testStr)
        self.normalStr = try container.decode(String.self, forKey: .normalStr)
        self.normalInt = try container.decode(Int.self, forKey: .normalInt)
        self.testStr = try container.decodeDynamicItem(ClassStr.self, forKey: .testStr)
        self.testInt = try container.decodeDynamicItem(ClassInt.self, forKey: .testInt)
        self.testFloat = try container.decodeDynamicItem(ClassFloat.self, forKey: .testFloat)
        self.testCombo1 = try container.decodeDynamicItem(ExpCombo.self, forKey: .testCombo1)
        self.testCombo2 = try container.decodeDynamicItem(ExpCombo.self, forKey: .testCombo2)
        self.testCombo3 = try container.decodeDynamicItem(ExpCombo.self, forKey: .testCombo3)
        self.testCombo4 = try container.decodeDynamicItem(ExpCombo.self, forKey: .testCombo4)
        self.testCombo4Ref = try container.decodeDynamicItem(ExpCombo.self, forKey: .testCombo4Ref)
        self.testChildObj = try container.decodeDynamicItem(ExpCombo.self, forKey: .testChildObj)
        self.testChildObjRef = try container.decodeDynamicItem(ExpCombo.self, forKey: .testChildObjRef)
        self.testChildObjNoType = try container.decodeDynamicItem(ExpComboChild.self, forKey: .testChildObjNoType)
        self.listEx = try container.decodeArray(ExpCombo.self, forKey: .listEx)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.normalStr, forKey: .normalStr)
        try container.encode(self.normalInt, forKey: .normalInt)
        try container.encodeDynamicItem(self.testStr, forKey: .testStr)
        try container.encodeDynamicItem(self.testInt, forKey: .testInt)
        try container.encodeDynamicItem(self.testFloat, forKey: .testFloat)
        try container.encodeDynamicItem(self.testCombo1, forKey: .testCombo1)
        try container.encodeDynamicItem(self.testCombo2, forKey: .testCombo2)
        try container.encodeDynamicItem(self.testCombo3, forKey: .testCombo3)
        try container.encodeDynamicItem(self.testCombo4, forKey: .testCombo4)
        try container.encodeDynamicItem(self.testCombo4Ref, forKey: .testCombo4Ref)
        try container.encodeDynamicItem(self.testChildObj, forKey: .testChildObj)
        try container.encodeDynamicItem(self.testChildObjRef, forKey: .testChildObjRef)
        try container.encodeDynamicItem(self.testChildObjNoType, forKey: .testChildObjNoType)
        try container.encodeArray(self.listEx, forKey: .listEx)
    }*/
}

class SerializationTests: XCTestCase {
    
    static func customDecodeSwitch(_ type:String, _ decoder:Decoder) throws -> Any {
        switch (type) {
        case "ClassStr":
            return try ClassStr(from: decoder)
        case "ClassInt":
            return try ClassInt(from: decoder)
        case "ClassFloat":
            return try ClassFloat(from: decoder)
        case "ExpCombo":
            return try ExpCombo(from: decoder)
        case "ExpComboChild":
            return try ExpComboChild(from: decoder)
        default:
            throw GenericError("Unknown Type: \(type)")
        }
    }

    func testExample() throws {
        CodableTypeResolver.resolve = { try SerializationTests.customDecodeSwitch($0, $1) }
        let sampleJson = """
{
    "normalStr": "I'm Normal",
    "normalInt": 42,
    "testStr": "Hello",
    "testInt": 2,
    "testFloat": 3.2,
    "testCombo1": "Combo1",
    "testCombo2": 4,
    "testCombo3": 5.2,
    "testCombo4": {
        "_id": "idTesting",
        "valueInt": 6
    },
    "testCombo4Ref": { "_id": "idTesting" },
    "testChildObj": {
        "_id": "idChild1",
        "_type": "ExpComboChild",
        "valueInt": 7,
        "dummyInfo": 8
    },
    "testChildObjRef": { "_id": "idChild1" },
    "testChildObjNoType": {
        "valueInt": 9,
        "dummyInfo": 10
    },
    "listEx": [
        "ComboA",
        20,
        24.2,
        {
            "_id": "idListItemB",
            "valueInt": 64
        },
        { "_id": "idTesting" } ,
        { "_id": "idChild1" } ,
        {
            "_type": "ExpComboChild",
            "valueInt": 70,
            "dummyInfo": 80
        }
    ]
}
"""
        let data = sampleJson.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] = InstanceCache()
        let content:SampleClass
        do {
            content = try decoder.decode(SampleClass.self, from: data)
            print(content.testStr)
            XCTAssert(content.testCombo3.valueFloat == 5.2)
        }
        catch {
            print ("Error converting json: \(error)\n\n\(error.localizedDescription)")
            XCTAssert(false)
            return
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] = InstanceCache()
        let encodedData:Data
        do {
            encodedData = try encoder.encode(content)
            print(String(data: encodedData, encoding: .utf8)!)
        } catch {
            XCTAssert(false)
            return
        }
        decoder.userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] = InstanceCache()
        do {
            let content2 = try decoder.decode(SampleClass.self, from: encodedData)
            print(content2.testStr)
            XCTAssert(content.testCombo3.valueFloat == 5.2)
        }
        catch {
            print ("Error converting json: \(error)\n\n\(error.localizedDescription)")
            XCTAssert(false)
            return
        }
    }
    
    func testArrayBase() {
        CodableTypeResolver.resolve = { try SerializationTests.customDecodeSwitch($0, $1) }
        let json = """
[
    "ComboA",
    20,
    24.2,
    {
        "_id": "idListItemB",
        "valueInt": 64
    },
    { "_id": "idTesting" } ,
    { "_id": "idChild1" } ,
    {
        "_type": "ExpComboChild",
        "valueInt": 70,
        "dummyInfo": 80
    }
]
"""
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey(rawValue: "instanceCache")!] = InstanceCache()
        do {
            let content = try decoder.decode(Resolver<ExpCombo>.self, from: data)
            print(content.result.first!.valueString!)
        }
        catch {
            print ("Error converting json: \(error)\n\n\(error.localizedDescription)")
            XCTAssert(false)
        }
    }

}
