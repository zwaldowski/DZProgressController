Pod::Spec.new do |s|
  s.name         = 'DZProgressHUD'
  s.platform     = :ios
  s.license      = 'MIT'
  s.summary      = 'A dead simple, drop-in HUD view for iOS.'
  s.homepage     = 'https://github.com/zwaldowski/DZProgressHUD'
  s.author       = { 'Zachary Waldowski' => 'zwaldowski@gmail.com' }
  s.source       = { :git => 'https://github.com/zwaldowski/DZProgressHUD.git' }
  s.description  = 'DZProgressHUD is a drop-in iOS class that displays a translucent HUD with a ' \
                   'progress indicator and an optional label while work is being done. It is meant ' \
                   'as an easy-to-use replacement for the undocumented, private class UIProgressHUD.' 
  s.source_files = '*.{h,m}'
  s.resources    = 'Images/*.png'
  s.clean_paths  = 'Doxyfile', 'HudDemo', 'HudDemo.xcodeproj', '.gitignore'
  s.framework    = 'QuartzCore'
  s.requires_arc = true
end
