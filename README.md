MBProgressHUD
=============

`MBProgressHUD` is a drop-in iOS class that displays a translucent HUD with a progress indicator and an optional label while work is being done. It is meant as an easy-to-use replacement for the undocumented, private class `UIProgressHUD`. 

`MBProgressHUD` is compatible with iOS 4 and up and released under the MIT license.

[![Simple HUD](http://d.pr/3I3+)](http://d.pr/3I3+)
[![With native label](http://d.pr/N42R+)](http://d.pr/N42R+)
[![Determinate progress](http://d.pr/wukD+)](http://d.pr/wukD+)
[![Custom view: success](http://d.pr/vlxv+)](http://d.pr/vlxv+)
[![Custom view: failure](http://d.pr/lod2+)](http://d.pr/lod2+)

Installation
============

The simplest way to add the `MBProgressHUD` to your project is to directly add the source files to your project, as well as the four completion images.

1. Download the latest code version from the repository. You can simply use the Download Source button and get a zipball or tarball.
2. Extract the archive.
3. Open your project in Xcode, than drag and drop `MBProgressHUD.h` and `MBProgressHUD.m` to your Classes group (in the Groups & Files view). Make sure to select Copy Items when asked. 
4. Drag and drop the four images (`success.png`, `success@2x.png`, `error.png`, and `error@2x.png`) into the Resources group.

If you have a git tracked project, you can add MBProgressHUD as a submodule to your project. 

1. `cd`` inside your git tracked project.
2. Add `MBProgressHUD` as a submodule using `git submodule add git://github.com/matej/MBProgressHUD.git MBProgressHUD` .
3. Open your project in Xcode, than drag and drop `MBProgressHUD.h` and `MBProgressHUD.m` to your classes group (in the Groups & Files view). Don't select Copy Items. 
4. Drag and drop the four images (`success.png`, `success@2x.png`, `error.png`, and `error@2x.png`) into the Resources group.

Usage
=====

Extensive documentation is provided in the header file. Additionally, a full Xcode demo project is included.

License
=======

This code is distributed under the terms and conditions of the MIT license. 

Copyright (c) 2010-2012 Jonathan George, Matej Bukovinski, Zachary Waldowski, and the MBProgressHUD contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.