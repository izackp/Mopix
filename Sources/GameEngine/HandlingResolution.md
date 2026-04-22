HandlingResolution

How do we support multiple resolutions?

We send UI screen size (420x300) and it gets scaled to fit the screen?
We send 1px = 1pt or 1px = 4pt? 
lets say our game is being drawin in 320px space but we have 1080p display,we can treat the pixels like points and scale up everything?

but what if we have a camera in a game world. Do we scale up or show more game world?

Do we just send the resolution back to the engine for it to decide?

What if we have different resources for different resolutions?

Here is the thing. We send the current (Window) resolution back, and the engine decides. Because what if things are out of bounds? We don't need to send draw commands for them and only the engine has scene info to cull these commands.