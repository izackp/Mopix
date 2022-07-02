//
//  TTFInterface.h
//  TestGame
//
//  Created by Isaac Paul on 6/28/22.
//


#ifndef TTFInterface_h
#define TTFInterface_h
#import <CoreGraphics/CoreGraphics.h>

NSArray* fontFamilyNames(void);
NSData* fontDataForCGFont(CGFontRef cgFont);

#endif /* TTFInterface_h */
