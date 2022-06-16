//
//  AtlasAllocator.swift
//  TestGame
//
//  Created by Isaac Paul on 4/21/22.
//

import Foundation

fileprivate let SHELF_SPLIT_THRESHOLD: UInt16 = 8
fileprivate let ITEM_SPLIT_THRESHOLD: UInt16 = 8

public struct ShelfIndex : ExpressibleByIntegerLiteral, Equatable {
    public typealias IntegerLiteralType = UInt16
    var value: UInt16
    
    public static let NONE = ShelfIndex(integerLiteral: UInt16.max)

    public init(integerLiteral val: UInt16) {
      self.value = val
    }
    
    @inline(__always) public func index() -> Int { //Note: was usize == UInt, but swift arrays use Int
        return Int(value)
    }
    
    @inline(__always) public func is_some() -> Bool {
        return value != UInt16.max
    }
    
    @inline(__always) public func is_none() -> Bool {
        return value == UInt16.max
    }
}

public struct ItemIndex : ExpressibleByIntegerLiteral, Equatable {
    public typealias IntegerLiteralType = UInt16
    var value: UInt16
    
    public static let NONE = ItemIndex(integerLiteral: UInt16.max)

    public init(integerLiteral val: UInt16) {
      self.value = val
    }
    
    @inline(__always) public func index() -> Int { //Note: was usize == UInt, but swift arrays use Int
        return Int(value)
    }
    
    @inline(__always) public func is_some() -> Bool {
        return value != UInt16.max
    }
    
    @inline(__always) public func is_none() -> Bool {
        return value == UInt16.max
    }
}

public struct Shelf {
    var x: UInt16
    var y: UInt16
    var height: UInt16
    var prev: ShelfIndex
    var next: ShelfIndex
    var first_item: ItemIndex
    var is_empty: Bool
}

public struct Item {
    var x: UInt16
    var width: UInt16
    var prev: ItemIndex
    var next: ItemIndex
    var shelf: ShelfIndex
    var allocated: Bool
    var generation: UInt16
    
    func toTuple() -> (UInt16, UInt16, ItemIndex, ItemIndex, ShelfIndex, Bool, UInt16) {
        return (x, width, prev, next, shelf, allocated, generation)
    }
}

// Note: if allocating is slow we can use the guillotiere trick of storing multiple lists of free
// rects (per shelf height) instead of iterating the shelves and items.

/// A shelf-packing dynamic texture atlas allocator tracking each allocation individually and with support
/// for coalescing empty shelves.

public class AtlasAllocator : Sequence {

    var shelves: Arr<Shelf> = Arr<Shelf>()
    var items: Arr<Item> = Arr<Item>()
    let alignment: Size<Int32>
    let flip_xy: Bool
    let size: Size<Int32>
    var first_shelf: ShelfIndex = ShelfIndex(0)
    var free_items: ItemIndex = ItemIndex.NONE
    var free_shelves: ShelfIndex = ShelfIndex.NONE
    var shelf_width: UInt16
    var allocated_space: Int32 = 0
    
    internal init(alignment: Size<Int32>, flip_xy: Bool, size: Size<Int32>, first_shelf: ShelfIndex = ShelfIndex(0), free_items: ItemIndex = ItemIndex.NONE, free_shelves: ShelfIndex = ShelfIndex.NONE, shelf_width: UInt16, allocated_space: Int32 = 0) {
        self.alignment = alignment
        self.flip_xy = flip_xy
        self.size = size
        self.first_shelf = first_shelf
        self.free_items = free_items
        self.free_shelves = free_shelves
        self.shelf_width = shelf_width
        self.allocated_space = allocated_space
    }
    
    convenience init(size:Size<Int32>, options:AllocatorOptions = AllocatorOptions.new()) {
        let shelf_alignment:Int32
        let width:Int32
        let height:Int32
        
        if options.vertical_shelves {
            shelf_alignment = options.alignment.height
            width = size.height
            height = size.width
        } else {
            shelf_alignment = options.alignment.width
            width = size.width
            height = size.height
        }
        
        var shelf_width = width / options.num_columns
        shelf_width -= shelf_width % shelf_alignment

        self.init(
            alignment: options.alignment,
            flip_xy: options.vertical_shelves,
            size: Size<Int32>(width, height),
            shelf_width: UInt16(shelf_width)
        )
        someInit()
    }
    
    func clear() {
        someInit()
    }
    
