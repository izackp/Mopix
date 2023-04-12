## Mopixs

2D Game engine in Swift. Temporary name. You may notice things done a certain way that is not good practice. I typically prioritize getting it running and then refactoring. Refactoring is much easier one you have something running with example use cases. 

Workspace repo is here: https://github.com/izackp/MopixWorkspace

### Todo Tasks
```
  = Unstarted
o = WIP
/ = Happy path works
x = Done

[ ] Seperate SwiftSDL into its own project
[o] Virtual Drive
- [/] Directory mounted drive - reading files
- [ ] Directory mounted drive - writing files
- [ ] File mounted drive - reading/writing files
- [ ] File mounted drive - support compression: zstd, deflate
- [ ] File change callbacks - For hot reloading assets
- [ ] Seperate into its own project / library
[/] Atlas Generator / Dynamic Image Packer
- [ ] Plugin style codecs; JPEGXL
[/] Loading and Drawing Fonts
- [/] Loading system fonts
- [ ] Drawing text spans; several formats of text on one line
[ ] Sprite sheets / pregenerated atlas
[o] Tweening library
[ ] Support windows / linux
- [ ] Move project to SPM; requires heavily modifing SDL to support -fmodules compile flag
[ ] Audio
- [ ] Wav and Ogg
- [ ] Sound Effects API
- [ ] Music Api
- [ ] Some way sync sound with game actions (mario odyssey)
- [ ] Plugin style codecs
- [ ] Sequencer / Instruments (like pico-8)
[o] UI
- [/] Views
- [ ] Images
- [o] TextView
    - [o] Type setting (text layout / word wrapping) - ENG
- [ ] Effects (clipping, masks, border, shadows)
- [ ] Gestures, User interaction
- [ ] ScrollView
- [ ] Tables
- [ ] Video player
- [o] Live reload editor
[o] Input API
- [ ] Gamepad / Joystick Support
- [ ] Keyboard Support
- [o] Keymapping to virtual gamepad
- [ ] Load keymapping from file
- [ ] Support downloading/uploading mappings for devices
[ ] Project Editor
- [ ] Level Editor; Serializes with json5/binary
- [ ] Drag and drop resources; Resources can be referenced in the level editor
- [ ] Templates; Define and reuse stuff
- [ ] Style sheet; Globaly? defined parameters (padding; text color; etc)
- [ ] Basic Image editor (mspaint)
- [ ] Basic sequencer
[ ] Networking API
- [ ] Serialize entire game state
[ ] Auto Sync Engine class
[ ] Performance metrics
[ ] Serialization. Codable is missing necessary features. We need something similar to https://github.com/antofic/GraphCodable
- [/] Decodable; Resolve Dynamic Type
- [/] Decodable; Resolve Ids
- [/] Encodable; Encode Dynamic Type
- [/] Encodable; Encode Ids
- [o] Serialization boiler plate code generation; Because writing out serialization code sucks.
- [ ] Serialize floats with a 'best match' number. Instead of just some random number.
[ ] Works entirely from SPM without xcode
- [ ] Leave SDL or port so it supports clang modules
```

I'm not sure how I want to design an ECS. I would always prefer to use an existing solution like flecs. Though I want to support hardcoded classes first. Flecs uses arch type entities because it makes sense to group components together by type. My question is why bother have pieces when you can just have a single class. You get the grouping automatically. Overall, I'm curious about a hybrid approach.

I also have previously designed a way for dynamic behavior via components + json. It removed the need of state machines because state was just the makeup of the components the entity had. 

### Requirements to build:
* Code sign libicuuc or disable library validation
* * security find-identity
* * codesign --remove-signature /path/to/theirlib.dylib
* * codesign -s "Apple Development: Your Name (10-char-ID)"  /path/to/theirlib.dylib
* * Possible Path: /opt/homebrew/Cellar/icu4c/70.1/lib/libicuuc.70.1.dylib
or
* * Project Settings > Signing & Capabilities > Hardened Runtime > Runtime Exceptions > Diable Library Validation

