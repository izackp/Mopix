

### Todo Tasks
```
  = Unstarted
o = WIP
/ = Happy path works
x = Done

- [o] Virtual Drive
- - [/] Directory mounted drive - reading files
- - [ ] Directory mounted drive - writing files
- - [ ] File mounted drive - reading/writing files
- - [ ] File mounted drive - support compression: zstd, deflate
- - [ ] File change callbacks - For hot reloading assets
- [/] Atlas Generator / Dynamic Image Packer
- - [ ] Plugin style codecs; JPEGXL
- [ ] Loading and Drawing Fonts
- [ ] Sprite sheets / pregenerated atlas
- [o] Tweening library
- [ ] Audio
- - [ ] Wav and Ogg
- - [ ] Sound Effects API
- - [ ] Music Api
- - [ ] Some way sync sound with game actions (mario odyssey)
- - [ ] Plugin style codecs
- - [ ] Sequencer / Instruments (like pico-8)
- [o] UI
- - [ ] Views, Images, Shadows, Fonts, Layer Effects (clipping, masks, border, shadows), Tables, Zoom/Tiling for scrollview, video player
- - [ ] Images
- - [ ] TextView
- - [ ] Effects (clipping, masks, border, shadows)
- - [ ] Gestures, User interaction
- - [ ] ScrollView
- - [ ] Tables
- - [ ] Video player
- [o] Input API
- - [ ] Gamepad / Joystick Support
- - [ ] Keyboard Support
- - [o] Keymapping to virtual gamepad
- - [ ] Load keymapping from file
- - [ ] Support downloading/uploading mappings for devices
- [ ] Project Editor
- - [ ] Level Editor; Serializes with json5/binary
- - [ ] Drag and drop resources; Resources can be referenced in the level editor
- - [ ] Templates; Define and reuse stuff
- - [ ] Style sheet; Globaly? defined parameters (padding; text color; etc)
- - [ ] Basic Image editor (mspaint)
- - [ ] Basic sequencer
- [ ] Networking API
- - [ ] Serialize entire game state
- [ ] Auto Sync Engine class
- [ ] Move project to SPM; requires heavily modifing SDL to support -fmodules compile flag
```

I'm not sure how I want to design an ECS. I would always prefer to use an existing solution like flecs. Though I want to support hardcoded classes first. I also have previously designed a way for dynamic behavior via components + json. It removed the need of state machines because state was just the makeup of the components the entity had. 

### Design Goals
Why not Godot? I wanted something I could possibly port to the 3ds. I also wanted to make a deterministic engine for input only networking. Granted.. the 3ds might not be powerful enough to support 'rollback' but hopefully we will see.

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
* Swift : Got pissed at how difficult it was to compile on a mac. Did a lot of research on swift embedded/android as I will probably have to port swift to the 3ds. Decided to try nim since it compiles to c and can be very performant.
* Nim : Like it a lot, source code is understandable. However, I spent way too much learning macros because I wanted optionals, results, and early exits. Lack of _consistent_ support for indirection (interfaces, traits) made me look towards rust. Even the standard library uses different strategies for indirection. Look at file streams. Rust had all of the safety features I wanted (results and traits) that _everyone_ used.
* Rust : Looks sexy from the outside. Though, once you start working with it you realize that you realllyyyy need shared mutability in order to provide decent abstractions and decoupling. I feel like swift is the most productive language I've ever used so I moved back to that. Swift is also in the works for implementing a sort of borrow checker, and I feel performance will soon be up to par.
* Zig : I took a peak it at. Seems cool. Takes like 8 gbs of ram to compile .. I got scared away one I saw the code to manipulate strings. Though it seems like you can hide the mess by providing your own string class.

I also spent a chunk of time wrapping The-Forge api to nim. One of the reasons I decided on SDL was so I don't have to do that again lol. 

### Virtual Drive

Virtual drive allows you to combine directories into one virtual drive. This is to make modding much easier. Lets say a mod adds more maps your resource directory could look like:
C:/game/BaseGame.1.0.1/maps/01.dat
C:/game/BaseGame.1.0.1/maps/02.dat
C:/game/MyMod.0.0.1/maps/02.dat
C:/game/MyMod.0.0.1/maps/03.dat

mounting both will produce this virtual file system:
/maps/01.dat
/maps/02.dat (from MyMod)
/maps/03.dat

02.dat from BaseGame is still accessable via vd://BaseGame.1.0.1/02.dat

Example Usage:
```
    virtualDrive.writeStream("BaseGame","/save.dat", stream)
    virtualDrive.writeStream(<MountedDirInstance>,"/save.dat", stream)
    virtualDrive.writeStream("vd://basegame.1.1.0/packagesave.dat", stream)
    virtualDrive.writeStream("vd://basegame/packagesave.dat", stream)
    ^ same for read
    virtualDrive.listMountedDir()
    virtualDrive.filesWithName("02.dat")
    virtualDrive.filesInDirectory("BaseGame", "/maps/")
    virtualDrive.filesInDirectory(<MountedDir>,"/maps/")
    virtualDrive.filesInDirectory("/maps/")
    virtualDrive.directoriesInDirectory("/storage", "/maps/")
    virtualDrive.directoriesInDirectory(<MountedDir>,"/maps/")
    virtualDrive.directoriesInDirectory("/maps/")
```

Urls to virtual files are expected or returned in URI format:
vd://<package_name>.<version>/<path>
or
vd://<package_name>/<path>
or
vd:/<path>

