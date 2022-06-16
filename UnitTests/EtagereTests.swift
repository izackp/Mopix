//
//  EtagereTests.swift
//  TestGame
//
//  Created by Isaac Paul on 4/21/22.
//

import XCTest

class EtagereTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_simple() throws {
        let atlas = AtlasAllocator(
            size: Size(2048, 2048),
            options: AllocatorOptions (
                alignment: Size(4, 8),
                vertical_shelves: false,
                num_columns: 2
            )
        )

        XCTAssert(atlas.is_empty())
        XCTAssert(atlas.allocated_space == 0)

        let a1 = atlas.allocate(size_: Size<Int32>(20, 30))!
        let a2 = atlas.allocate(size_: Size<Int32>(30, 40))!
        let a3 = atlas.allocate(size_: Size<Int32>(20, 30))!

        XCTAssert(a1.id != a2.id)
        XCTAssert(a1.id != a3.id)
        XCTAssert(!atlas.is_empty())

        atlas.deallocate(a1.id)
        atlas.deallocate(a2.id)
        atlas.deallocate(a3.id)

        XCTAssert(atlas.is_empty())
        XCTAssert(atlas.allocated_space == 0)
    }
    
    func test_options() {
        let alignment = Size<Int32>(8, 16)

        let atlas = AtlasAllocator(
            size: Size(2000, 1000),
            options: AllocatorOptions (
                alignment: alignment,
                vertical_shelves: true,
                num_columns: 1
            )
        )
        XCTAssert(atlas.is_empty())
        XCTAssert(atlas.allocated_space == 0)

        let a1 = atlas.allocate(size_: Size<Int32>(20, 30))!
        let a2 = atlas.allocate(size_: Size<Int32>(30, 40))!
        let a3 = atlas.allocate(size_: Size<Int32>(20, 30))!

        XCTAssert(a1.id != a2.id)
        XCTAssert(a1.id != a3.id)
        XCTAssert(!atlas.is_empty())

        for id in atlas {
            XCTAssert(id.id == a1.id || id.id == a2.id || id.id == a3.id)
        }

        XCTAssert(a1.rectangle.x % alignment.width == 0)
        XCTAssert(a1.rectangle.y % alignment.height == 0)
        XCTAssert(a2.rectangle.x % alignment.width == 0)
        XCTAssert(a2.rectangle.y % alignment.height == 0)
        XCTAssert(a3.rectangle.x % alignment.width == 0)
        XCTAssert(a3.rectangle.y % alignment.height == 0)

        XCTAssert(a1.rectangle.width >= 20)
        XCTAssert(a1.rectangle.height >= 30)
        XCTAssert(a2.rectangle.width >= 30)
        XCTAssert(a2.rectangle.height >= 40)
        XCTAssert(a3.rectangle.width >= 20)
        XCTAssert(a3.rectangle.height >= 30)


        //atlas.dump_svg(&mut std::fs::File::create("tmp.svg").expect("!!"))!

        atlas.deallocate(a1.id)
        atlas.deallocate(a2.id)
        atlas.deallocate(a3.id)

        XCTAssert(atlas.is_empty())
        XCTAssert(atlas.allocated_space == 0)
    }
    
    func test_vertical() {
        let atlas = AtlasAllocator(size: Size(128, 256), options: AllocatorOptions (
            alignment: Size.one,
            vertical_shelves: true,
            num_columns: 2
        ))

        XCTAssert(atlas.getSize() == Size<Int32>(128, 256))

        let a = atlas.allocate(size_: Size<Int32>(32, 16))!
        let b = atlas.allocate(size_: Size<Int32>(16, 32))!

        XCTAssert(a.rectangle.width >= 32)
        XCTAssert(a.rectangle.height >= 16)

        XCTAssert(b.rectangle.width >= 16)
        XCTAssert(b.rectangle.height >= 32)

        let c = atlas.allocate(size_: Size<Int32>(128, 128))!

        for _ in atlas {}

        atlas.deallocate(a.id)
        atlas.deallocate(b.id)
        atlas.deallocate(c.id)

        for _ in atlas {}

        XCTAssert(atlas.is_empty())
        XCTAssert(atlas.allocated_space == 0)
    }
    
    func test_clear() {
        let atlas = AtlasAllocator(size: Size<Int32>(2048, 2048))

        // Run a workload a few hundred times to make sure clearing properly resets everything.
        for _ in 0..<500 {
            atlas.clear()
            XCTAssert(atlas.allocated_space == 0)

            let _ = atlas.allocate(size_: Size<Int32>(8, 2))!
            let _ = atlas.allocate(size_: Size<Int32>(2, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(16, 512))!
            let _ = atlas.allocate(size_: Size<Int32>(34, 34))!
            let _ = atlas.allocate(size_: Size<Int32>(34, 34))!
            let _ = atlas.allocate(size_: Size<Int32>(34, 34))!
            let _ = atlas.allocate(size_: Size<Int32>(34, 34))!
            let _ = atlas.allocate(size_: Size<Int32>(2, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(2, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 2))!
            let _ = atlas.allocate(size_: Size<Int32>(2, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 2))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(82, 80))!
            let _ = atlas.allocate(size_: Size<Int32>(56, 56))!
            let _ = atlas.allocate(size_: Size<Int32>(64, 66))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(40, 40))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(256, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(256, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(256, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(256, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(256, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(256, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(256, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(155, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(256, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(24, 24))!
            let _ = atlas.allocate(size_: Size<Int32>(64, 64))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(84, 84))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 2))!
            let _ = atlas.allocate(size_: Size<Int32>(34, 34))!
            let _ = atlas.allocate(size_: Size<Int32>(34, 34))!
            let _ = atlas.allocate(size_: Size<Int32>(192, 192))!
            let _ = atlas.allocate(size_: Size<Int32>(192, 192))!
            let _ = atlas.allocate(size_: Size<Int32>(52, 52))!
            let _ = atlas.allocate(size_: Size<Int32>(144, 144))!
            let _ = atlas.allocate(size_: Size<Int32>(192, 192))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(144, 144))!
            let _ = atlas.allocate(size_: Size<Int32>(24, 24))!
            let _ = atlas.allocate(size_: Size<Int32>(192, 192))!
            let _ = atlas.allocate(size_: Size<Int32>(192, 192))!
            let _ = atlas.allocate(size_: Size<Int32>(432, 243))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 2))!
            let _ = atlas.allocate(size_: Size<Int32>(2, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(9, 9))!
            let _ = atlas.allocate(size_: Size<Int32>(14, 14))!
            let _ = atlas.allocate(size_: Size<Int32>(14, 14))!
            let _ = atlas.allocate(size_: Size<Int32>(14, 14))!
            let _ = atlas.allocate(size_: Size<Int32>(14, 14))!
            let _ = atlas.allocate(size_: Size<Int32>(8, 8))!
            let _ = atlas.allocate(size_: Size<Int32>(27, 27))!
            let _ = atlas.allocate(size_: Size<Int32>(27, 27))!
            let _ = atlas.allocate(size_: Size<Int32>(27, 27))!
            let _ = atlas.allocate(size_: Size<Int32>(27, 27))!
            let _ = atlas.allocate(size_: Size<Int32>(11, 12))!
            let _ = atlas.allocate(size_: Size<Int32>(29, 28))!
            let _ = atlas.allocate(size_: Size<Int32>(32, 32))!

            for _ in atlas {}
        }
    }
    
    
    func test_fuzz_01() {
        var s:Int32 = 65472

        var atlas = AtlasAllocator(size: Size<Int32>(s, 64))
        var alloc = atlas.allocate(size_: Size<Int32>(s, 64))!
        XCTAssert(alloc.rectangle.width == s)
        XCTAssert(alloc.rectangle.height == 64)

        atlas = AtlasAllocator(size: Size<Int32>(64, s))
        alloc = atlas.allocate(size_: Size<Int32>(64, s))!
        XCTAssert(alloc.rectangle.width == 64)
        XCTAssert(alloc.rectangle.height == s)

        atlas = AtlasAllocator(size: Size<Int32>(s, 64))
        alloc = atlas.allocate(size_: Size<Int32>(s - 1, 64))!
        XCTAssert(alloc.rectangle.width == s)
        XCTAssert(alloc.rectangle.height == 64)

        atlas = AtlasAllocator(size: Size<Int32>(64, s))
        alloc = atlas.allocate(size_: Size<Int32>(64, s - 1))!
        XCTAssert(alloc.rectangle.width == 64)
        XCTAssert(alloc.rectangle.height == s)

        // Because of potential alignment we won't necessarily
        // succeed at allocation something this big
        s = Int32(UInt16.max)

        atlas = AtlasAllocator(size: Size<Int32>(s, 64))
        if let alloc = atlas.allocate(size_: Size<Int32>(s, 64)) {
            XCTAssert(alloc.rectangle.width == s)
            XCTAssert(alloc.rectangle.height == 64)
        }

        atlas = AtlasAllocator(size: Size<Int32>(64, s))
        if let alloc = atlas.allocate(size_: Size<Int32>(64, s)) {
            XCTAssert(alloc.rectangle.width == 64)
            XCTAssert(alloc.rectangle.height == s)
        }
    }
    
    func test_fuzz_02() {
        let atlas = AtlasAllocator(size: Size<Int32>(1000, 1000))

        XCTAssert(atlas.allocate(size_: Size<Int32>(255, 65599)) == nil)
    }
    
    func test_fuzz_03() {
        let atlas = AtlasAllocator(size: Size<Int32>(1000, 1000))

        let sizes = [
            Size<Int32>(999, 128),
            Size<Int32>(168492810, 10),
            Size<Int32>(45, 96),
            //Size<Int32>(-16711926, 0), not sure how you'd have a negative...
        ]

        var allocations:[Allocation] = []
        var allocated_space:Int32 = 0

        for size in sizes {
            if let alloc = atlas.allocate(size_: size) {
                allocations.append(alloc)
                allocated_space += alloc.rectangle.size.area()
                XCTAssert(allocated_space == atlas.allocated_space)
            }
        }

        for alloc in allocations {
            atlas.deallocate(alloc.id)

            allocated_space -= alloc.rectangle.size.area()
            XCTAssert(allocated_space == atlas.allocated_space)
        }

        XCTAssert(atlas.allocated_space == 0)
    }
    
    func test_fuzz_04() {
        let atlas = AtlasAllocator(size: Size<Int32>(1000, 1000))

        XCTAssert(atlas.allocate(size_: Size<Int32>(2560, 2147483647)) == nil)
    }


}

