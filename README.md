DZProgressController
=============

`DZProgressController` is a drop-in iOS class that displays a translucent HUD with a progress indicator and an optional label. It is meant as an easy-to-use replacement for the undocumented, private class `UIProgressHUD`. 

`DZProgressController` is compatible with iOS 4 and up and released under the MIT license. It is derived from [MBProgressHUD](https://github.com/jdg/MBProgressHUD).

### Screenshots

* [Simple HUD](http://d.pr/i/UOdH+)
* [With label](http://d.pr/i/UOdH+)
* [Determinate progress](http://d.pr/i/h6Pq+)
* [Custom view: success](http://d.pr/i/tenx+)
* [Custom view: failure](http://d.pr/i/vTrV+)

Installation
============

The simplest way to add the `DZProgressController` to your project is to directly add the source files to your project, as well as the four completion images.

1. Download the latest code version from the repository. You can simply use the Download Source button and get a zipball or tarball.
2. Extract the archive.
3. Open your project in Xcode, than drag and drop `DZProgressController.h` and `DZProgressController.m` to your Classes group (in the Groups & Files view). Make sure to select Copy Items when asked. 
4. Drag and drop the four images (`success.png`, `success@2x.png`, `error.png`, and `error@2x.png`) into the Resources group.

If you have a git tracked project, you can add DZProgressHUD as a submodule to your project. 

1. `cd`` inside your git tracked project.
2. Add `DZProgressController` as a submodule using `git submodule add git://github.com/zwaldowski/DZProgressController.git DZProgressController` .
3. Open your project in Xcode, than drag and drop `DZProgressController.h` and `DZProgressController.m` to your classes group (in the Groups & Files view). Don't select Copy Items. 
4. Drag and drop the four images (`success.png`, `success@2x.png`, `error.png`, and `error@2x.png`) into the Resources group.

Usage
=====

Extensive documentation is provided in the header file. Additionally, a full Xcode demo project is included.

License
=======

This code is distributed under the terms and conditions of the MIT license. 

Copyright (c) 2012 Zachary Waldowski.
Copyright (c) 2009-2012 Matej Bukovinski, Jonathan George, and MBProgressHUD contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.