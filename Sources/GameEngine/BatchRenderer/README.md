# BatchRenderer

Provides an interface in order to draw stuff. Automatically supports interpolation. 

```
  = Unstarted
o = WIP
/ = Happy path works
x = Done
```

TODO:
- [ ] Clip info for every draw command
- [ ] Creating textures out of other textures

- [ ] Image tiling. If it's too big we tile the image to fit into textures. 
- [ ] * Possibly streaming the image from disk as needed

- [ ] Choice of memory management
- [ ] Support resources with random lifetimes
```
draw("myImage.png", x, y)
```

- [ ] ImageBuilder not taking clipping into consideration
- [ ] Assuming the texture is destroyed for no reason (directx9): we need to be able to recreate it

Image Sources:
- [/] Disk (Url)
- [ ] * Can remotely download resource pack
- [o] Memory (PixlData)
- [ ] Remote URL
- [o] Composed Images
- [o] System Font (String?)

Image Types:
- [ ] Id
- [ ] Id+metadata
- [ ] PixelData

- [ ] Enforce maximum cache size 
- [ ] Drop unmanaged images no longer used when reaching maximum cache size

Animation:
- [ ] Pathing
- [ ] * Bezier curves
- [ ] Choose smoothing algo

Geometry:
- [ ] Rectanges
- [ ] Triangle List

Fonts:
- [ ] Query Font list
- [ ] Upload font (url; or data)

I dunno yet:
- [ ] Blending
- [ ] Bulk Text (Currently we just draw each individual letter)

