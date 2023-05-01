//
//  String+Util.swift
//  TestGame
//
//  Created by Isaac Paul on 4/28/22.
//

import Foundation

public extension StringProtocol {
    //Todo test trailing . like ".DS_STORE."
    func parseExt() -> SubSequence? {
        guard let dotPos = self.lastIndex(of: ".") else { return nil }
        let distance: Int = self.distance(from: dotPos, to: self.endIndex)
        if (distance == 0) { return nil }
        let advancedIndex = self.index(dotPos, offsetBy: 1)
        return self[advancedIndex...self.endIndex]
    }

    // basically splitFile in std/os
    /*
    func parseFileName() -> (String?, String?) {

      var namePos = 0
      var dotPos = 0
      for i in countdown(len(path) - 1, 0):
        if path[i] in {DirSep, AltSep} or i == 0:
          if path[i] in {DirSep, AltSep}:
            namePos = i + 1
          if dotPos > i:
            result.name = some(substr(path, namePos, dotPos - 1))
            result.ext = some(substr(path, dotPos+1))
          else if namePos < len(path):
            result.name = some(substr(path, namePos))
          break
        else if path[i] == ExtSep and
            i > 0 and
            i < len(path) - 1 and
            path[i - 1] notin {DirSep, AltSep} and
            path[i + 1] != ExtSep and
            dotPos == 0:
          dotPos = i
    }*/

    func parseDirNameExt() -> (SubSequence?, SubSequence?, SubSequence?) {
    /*
      runnableExamples:
        var (dir, name, ext) = parseFileName("nimc.html")
        assert dir.isNone()
        assert name == "nimc"
        assert ext == "html"*/

        var name:SubSequence? = nil
        var ext:SubSequence? = nil
        var dir:SubSequence? = nil
        var namePos = 0
        var dotPos = 0
        
        let lastIndex = self.count - 1
        let sep = OS.pathSeparatorSet
        for i in stride(from:lastIndex, through:0, by:-1) {
            let curC = self[i]
            if (sep.containsUnicodeScalars(of: curC) || i == 0) {
                if (sep.containsUnicodeScalars(of: curC)) {
                    //weird.. we never include the seperator in the path unless its the root..
                    let to = (i >= 1) ? i - 1 : 0
                    dir = self[0...to]
                    namePos = i + 1
                }
                if dotPos > i {
                    name = self[namePos...(dotPos - 1)]
                    ext = self[(dotPos+1)...lastIndex]
                } else if namePos < self.count {
                    name = self[namePos...lastIndex]
                }
                break
            } else if curC == OS.extSeparator &&
                        dotPos == 0 &&
                        i > 0 &&
                        i < lastIndex &&
                        sep.containsUnicodeScalars(of: self[i-1]) == false &&
                        self[i + 1] != OS.extSeparator {
                    dotPos = i
            }
        }
        return (dir, name, ext)
    }
}

/*
when isMainModule:
  var (name, ext) = parseFileName("nimc.html")
  assert !name == "nimc"
  assert !ext == "html"

  var (name1, ext1) = parseFileName("")
  assert name1.isNone
  assert ext1.isNone

  var (name3, ext3) = parseFileName("/A/Path/") //TODO: inconsistent behavior with "/A/Path" ; We could do parseLastElementName for consistent behavior...
  assert name3.isNone
  assert ext3.isNone

  static:
    assert !parseExt("nimc.html") == "html"
    assert parseExt("nimc").isNone
    assert parseExt("/nimc.html/").isNone
    assert parseExt(".DS_STORE.").isNone
    assert parseExt(".DS_STORE").isNone
    assert !parseExt(".DS_STORE.test") == "test"
*/
