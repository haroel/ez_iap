Pod::Spec.new do |s|
  s.name         = "ez_iap"
  s.version      = "0.0.1"
  s.summary      = "iOS iap"
  s.homepage     = "https://github.com/haroel/ez_iap"
  s.license      = "MIT"
  s.author             = { "Howe Ho" => "ihowe@outlook.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/haroel/ez_iap.git", :tag => "0.0.1" }
  s.source_files  = "ez_iap", "ez_iap/*.{h,m,mm}"
  s.framework  = "StoreKit"
end