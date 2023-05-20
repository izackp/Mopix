
## Notes & Ramblings
I tried out these languages:
* Haxe : I tried it out on a mac. No debugger for hashlink :( Their 3d engine was buggy. No real argument except I just didn't get a good vibe from it.
* Nim : Like it a lot, source code is understandable. However, I spent way too much learning macros because I wanted optionals, results, and early exits. Lack of _consistent_ support for indirection (interfaces, traits) made me look towards rust. Even the standard library uses different strategies for indirection. Look at file streams. Rust had all of the safety features I wanted (results and traits) that _everyone_ used.
* Rust : Looks sexy from the outside. Though, once you start working with it you realize that you realllyyyy need shared mutability in order to provide decent abstractions and decoupling. It's a huge learning curve for sure.
* Swift : I feel like swift is the most productive language I've ever used so I moved back to that. Swift is also in the works for implementing a sort of borrow checker, and I feel performance will soon be up to par.
* Zig : I took a peak it at. Seems cool. ~~Takes like 8 gbs of ram to compile~~ .. I got scared away once I saw the code to manipulate strings. Though it seems like you can hide the mess by providing your own string class. I have hope for this language. If I like it enough I might just port this over after I'm done.



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


#### Seperation between Logic, Drawing, and UI

Maybe inheritance will work to seperate entity drawing and logic behaviors?

SpaceShip
  - Stats (hp, speed, etc)
  - CollisionBox
  - MoveToTheSun
  
  static initializeBuilder(isRendering)
  static buildSpaceShip() -> SpaceShip //What if we need a drawable?
  
SpaceShipDrawable: SpaceShip
  - Sprite
  - Draw behavior
  - if (hp < 20) drawSmoke()

If we need performance we can still make a chunked pool of the specific entity.

Scene:
   if (rendering) SpaceShipDrawable else SpaceShip
   
What if we had a spaceship spawner?

hmmm
I feel like we could use #ifdefs to seperate the drawing and the logic. At least as a temporary solution.
Anything else will require some sort of indirection.

Thoooo I would to treat pieces of entities as hardwired components. More importantly..
Nevermind all this. I'm just going to get it working then figure it out afterwards


//Only for drawing
//var lastPos: Point<Int>
//Ok so if we do rollbacks..
//Draw server will call draw on the world before logic
//Then call logic(delta)
//Draw server will call draw again
//We're going to need to keep the previous draw list
// Logic calculates where we should be?
// One problem we're trying to solve/reduce is jitter
// if we draw at 60hz but logic is 50hz a handfull of frames will have no changes. (jitter)
// Assuming logic hz <= draw hz ; input -> step -> draw -> draw -> input -> step -> draw
// step _can_ describe where everything will be of x time.
// Tap a to jump.. step (16ms) -> draw (5ms) -> draw(15ms; 21ms total) // We can't draw the future?
// Tap a to jump.. step (16ms) -> draw (5ms) -> draw(8.33ms; 13.33ms total) // works but we need to limit this
// Lets say jumping is this: prep frame (16ms) -> -42 y (64ms) + Upper jump sprite
//From the a press to the prep frame this is going to be a delay of 16ms at least
//We can't draw what we want (immediately) because of jitter. oorrr??
// so jitter is a screen position thing... _not_ an animation thing.
//We can immediately draw what we want here.. and even give an animation timeline
// Tap a to jump.. step 1.. step 2 (16ms) -> draw (5ms) -> draw(8.33ms; 13.33ms total)
//Here on step 2 we move up. The first draw will draw us moving to -42, the second will be almost there.
//Lets say on step 3 we go down... the third will never reach the -42 height be we would have interpoliated through it
//This is weird because imagine never seeing a collision. Since we're already moving away by the time we draw
//We can force the game loop to draw the frame as if we reached the exact expected time..
//Then we end up with a less form of jitter?

//What if logic is very slow. Logic gives us where we will be in 200ms
//There will be a 0-200 ms + frame_ratehz input delay.. press a to jump so 200+ms to where we want to be
//The other extreme has the same input delay

//What I'm most worried about are fighting games. If we never want to miss a frame. Logic will definitely need to be faster than hz. Or maybe that's not possible. Because we could end up with < 1ms to do logic before the next frame is needed.
// In this case.. I think we can pass in not delta time but the target time. .. or nothing at all? if we have a frame that we need to display at 16ms its going to show. If logic dictates we need to display a frame immediately we will soon enough anways.. So what it comes down to.. your input might be delayed a frame because logic couldn't run fast enough.
// Or would it? you see frame 3 -> tap a ..  Nah this whole thing is a mess. I think we would need a special 'frame perfect mode' where logic would have to be faster than frame rate, but tick rate
