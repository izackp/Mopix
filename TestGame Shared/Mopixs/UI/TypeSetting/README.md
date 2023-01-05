
# Type Setting 

I was initially thinking about porting this to swift: https://github.com/npillmayer/uax . However, This is a very complex feature especially when it comes to bi directional text. Implementing a small piece means eventually supporting the whole thing. There are libraries such as FriBidi that seem to be used in a few projects. ICU dropped support for windows and osx? It seems rules also must be bent for terminal style applications. Aka problematic.

The secound idea was to create a swift library for libunibreak which seemed alright. 

Third, I knew these os's already have line breaking code somewhere. Which led me to this library: https://github.com/kphrx/icu-swift


References:
* https://www.unicode.org/reports/tr14/
* https://npillmayer.github.io/UAX/2021/bidi-console/ - Bidi what you see isn't what you get
* https://terminal-wg.pages.freedesktop.org/bidi/ - Bidi in terminal emulators


https://github.com/bbc/unicode-bidirectional/blob/master/README.md

https://github.com/darlinghq/darling-icu - Apple's version of icu

https://github.com/adah1972/libunibreak

https://util.unicode.org/UnicodeJsps/breaks.jsp - Online break reference


We currently depend on foundation.. we should remove this dependency