    func someInit() {
        assert(self.size.width > 0)
        assert(self.size.height > 0)
        assert(self.size.width <= Int32(UInt16.max))
        assert(self.size.height <= Int32(UInt16.max))
        assert(
            self.size.width.multipliedReportingOverflow(by: self.size.height).1 == false,
            "The area of the atlas must fit in a Int32 value"
        )

        assert(self.alignment.width > 0)
        assert(self.alignment.height > 0)

        self.shelves.removeAll()
        self.items.removeAll()

        let num_columns = UInt16(self.size.width) / self.shelf_width

        var prev = ShelfIndex.NONE
        for i in 0..<num_columns {
            let first_item = ItemIndex(integerLiteral: UInt16(self.items.count))
            let x = i * self.shelf_width
            let current = ShelfIndex(integerLiteral: i)
            let next = (i + 1 < num_columns) ? ShelfIndex(integerLiteral: i + 1) : ShelfIndex.NONE

            self.shelves.append(Shelf(
                x: x,
                y: 0,
                height: UInt16(self.size.height),
                prev: prev,
                next: next,
                first_item: first_item,
                is_empty: true
            ))

            self.items.append(Item(
                x: x,
                width: self.shelf_width,
                prev: ItemIndex.NONE,
                next: ItemIndex.NONE,
                shelf: current,
                allocated: false,
                generation: 1
            ))

            prev = current
        }

        self.first_shelf = ShelfIndex(0)
        self.free_items = ItemIndex.NONE
        self.free_shelves = ShelfIndex.NONE
        self.allocated_space = 0
    }
    
    func getSize() -> Size<Int32> {
        return flip_xy ? Size(size.height, size.width) : size
    }
    
    /// Allocate a rectangle in the atlas.
    func allocate(size_: Size<Int32>) -> Allocation? {
        if size_ == Size<Int32>.zero
            || size_.width > Int32(UInt16.max)
            || size_.height > Int32(UInt16.max) {
            return nil
        }
        var size = size_ //TODO: Was the intention inout?

        adjust_size(alignment.width, &size.width)
        adjust_size(alignment.height, &size.height)

        var (width_, height_) = convert_coordinates(flip_xy, size.width, size.height)
        height_ = shelf_height(height_)

        if width_ > Int32(self.shelf_width) || height_ > self.size.height {
            return nil
        }

        var width = UInt16(width_)
        var height = UInt16(height_)

        var selected_shelf_height = UInt16.max
        var selected_shelf = ShelfIndex.NONE
        var selected_item = ItemIndex.NONE
        var shelf_idx = self.first_shelf
        while shelf_idx.is_some() {
            let shelf = self.shelves[shelf_idx.index()] //TODO: Possible copy?

            if shelf.height < height
                || shelf.height >= selected_shelf_height
                || (!shelf.is_empty && shelf.height > height + height / 2) {
                shelf_idx = shelf.next
                continue
            }

            var item_idx = shelf.first_item;
            while item_idx.is_some() {
                let item = self.items[item_idx.index()] //TODO: Possible copy?
                if !item.allocated && item.width >= width {
                    break
                }

                item_idx = item.next
            }

            if item_idx.is_some() {
                selected_shelf = shelf_idx;
                selected_shelf_height = shelf.height;
                selected_item = item_idx;

                if shelf.height == height {
                    // Perfect fit, stop searching.
                    break
                }
            }

            shelf_idx = shelf.next;
        }

        if selected_shelf.is_none() {
            return nil
        }

        let shelf = self.shelves[selected_shelf.index()] //Intended copy
        if shelf.is_empty {
            self.shelves[selected_shelf.index()].is_empty = false
        }

        if shelf.is_empty && shelf.height > height + SHELF_SPLIT_THRESHOLD {
            // Split the empty shelf into one of the desired size and a new
            // empty one with a single empty item.

            let new_shelf_idx = self.add_shelf(Shelf(
                x: shelf.x,
                y: shelf.y + height,
                height: shelf.height - height,
                prev: selected_shelf,
                next: shelf.next,
                first_item: ItemIndex.NONE,
                is_empty: true
            ))

            let new_item_idx = self.add_item(Item(
                x: shelf.x,
                width: self.shelf_width,
                prev: ItemIndex.NONE,
                next: ItemIndex.NONE,
                shelf: new_shelf_idx,
                allocated: false,
                generation: 1
            ))

            self.shelves[new_shelf_idx.index()].first_item = new_item_idx;

            let next = self.shelves[selected_shelf.index()].next;
            self.shelves[selected_shelf.index()].height = height;
            self.shelves[selected_shelf.index()].next = new_shelf_idx;

            if next.is_some() {
                self.shelves[next.index()].prev = new_shelf_idx;
            }
        } else {
            height = shelf.height
        }

        let item = self.items[selected_item.index()] // Intended copy

        if item.width - width > ITEM_SPLIT_THRESHOLD {

            let new_item_idx = self.add_item(Item (
                x: item.x + width,
                width: item.width - width,
                prev: selected_item,
                next: item.next,
                shelf: item.shelf,
                allocated: false,
                generation: 1
            ))

            self.items[selected_item.index()].width = width;
            self.items[selected_item.index()].next = new_item_idx;

            if item.next.is_some() {
                self.items[item.next.index()].prev = new_item_idx;
            }
        } else {
            width = item.width
        }

        self.items[selected_item.index()].allocated = true;
        let generation = self.items[selected_item.index()].generation;

        let x0 = item.x;
        let y0 = shelf.y;
        let x1 = x0 + width;
        let y1 = y0 + height;

        let (xx0, yy0) = convert_coordinates(self.flip_xy, Int32(x0), Int32(y0))
        let (xx1, yy1) = convert_coordinates(self.flip_xy, Int32(x1), Int32(y1))

        self.check()

        let rectangle = Frame<Int32> (
            min: Point(xx0, yy0),
            max: Point(xx1, yy1)
        )

        self.allocated_space += rectangle.size.area();

        return Allocation (
            id: AllocId(selected_item.value, generation),
            rectangle: rectangle
        )
    }
    
