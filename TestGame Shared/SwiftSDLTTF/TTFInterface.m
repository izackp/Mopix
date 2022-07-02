//
//  TTFInterface.c
//  TestGame
//
//  Created by Isaac Paul on 6/28/22.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#include "TTFInterface.h"

typedef struct FontHeader {
    int32_t fVersion;
    uint16_t fNumTables;
    uint16_t fSearchRange;
    uint16_t fEntrySelector;
    uint16_t fRangeShift;
} FontHeader;

typedef struct TableEntry {
    uint32_t fTag;
    uint32_t fCheckSum;
    uint32_t fOffset;
    uint32_t fLength;
} TableEntry;

static uint32_t CalcTableCheckSum(const uint32_t *table, uint32_t numberOfBytesInTable) {
    uint32_t sum = 0;
    uint32_t nLongs = (numberOfBytesInTable + 3) / 4;
    while (nLongs-- > 0) {
       sum += CFSwapInt32HostToBig(*table++);
    }
    return sum;
}

static uint32_t CalcTableDataRefCheckSum(CFDataRef dataRef) {
    const uint32_t *dataBuff = (const uint32_t *)CFDataGetBytePtr(dataRef);
    uint32_t dataLength = (uint32_t)CFDataGetLength(dataRef);
    return CalcTableCheckSum(dataBuff, dataLength);
}

static size_t fontSizeForTag(CGFontRef cgFont, uint32_t tag) {
    CFDataRef tableDataRef = CGFontCopyTableForTag(cgFont, tag);
    size_t tableSize = 0;
    if (tableDataRef != NULL) {
        tableSize = CFDataGetLength(tableDataRef);
        CFRelease(tableDataRef);
    }
    return tableSize;
}

// Inspired by:
// http://skia.googlecode.com/svn-history/r1473/trunk/src/ports/SkFontHost_mac_coretext.cpp
// https://github.com/google/flatui/blob/master/src/font_systemfont.cpp
NSData* fontDataForCGFont(CGFontRef cgFont) {
    
    if (cgFont == NULL) {
        return nil;
    }

    CFRetain(cgFont);
    
    CFArrayRef tags = CGFontCopyTableTags(cgFont);
    int tableCount = (int)CFArrayGetCount(tags);
    
    size_t mallocSize = sizeof(size_t) * tableCount;
    size_t* tableSizes = malloc(mallocSize);
    memset(tableSizes, 0, mallocSize);
    
    size_t totalSize = sizeof(FontHeader) + sizeof(TableEntry) * tableCount;
    bool containsCFFTable = false;
    for (int index = 0; index < tableCount; ++index) {
        //Each entry in the array is a four-byte value representing a single TrueType or OpenType font table tag.
        uint32_t tag = (uint32_t)CFArrayGetValueAtIndex(tags, index);
       
        if (tag == 'CFF ') {
            containsCFFTable = true;
        }
        
        size_t tableSize = fontSizeForTag(cgFont, tag);
        totalSize += (tableSize + 3) & ~3;
        tableSizes[index] = tableSize;
    }
    
    unsigned char *stream = malloc(totalSize);
    memset(stream, 0, totalSize);
    
    char* dataStart = (char*)stream;
    char* dataPtr = dataStart;

    uint16_t entrySelector = 0;
    uint16_t searchRange = 1;
    
    while (searchRange < tableCount >> 1) {
        entrySelector++;
        searchRange <<= 1;
    }
    searchRange <<= 4;
    
    uint16_t rangeShift = (tableCount << 4) - searchRange;
    
    FontHeader* offsetTable = (FontHeader*)dataPtr;
    offsetTable->fVersion = containsCFFTable ? 'OTTO' : CFSwapInt16HostToBig(1);
    offsetTable->fNumTables = CFSwapInt16HostToBig((uint16_t)tableCount);
    offsetTable->fSearchRange = CFSwapInt16HostToBig((uint16_t)searchRange);
    offsetTable->fEntrySelector = CFSwapInt16HostToBig((uint16_t)entrySelector);
    offsetTable->fRangeShift = CFSwapInt16HostToBig((uint16_t)rangeShift);

    dataPtr += sizeof(FontHeader);

    TableEntry* entry = (TableEntry*)dataPtr;
    dataPtr += sizeof(TableEntry) * tableCount;
    
    for (int index = 0; index < tableCount; ++index) {
        
        uint32_t aTag = (uint32_t)CFArrayGetValueAtIndex(tags, index);
        CFDataRef tableDataRef = CGFontCopyTableForTag(cgFont, aTag);
        size_t tableSize = CFDataGetLength(tableDataRef);
        
        memcpy(dataPtr, CFDataGetBytePtr(tableDataRef), tableSize);
        
        entry->fTag = CFSwapInt32HostToBig((uint32_t)aTag);
        entry->fCheckSum = CFSwapInt32HostToBig(CalcTableCheckSum((uint32_t *)dataPtr, (uint32_t)tableSize));
        
        uint32_t offset = (uint32_t)(dataPtr - dataStart);
        entry->fOffset = CFSwapInt32HostToBig((uint32_t)offset);
        entry->fLength = CFSwapInt32HostToBig((uint32_t)tableSize);
        dataPtr += (tableSize + 3) & ~3;
        ++entry;
        CFRelease(tableDataRef);
    }
    
    CFRelease(cgFont);
    free(tableSizes);
    NSData *fontData = [NSData dataWithBytesNoCopy:stream length:totalSize freeWhenDone:true];
    return fontData;
}

NSArray* fontFamilyNames() {
    CFArrayRef arr = CTFontManagerCopyAvailableFontFamilyNames();
    NSArray *array = CFBridgingRelease(arr);
    return array;
}
