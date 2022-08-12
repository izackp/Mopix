#  Serialization

Using property wrappers is an interesting solution: https://github.com/dejanskledar/SerializedSwift (calling this library SS below)
I'm not I want to force this on users... I kind wanted to solution to be internal but opt-in. There is certainly nice features with transformers and being able to pick your keys.. 

I could code an additional attribute and skip the code generation portion for now.. So the code generations portion is going to be needed in the future anyways. I want to eventually integrate into the the developers project and create tools for them. 

I also tried skipping code generation by overwriting decode for keyedcodingcontainer. This works but only if a dictionary is the root of the object. 

What we know:
* We are going to need to serialize levels and UI
* This serialization has to support inheritance and references; at least for UI because of LayoutElement
* Support a no frilz solution of codable.
* Consistance

lets say we're making a model.
We can generate the code..
Use the pregenerated code..
Write it manually..
Use SS

Because consistancy is a goal we're going to have to decide between generating the code and SS

Eventually
* we will have to make mappings because model names may or may not match
* we will need transforms because we may want to share code but the same models will be different between client/server

If we generate the code.. we have to store this information in the generated code to 'keep it alive' between changes, and it will require external tools to make changes (or manually change generated code which is gross)

Hence, our only solution is property wrappers (SS) for the future.  The question is do we need these features in the engine? No we don't need the features for the engine itself, but games will need it. 
If games need it then it will need to be part of the Editor.
If its part of the editor it will have an opt-in solution. If you want mapped keys: include SS.
Can we make the engine without it, so a game can decide against it?

Alternate solutions:
* Wrap dynamic objects in an enum;
```swift
    let wrapped = try container.decode([LECodableWrapper].self, forKey: .listLayouts)
    self.listLayouts = wrapped.map({$0.toLE()})
```

Honestly I perfer one big switch. I don't see any benefits on a developer level. 



##Expressible by String, Int, Float

These are only useful for decoding. I feel like supporting this with encoding would be troublesome with little benefit.
To support encoding:
* Make them also be IDs; Unless the instance has an id interface then force object serialization
* Modify instance cache to have a cache for each instance to avoid collisions.
* Update decoder and encoder to find and use expressible values as IDs


##Ugly float encoding

JSONEncoder seems to encode floats using large unrounded numbers. What's interesting is if we print a float value to console we get 5.2 but encoding into json we get 5.1999998092651367 . This is basically the same number.. but what we want is 5.2 because it's easier to read. I also noticed floats _change_ in xib builder constantly and by a significant amount. That's unacceptable for our implementation.

https://stackoverflow.com/questions/56785594/swift-encodes-double-0-1-to-json-as-0-10000000000000001
Seems like we can just change the type to decimal.. 