    /// Deallocate a rectangle in the atlas.
    public func deallocate(_ id: AllocId) {
        let item_idx = ItemIndex(integerLiteral: id.index());

        //let item = self.items[item_idx.index()].clone();
        //let Item { mut prev, mut next, mut width, allocated, shelf, generation, .. } = self.items[item_idx.index()];
        var (_, width, prev, next, shelf, allocated, generation) = self.items[item_idx.index()].toTuple()
        assert(allocated)
        assert(generation == id.generation(), "Invalid AllocId")

        self.items[item_idx.index()].allocated = false;
        self.allocated_space -= Int32(width) * Int32(self.shelves[shelf.index()].height)

        if next.is_some() && !self.items[next.index()].allocated {
            // Merge the next item into this one.

            let next_next = self.items[next.index()].next;
            let next_width = self.items[next.index()].width;

            self.items[item_idx.index()].next = next_next;
            self.items[item_idx.index()].width += next_width;
            width = self.items[item_idx.index()].width;

            if next_next.is_some() {
                self.items[next_next.index()].prev = item_idx;
            }

            // Add next to the free list.
            self.remove_item(next);

            next = next_next
        }

        if prev.is_some() && !self.items[prev.index()].allocated {
            // Merge the item into the previous one.

            self.items[prev.index()].next = next;
            self.items[prev.index()].width += width;

            if next.is_some() {
                self.items[next.index()].prev = prev;
            }

            // Add item_idx to the free list.
            self.remove_item(item_idx);

            prev = self.items[prev.index()].prev;
        }

        if prev.is_none() && next.is_none() {
            let shelf_idx = shelf;
            // The shelf is now empty.
            self.shelves[shelf_idx.index()].is_empty = true;

            // Only attempt to merge shelves on the same column.
            let x = self.shelves[shelf_idx.index()].x;

            let next_shelf = self.shelves[shelf_idx.index()].next;
            if next_shelf.is_some()
                && self.shelves[next_shelf.index()].is_empty
                && self.shelves[next_shelf.index()].x == x {
                // Merge the next shelf into this one.

                let next_next = self.shelves[next_shelf.index()].next;
                let next_height = self.shelves[next_shelf.index()].height;

                self.shelves[shelf_idx.index()].next = next_next;
                self.shelves[shelf_idx.index()].height += next_height;

                if next_next.is_some() {
                    self.shelves[next_next.index()].prev = shelf_idx;
                }

                // Add next to the free list.
                self.remove_shelf(next_shelf);
            }

            let prev_shelf = self.shelves[shelf_idx.index()].prev;
            if prev_shelf.is_some()
                && self.shelves[prev_shelf.index()].is_empty
                && self.shelves[prev_shelf.index()].x == x {
                // Merge the shelf into the previous one.

                let next_shelf = self.shelves[shelf_idx.index()].next;
                self.shelves[prev_shelf.index()].next = next_shelf;
                self.shelves[prev_shelf.index()].height += self.shelves[shelf_idx.index()].height;

                self.shelves[prev_shelf.index()].next = self.shelves[shelf_idx.index()].next;
                if next_shelf.is_some() {
                    self.shelves[next_shelf.index()].prev = prev_shelf;
                }

                // Add the shelf to the free list.
                self.remove_shelf(shelf_idx);
            }
        }

        self.check();
    }
    
