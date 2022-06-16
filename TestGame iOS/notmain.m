#define SDL_MAIN_HANDLED

#include <SDL2/SDL.h>
#include <time.h>
#include "common.h"

#import <TestGame-Swift.h>


void
render(SDL_Renderer *renderer)
{
    Uint8 r, g, b;
    int renderW;
    int renderH;

    SDL_RenderGetLogicalSize(renderer, &renderW, &renderH);

    /*  Come up with a random rectangle */
    SDL_Rect rect;
    rect.w = randomInt(64, 128);
    rect.h = randomInt(64, 128);
    rect.x = randomInt(0, 64);
    rect.y = randomInt(0, 64);

    /* Come up with a random color */
    r = randomInt(50, 255);
    g = randomInt(50, 255);
    b = randomInt(50, 255);

    /*  Fill the rectangle in the color */
    SDL_SetRenderDrawColor(renderer, r, g, b, 255);
    SDL_RenderFillRect(renderer, &rect);

    /* update screen */
    SDL_RenderPresent(renderer);
}


int mainnot(int argc, char *argv[])
{
    return SDL_UIKitRunApp(argc, argv, SDL_main);
}

int
SDL_main(int argc, char *argv[])
{
    
    return [Main proxyMainWithArgc:argc argv:argv];
    SDL_Window *window;
    SDL_Renderer *renderer;
    int done;
    SDL_Event event;
    int windowW;
    int windowH;

    /* initialize SDL */
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        fatalError("Could not initialize SDL");
    }

    /* seed random number generator */
    srand(time(NULL));

    /* create window and renderer */
    window = SDL_CreateWindow(NULL, 0, 0, 320*2, 568*2, SDL_WINDOW_ALLOW_HIGHDPI);//SDL_WINDOW_ALLOW_HIGHDPI
    if (window == 0) {
        fatalError("Could not initialize Window");
    }
    renderer = SDL_CreateRenderer(window, -1, 0);
    if (!renderer) {
        fatalError("Could not create renderer");
    }

    SDL_GetWindowSize(window, &windowW, &windowH);
    SDL_RenderSetLogicalSize(renderer, windowW, windowH);

    /* Fill screen with black */
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);

    /* Enter render loop, waiting for user to quit */
    render(renderer);
    done = 0;
    while (!done) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                done = 1;
            }
        }
        //SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        //SDL_RenderClear(renderer);
        
        //SDL_RenderPresent(renderer);
        
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
        render(renderer);
        SDL_Delay(160);
    }

    /* shutdown SDL */
    SDL_Quit();

    return 0;
}
