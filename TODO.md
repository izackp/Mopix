
### Current Tasks
[ ] Hide all exposed SDL api/structs
[ ] Get asset reloading working
[Hold] Fix frame hiccups. Sometimes our logic starts late and holds up the thread so we miss the draw opportunity? maybe?
   Looked into it... seems like a bug with sdl. Present and PollEvent random takes a ton of time. Still need to test on windows.

[ ] odd yet significant delay reading input with SDL_PollEvent
[ ] same issue with SDL_Present eating up 1-2 frames
### Todo Tasks
```
  = Unstarted
o = WIP
/ = Happy path works
x = Done

[/] Seperate SwiftSDL into its own project
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
[/] Tweening library
 - Odd 6x performance slow down when main project is an spm project
[o] Support windows / linux
- [/] Move project to SPM
- [/] Add build and vscode integration instructions. Possible include binaries to reduce friction.
- [ ] Test on linux
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