### Design Goals
Why not Godot? I wanted something I could possibly port to the 3ds. I also wanted to make a deterministic engine for input only networking. Granted.. the 3ds might not be powerful enough to support 'rollback' but we will see.

* Highly portable (built on SDL)
* Deterministic
* Supports multiple windows
* Code centric - Monogame style
* Easy to mod

Subgoals:
* Easy exporting and debugging (being deterministic should allow us to 'replay' most gameplay related bugs)
* Good UI
* 3D (Maybe integrate Kinc or Mach or The-Forge)

Notes:
I tried out these languages:
* Haxe : I tried it out on a mac. No debugger for hashlink :( Their 3d engine was buggy. No real argument except I just didn't get a good vibe from it.
* Swift : Got pissed at how difficult it was to compile the toolchain on a mac. Did a lot of research on swift embedded/android as I will probably have to port swift to the 3ds. Decided to try nim since it compiles to c and can be very performant.
* Nim : Like it a lot, source code is understandable. However, I spent way too much learning macros because I wanted optionals, results, and early exits. Lack of _consistent_ support for indirection (interfaces, traits) made me look towards rust. Even the standard library uses different strategies for indirection. Look at file streams. Rust had all of the safety features I wanted (results and traits) that _everyone_ used.
* Rust : Looks sexy from the outside. Though, once you start working with it you realize that you realllyyyy need shared mutability in order to provide decent abstractions and decoupling. I feel like swift is the most productive language I've ever used so I moved back to that. Swift is also in the works for implementing a sort of borrow checker, and I feel performance will soon be up to par.
* Zig : I took a peak it at. Seems cool. ~~Takes like 8 gbs of ram to compile~~ .. I got scared away once I saw the code to manipulate strings. Though it seems like you can hide the mess by providing your own string class. I have hope for this language. If I like it enough I might just port this over after I'm done.

I also spent a chunk of time wrapping The-Forge api to nim. One of the reasons I decided on SDL was so I don't have to do that again lol. 




--==-=--=-=-= Notes

SDL_RENDER_TARGETS_RESET = 0x2000, /**< The render targets have been reset and their contents need to be updated */
    SDL_RENDER_DEVICE_RESET, /**< The device has been reset and all textures need to be recreated */
Those events are sent when Direct3D loses your stuff
These are meant to be something that happens when some other app goes exclusive fullscreen and steals all the GPU resources, but this is not the first time I've heard about resizing the window causing it.
Which is atrocious, but if the GPU driver is doing it, it's beyond our control.
(But it might also just be an SDL bug, I won't rule it out.)


// Resizing windows freezes main loop:
The idea of using sdl is to avoid dealing with this stuff. For osx [super sendEvent:event]; on the window freezes up the main thread. Seems like something I can ignore for a while.
https://github.com/libsdl-org/SDL/issues/1059


I want to eventually target the web / wasm . This means we're going to have to drop foundation. We can replace somethings with the numerics library, but it should also be possible to just cherry pick what we need.


#### Animations, Tasks, And what not
* Simpliest solution is to avoid async await
 - Less worries about swift ports

Granted most Applications run based on tasks / threads
UI all happens on one thread while other common operations happen on different threads. This is a difficult problem and
best solved using async/await as it will be optimized and maintained by other people.


We can combine the solutions. Spin up a UI thread..


Ok what's neat about some animation systems is that you can 'move something' and it happens immediately. Move + scale + something and immediately it is in that position in memory. However, the screen in this system has a seperate representation. This representation will start and eventually animates into the desired values causing a seperation between the two.

This provides us with some benefits:
 - No need to wait for the animation to complete to begin the next one
 - Never have the UI layout be in an 'odd' position by operating on incomplete animations.
   - Pretty important. Lets say we insert a view between two others. This inserted view is animated from the bottom up. The layout could be mostly automatic.. however once we start animating we need to manually move everything affected.
 - Knowing the next few frames of an animation would help interpolation if any.
 
 but it sounds like a lot of work
