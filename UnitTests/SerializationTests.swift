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
}

class SampleClass : Codable {
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
        KeyedDecodingContainerUtil.customDecoder = { try SerializationTests.customDecodeSwitch($0, $1) }
        let sampleJson = """
{
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
        do {
            let content = try decoder.decode(SampleClass.self, from: data)
            print(content.testStr)
        }
        catch {
            print ("Error converting json: \(error)\n\n\(error.localizedDescription)")
        }
        //XCTAssert(myVersion2.getMajor() == 1)
    }

}