    func adjust_size(_ alignment: Int32, _ size: inout Int32) {
        let rem = size % alignment
        if rem > 0 {
            size += alignment - rem
        }
    }
    
    func convert_coordinates(_ flip_xy: Bool, _ x: Int32, _ y: Int32) -> (Int32, Int32) {
        if flip_xy {
            return (y, x)
        }
        return (x, y)
    }

    func shelf_height(_ size: Int32) -> Int32 {
        let alignment:Int32
        switch size {
        case 0 ... 31 : alignment = 8
        case 32 ... 127 : alignment = 16
        case 128 ... 511 : alignment = 32
        default: alignment = 64
        }

        let rem = size % alignment;
        if rem > 0 {
            return size + alignment - rem;
        }

        return size
    }
            
     func add_item(_ item: Item) -> ItemIndex {
         if self.free_items.is_some() {
             let idx = self.free_items
             let lastGen = self.items[idx.index()].generation
             self.free_items = self.items[idx.index()].next
             self.items[idx.index()] = item
             self.items[idx.index()].generation = lastGen &+ 1

             return idx
         }

         let idx = ItemIndex(integerLiteral: UInt16(self.items.count))
         self.items.append(item)

         return idx
     }

    //TODO: Does inout here improve perf
    func add_shelf(_ shelf: Shelf) -> ShelfIndex {
        if self.free_shelves.is_some() {
            let idx = self.free_shelves
            self.free_shelves = self.shelves[idx.index()].next
            self.shelves[idx.index()] = shelf

            return idx
        }

        let idx = ShelfIndex(integerLiteral: UInt16(self.shelves.count))
        self.shelves.append(shelf);

        return idx
    }
    
    func remove_item(_ idx: ItemIndex) {
        self.items[idx.index()].next = self.free_items
        self.free_items = idx
    }

    func remove_shelf(_  idx: ShelfIndex) {
        // Remove the shelf's item.
        self.remove_item(self.shelves[idx.index()].first_item)

        self.shelves[idx.index()].next = self.free_shelves
        self.free_shelves = idx
    }
    
    func check() {
        var prev_empty = false
        var accum_h:UInt16 = 0
        var shelf_idx = self.first_shelf
        var shelf_x:UInt16 = 0
        while shelf_idx.is_some() {
            let shelf = self.shelves[shelf_idx.index()] //TODO: Unintended copy
            let new_column = shelf_x != shelf.x;
            if new_column {
                assert(Int32(accum_h) == self.size.height)
                accum_h = 0
            }
            shelf_x = shelf.x
            accum_h += shelf.height
            if prev_empty && !new_column {
                assert(!shelf.is_empty)
            }
            if shelf.is_empty {
                assert(!self.items[shelf.first_item.index()].allocated)
                assert(self.items[shelf.first_item.index()].next.is_none())
            }
            prev_empty = shelf.is_empty

            var accum_w:UInt16 = 0
            var prev_allocated = true
            var item_idx = shelf.first_item
            var prev_item_idx = ItemIndex.NONE
            while item_idx.is_some() {
                let item = self.items[item_idx.index()] //TODO: Unintended copy
                accum_w += item.width

                assert(item.prev == prev_item_idx)

                if !prev_allocated {
                    assert(item.allocated, "item \(item_idx.value) should be allocated");
                }
                prev_allocated = item.allocated

                prev_item_idx = item_idx
                item_idx = item.next
            }

            assert(accum_w == self.shelf_width)

            shelf_idx = shelf.next
        }
    }
    
    //All Below: Not Used besides for testing?
    
    public func is_empty() -> Bool {
        var shelf_idx = self.first_shelf

        while shelf_idx.is_some() {
            let shelf = self.shelves[shelf_idx.index()]
            if !shelf.is_empty {
                return false
            }

            shelf_idx = shelf.next
        }

        return true
    }
    
    /// How much space is available for future allocations.
    public func free_space() -> Int32 {
        return self.size.area() - self.allocated_space
    }
    
    public func makeIterator() -> AtlasIterator {
        return AtlasIterator(atlas: self, idx: 0)
    }
}

