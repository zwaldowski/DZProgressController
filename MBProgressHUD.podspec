Pod::Spec.new do |s|
  s.name         = 'MBProgressHUD'
  s.platform     = :ios
  s.license      = 'MIT'
  s.summary      = 'A dead simple, drop-in HUD view for iOS.'
  s.homepage     = 'https://github.com/zwaldowski/MBProgressHUD'
  s.author       = { 'Zachary Waldowski' => 'zwaldowski@gmail.com',
                     'Jonathan George' => 'jonathan@jdg.net',
                     'Matej Bukovinski' => 'matej@bukovinski.com' }
  s.source       = { :git => 'https://github.com/zwaldowski/MBProgressHUD.git' }
  s.description  = 'MBProgressHUD is a drop-in iOS class that displays a translucent HUD with a ' \
                   'progress indicator and an optional label while work is being done. It is meant ' \
                   'as an easy-to-use replacement for the undocumented, private class UIProgressHUD.' 
  s.source_files = '*.{h,m}'
  s.resources    = 'Images/*.png'
  s.clean_paths  = 'Doxyfile', 'HudDemo', 'HudDemo.xcodeproj', '.gitignore'
  s.framework    = 'QuartzCore'
end
