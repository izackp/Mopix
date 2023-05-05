## Mopixs

2D Game engine in Swift. Temporary name. You may notice things done a certain way that is not good practice. I typically prioritize getting it running and then refactoring. Refactoring is much easier one you have something running with example use cases. 

### Running on Windows

1. Follow the instructions here to install swift: https://github.com/pwsacademy/swift-setup/tree/main/platforms/windows

2. Follow the instructions here to setup vscode: https://github.com/pwsacademy/swift-setup/tree/main/editors/vscode-windows

    * Optional: Create a test hello world project to make sure and hit a breakpoint to make sure everything is working

3. Run `.\downloadBinaries.ps1` **Or:** 
    * Download SDL2 manually.
    * Copy SDL2.dll, SDL2_ttf.dll, etc files into this folder
    * Copy the appropiate files into `windows_bin\include` and `windows_bin\lib\x64`

4. Run `.\fix_vscode_settings.ps1`
    * SourceKit needs to be pointed to the SDL directories for intellisense.

5. Open the project folder in vscode and hitting the Run and debug button should work fine.

If you wish to run manually without vscode then run:

```bash
swift build --product "ParticleTweenTest" -c debug -Xswiftc -Iwindows_bin\\include -Xlinker -Lwindows_bin\\lib\\x64
.\.build\debug\ParticleTweenTest.exe
```

We're using `swift build` because `swift run` can't find the SDL directories for some reason.

Note: enums on windows from c libraries are backed by an Int32 rather than a UInt32 which is why I needed to fork and modify some dependencies

### Todo Tasks
```
  = Unstarted
o = WIP
/ = Happy path works
x = Done

[o] Seperate SwiftSDL into its own project
[o] Virtual Drive
- [/] Directory mounted drive - reading files
- [ ] Directory mounted drive - writing files
- [ ] File mounted drive - reading/writing files
- [ ] File mounted drive - support compression: zstd, deflate
- [o] File change callbacks - For hot reloading assets
- [ ] Seperate into its own project / library
[/] Atlas Generator / Dynamic Image Packer
- [ ] Resource reloading when textures 'go bad' (directx issue)
- [ ] Plugin style codecs; JPEGXL
[/] Loading and Drawing Fonts
- [/] Loading system fonts
- [ ] Loading system fonts (Windows)
- [ ] Drawing text spans; several formats of text on one line
[ ] Sprite sheets / pregenerated atlas
[/] Tweening library
 - Odd 6x performance slow down when main project is an spm project
 - Need to replace handles with pointers if possible.
[o] Support windows / linux
- [ ] Move project to SPM; ~~requires heavily modifing SDL to support -fmodules compile flag~~ 
- [o] Add build and vscode integration instructions. Possible include binaries to reduce friction.
[ ] Audio
- [ ] Wav and Ogg
- [ ] Sound Effects API
- [ ] Music Api
- [ ] Some way sync sound with game actions (mario odyssey)
- [ ] Plugin style codecs
- [ ] Sequencer / Instruments (like pico-8)
[o] UI
- [/] Views
- [o] Images
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
[/] Works entirely from SPM without xcode
- [ ] Leave SDL or port so it supports clang modules
```

I'm not sure how I want to design an ECS. I would always prefer to use an existing solution like flecs. Though I want to support hardcoded classes first. Flecs uses arch type entities because it makes sense to group components together by type. My question is why bother have pieces when you can just have a single class. You get the grouping automatically. Overall, I'm curious about a hybrid approach.

What will be interesting is trying to serialize the entire game world in a timely manner to support rollback.

### Requirements to build:
* Code sign libicuuc or disable library validation
* * security find-identity
* * codesign --remove-signature /path/to/theirlib.dylib
* * codesign -s "Apple Development: Your Name (10-char-ID)"  /path/to/theirlib.dylib
* * Possible Path: /opt/homebrew/Cellar/icu4c/70.1/lib/libicuuc.70.1.dylib
or
* * Project Settings > Signing & Capabilities > Hardened Runtime > Runtime Exceptions > Disable Library Validation

### Design Goals
I also wanted to make a deterministic engine for input only networking. Granted.. the swift might not be powerful enough to support 'rollback' but we will see.

* Highly portable (built on SDL)
* Deterministic
* Supports multiple windows
* Code centric - Monogame style
* Easy to mod

Subgoals:
* Easy exporting and debugging (being deterministic should allow us to 'replay' most gameplay related bugs)
* Good UI
* 3D (Maybe integrate Kinc or Mach or The-Forge)
