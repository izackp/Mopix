//
//  TestAVC.m
//  TestGame
//
//  Created by Isaac Paul on 7/16/22.
//

#import <Foundation/Foundation.h>
#import <SDL2/SDL.h>
#import "../TestGame iOS/VCTest.h"

void testWindowThing(SDL_Window *sdlWindow)
{
    SDL_SysWMinfo systemWindowInfo;
    SDL_GetWindowWMInfo (sdlWindow, &systemWindowInfo);
    UIWindow * appWindow = systemWindowInfo.info.uikit.window;
    UIViewController * rootViewController = appWindow.rootViewController;
    
    UIViewController* myCustomeViewController = [VCTest new];
    [rootViewController presentViewController:myCustomeViewController animated:true completion:nil];
}

