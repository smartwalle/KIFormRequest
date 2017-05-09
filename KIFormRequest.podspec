Pod::Spec.new do |s|
  s.name         = "KIFormRequest"
  s.version      = "3.0.0"
  s.summary      = "KIFormRequest"
  s.description  = <<-DESC
                  KIFormRequest.
                   DESC

  s.homepage     = "https://github.com/smartwalle/KIFormRequest"
  s.license      = { :type => "MIT"}
  s.author       = { "SmartWalle" => "smartwalle@gmail.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/smartwalle/KIFormRequest.git", :tag => "#{s.version}" }
  s.source_files  = "KIFormRequest/KIFormRequest/*.{h,m}", "KIFormRequest/KIFormRequest/Reachability/*.{h,m}"
  s.requires_arc  = true
  s.dependency "AFNetworking"
end