/*

impl AtlasAllocator {

    /// Turn a valid AllocId into an index that can be used as a key for external storage.
    ///
    /// The allocator internally stores all items in a single vector. In addition allocations
    /// stay at the same index in the vector until they are deallocated. As a result the index
    /// of an item can be used as a key for external storage using vectors. Note that:
    ///  - The provided ID must correspond to an item that is currently allocated in the atlas.
    ///  - After an item is deallocated, its index may be reused by a future allocation, so
    ///    the returned index should only be considered valid during the lifetime of the its
    ///    associated item.
    ///  - indices are expected to be "reasonable" with respect to the number of allocated items,
    ///    in other words it is never larger than the maximum number of allocated items in the
    ///    atlas (making it a good fit for indexing within a sparsely populated vector).
    pub func get_index(&self, id: AllocId) -> u32 {
        let index = id.index();
        debug_assert_eq!(self.items[index as usize].generation, id.generation());

        index as u32
    }

    /// Dump a visual representation of the atlas in SVG format.
    pub func dump_svg(&self, output: &mut dyn std::io::Write) -> std::io::Result<()> {
        use svg_fmt::*;

        writeln!(
            output,
            "{}",
            BeginSvg {
                w: self.size.width as f32,
                h: self.size.height as f32
            }
        )?;

        self.dump_into_svg(None, output)?;

        writeln!(output, "{}", EndSvg)
    }

    /// Dump a visual representation of the atlas in SVG, omitting the beginning and end of the
    /// SVG document, so that it can be included in a larger document.
    ///
    /// If a rectangle is provided, translate and scale the output to fit it.
    pub func dump_into_svg(&self, rect: Option<&Rectangle>, output: &mut dyn std::io::Write) -> std::io::Result<()> {
        use svg_fmt::*;

        let (sx, sy, tx, ty) = if let Some(rect) = rect {
            (
                rect.size().width as f32 / self.size.width as f32,
                rect.size().height as f32 / self.size.height as f32,
                rect.min.x as f32,
                rect.min.y as f32,
            )
        } else {
            (1.0, 1.0, 0.0, 0.0)
        };

        writeln!(
            output,
            r#"    {}"#,
            rectangle(tx, ty, self.size.width as f32 * sx, self.size.height as f32 * sy)
                .fill(rgb(40, 40, 40))
                .stroke(Stroke::Color(black(), 1.0))
        )?;

        var shelf_idx = self.first_shelf;
        while shelf_idx.is_some() {
            let shelf = &self.shelves[shelf_idx.index()];

            let y = shelf.y as f32 * sy;
            let h = shelf.height as f32 * sy;

            var item_idx = shelf.first_item;
            while item_idx.is_some() {
                let item = &self.items[item_idx.index()];

                let x = item.x as f32 * sx;
                let w = item.width as f32 * sx;

                let color = if item.allocated {
                    rgb(70, 70, 180)
                } else {
                    rgb(50, 50, 50)
                };

                let (x, y) = if self.flip_xy { (y, x) } else { (x, y) };
                let (w, h) = if self.flip_xy { (h, w) } else { (w, h) };

                writeln!(
                    output,
                    r#"    {}"#,
                    rectangle(x + tx, y + ty, w, h).fill(color).stroke(Stroke::Color(black(), 1.0))
                )?;

                item_idx = item.next;
            }

            shelf_idx = shelf.next;
        }

        Ok(())
    }

}
*/


public struct AtlasIterator: IteratorProtocol {
    
    private let atlas: AtlasAllocator
    private var idx: Int //usize
    
    public init(atlas: AtlasAllocator, idx: Int) {
        self.atlas = atlas
        self.idx = idx
    }

    mutating public func next() -> Allocation? {
        if self.idx >= self.atlas.items.count {
            return nil
        }

        while !self.atlas.items[self.idx].allocated {
            self.idx += 1;
            if self.idx >= self.atlas.items.count {
                return nil
            }
        }

        let item = self.atlas.items[self.idx]; //TODO: Unintended copy
        let shelf = self.atlas.shelves[item.shelf.index()];//TODO: Unintended copy

        let id = AllocId(UInt16(self.idx), item.generation)
        let alloc:Allocation
        if self.atlas.flip_xy {
            alloc = Allocation(
                id: id,
                rectangle: Frame<Int32>(
                    min: Point(
                        Int32(shelf.y),
                        Int32(item.x)
                    ),
                    max: Point(
                        Int32(shelf.y + shelf.height),
                        Int32(item.x + item.width)
                    )
                )
            )
        } else {
            alloc = Allocation(
                id: id,
                rectangle: Frame<Int32>(
                    min: Point(
                        Int32(item.x),
                        Int32(shelf.y)
                    ),
                    max: Point(
                        Int32(item.x + item.width),
                        Int32(shelf.y + shelf.height)
                    )
                )
            )
        }

        self.idx += 1

        return alloc
    }
}
