
### Virtual Drive

Virtual drive allows you to combine directories into one virtual drive. This is to make modding much easier. Lets say a mod adds more maps your resource directory could look like:
```
C:/game/BaseGame.1.0.1/maps/01.dat
C:/game/BaseGame.1.0.1/maps/02.dat
C:/game/MyMod.0.0.1/maps/02.dat
C:/game/MyMod.0.0.1/maps/03.dat

mounting both will produce this virtual file system:
/maps/01.dat
/maps/02.dat (from MyMod)
/maps/03.dat
````
02.dat from BaseGame is still accessable via `vd://BaseGame.1.0.1/02.dat`

Example Usage:
```
    virtualDrive.writeStream("BaseGame","/save.dat", stream)
    virtualDrive.writeStream(<MountedDirInstance>,"/save.dat", stream)
    virtualDrive.writeStream("vd://basegame.1.1.0/packagesave.dat", stream)
    virtualDrive.writeStream("vd://basegame/packagesave.dat", stream)
    ^ same for read
    virtualDrive.listMountedDir()
    virtualDrive.filesWithName("02.dat")
    virtualDrive.filesInDirectory("BaseGame", "/maps/")
    virtualDrive.filesInDirectory(<MountedDir>,"/maps/")
    virtualDrive.filesInDirectory("/maps/")
    virtualDrive.directoriesInDirectory("/storage", "/maps/")
    virtualDrive.directoriesInDirectory(<MountedDir>,"/maps/")
    virtualDrive.directoriesInDirectory("/maps/")
```

Urls to virtual files are expected or returned in URI format:
```
vd://<package_name>.<version>/<path>
or
vd://<package_name>/<path>
or
vd:/<path>
```


Why not just return direct urls?
In the future I would like to support loading zip files. These files will not have direct urls as they will reside in memory or on a section of disk.
