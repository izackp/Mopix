//
//  ScrollView.swift
//  TestGame
//
//  Created by Isaac Paul on 1/18/23.
//

import Foundation
import SDL2

extension Point where T == Float {
    func distance() -> T {
        let dist = sqrtf(x * x + y * y)
        return dist
    }
    
    func directionAndMagnitude() -> (Point<T>, T) {
        let dist = distance()
        if (dist == 0) {
            return (self, 0)
        }
        let vector = Point(x / dist, y / dist)
        return (vector, dist)
    }
}

extension Point where T == Double {
    func distance() -> T {
        let dist = sqrt(x * x + y * y)
        return dist
    }
    
    func directionAndMagnitude() -> (Point<T>, T) {
        let dist = distance()
        if (dist == 0) {
            return (self, 0)
        }
        let vector = Point(x / dist, y / dist)
        return (vector, dist)
    }
}

extension Point where T:SignedInteger {
    
    //Distance_FlipCode
    func approx_distance_2() -> T {
        var approx:Int64 = 0
        var a:Int64 = Int64(x)
        var b:Int64 = Int64(y)
        
        if (a < 0) { a = -a }
        if (b < 0) { b = -b }

        if (a > b) {
            let c = a
            a = b
            b = c
        }

        approx = (b * 1007) + (a * 441) //TODO: Overflow on too small vector
        if (b < (a << 4)) {
            approx -= (b * 40)
        }
         
        return T((approx + 512) >> 10)
    }
    
    /*
    static int Distance_428(int a, int b) {
        if (a == 0 && b == 0)
            return 0; //Otherwise we get some crazy number
        ABSAndOrder(ref a, ref b);
        return (int)(b + 0.428 * a * a / b);
    }*/
    
    func approx_directionAndMagnitude() -> (Point<T>, T) {
        let dist = approx_distance_2()
        if (dist == 0) {
            return (self, 0)
        }
        let dist2 = dist
        let vector = Point(x<<8 / dist2, y<<8 / dist2)
        return (vector, dist2)
    }
    
    func distance() -> T {
        let dist = sqrt(Double(x * x + y * y))
        return T(dist)
    }
    
    func directionAndMagnitude() -> (Point<T>, T) {
        let dist = distance()
        if (dist == 0) {
            return (self, 0)
        }
        let vector = Point(x / dist, y / dist) //Notes: Loss of precision; doesn't move 'next frame'
        return (vector, dist)
    }
}

//TODO: Calculate frames lost per second
open class ScrollView : View {
    
    var offsetInter:Point<Int64> = Point.zero
    var offset:Point<Int64> = Point.zero //current
    var contentSize:Size<DValue> = Size.zero
    
    var destinationOffset:Point<Int64> = Point.zero
    
    var previousLocation:Point<DValue>? = nil
    var currentLocation:Point<DValue>? = nil
    
    let stretchMargin:DValue = 20
    let maxVel:Int64 = 1
    var isPressed = false
    var mouseOffset:Point<DValue>? = nil
    
    open override func onMousePress(_ event:MouseButtonEvent) {
        isPressed = true
        let point = Point(Int16(event.x), Int16(event.y))
        previousLocation = point
        currentLocation = point
        mouseOffset = point.offset(Int16(-destinationOffset.x), Int16(-destinationOffset.y))
    }
    
    open override func onMouseRelease(_ event:MouseButtonEvent) {
        if (!isPressed) { return }
        isPressed = false
        previousLocation = nil
        
        let insets = calcSnapbackInsets()
        var calcDest = destinationOffset
        if (insets.left > 0) {
            calcDest.x = 0
        } else if (insets.right > 0) {
            calcDest.x += insets.right
        }
        if (insets.top > 0) {
            calcDest.y = 0
        } else if (insets.bottom > 0) {
            calcDest.y += insets.bottom
        }
        destinationOffset = calcDest
        moveToDest()
    }
    
    func calcSnapbackInsets() -> Inset<Int64> {
        let snapWidth = contentSize.width < frame.width ? frame.width : contentSize.width
        let snapHeight = contentSize.height < frame.height ? frame.height : contentSize.height
        let insets = Inset(left: destinationOffset.x, top: destinationOffset.y, right: Int64(frame.width) - (Int64(snapWidth) + destinationOffset.x), bottom: Int64(frame.height) - (Int64(snapHeight) + destinationOffset.y))
        return insets
    }
    
    open override func onMouseMotion(event: SDL_MouseMotionEvent) {
        if (isPressed == false) { return }
        previousLocation = currentLocation
        let current = event.pos()
        currentLocation = current
        guard let previous = previousLocation else {
            //Log Error; unexpected value
            return
        }
        let diff = current - previous
        //print("diff: \(diff)")
        destinationOffset = destinationOffset + Point(Int64(diff.x), Int64(diff.y))
        //print("Destination: \(destinationOffset)")
        //destinationOffset = destinationOffset + Point(Float(diff.x), Float(diff.y))
        moveToDest()
    }
    
    func moveToDest() {
        let insets = calcSnapbackInsets()
        var calcDest = destinationOffset
        if (insets.left > 0) {
            calcDest.x -= (insets.left >> 1)
        } else if (insets.right > 0) {
            calcDest.x += (insets.right >> 1)
        }
        if (insets.top > 0) {
            calcDest.y -= (insets.top >> 1)
        } else if (insets.bottom > 0) {
            calcDest.y += (insets.bottom >> 1)
        }
        calcDest.x = calcDest.x << 8
        calcDest.y = calcDest.y << 8
        let totalOffset = calcDest - offsetInter
        if (totalOffset.x == 0 && totalOffset.y == 0) {
            return
        }
        //print("insets: \(insets)")
        let (vector, magnitude) = totalOffset.approx_directionAndMagnitude()
        
        if (magnitude > maxVel << 8) {
            let newDiff = Point((vector.x * maxVel), (vector.y * maxVel))
            offsetInter = offsetInter + newDiff
            offset = Point(offsetInter.x >> 8, offsetInter.y >> 8)
            scrollDidMove(Point(Int16(newDiff.x), Int16(newDiff.y)))
        } else {
            offsetInter = calcDest
            offset = Point(offsetInter.x >> 8, offsetInter.y >> 8)
            scrollDidMove(Point(Int16(totalOffset.x), Int16(totalOffset.y)))
        }
    }
    
    open func scrollDidMove(_ delta:Point<DValue>) {
        //print("scrollDidMove \(delta)")
    }
    
    open override func draw(_ context: UIRenderContext, _ rect: Rect<DValue>) throws {
        
        let offsetFrame = rect.offset(Point(Int16(offset.x), Int16(offset.y)))
        try super.draw(context, offsetFrame)
        
        let a = rect.offset(Point(Int16(destinationOffset.x), Int16(destinationOffset.y)))
        var offsetFrame2 = frame.offset(a.origin)
        if let mouseOffset = mouseOffset {
            offsetFrame2 = offsetFrame2.offset(mouseOffset)
        }
        offsetFrame2.width = 10
        offsetFrame2.height = 10
        try context.drawSquare(offsetFrame2, LabeledColor.red.sdlColor())
        //Hack:
        moveToDest()
    }
    
}
