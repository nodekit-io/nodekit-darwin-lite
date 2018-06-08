Pod::Spec.new do |s|
s.name         = "NKScriptingLite"
s.version      = "0.10.0"
s.summary      = "The universal, open-source, embedded engine"
s.description  = "NodeKit is the universal, open-source, embedded engine that provides a full ES5 / Node.js instance inside desktop and mobile applications for OS X, iOS, Android, and Windows."
s.homepage     = "https://github.com/nodekit-io/nodekit"
s.license      = { :type => 'APACHE-2', :file => 'LICENSE' }
s.author       = { "OffGrid Networks" => 'admin@offgridn.com' }
s.source       = { :git => "https://github.com/nodekit-io/nodekit-darwin-lite.git", :tag => "0.9.1" }

s.ios.deployment_target = '9.0'
s.osx.deployment_target = '10.11'
s.requires_arc = true
s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
s.libraries = 'compression'
s.source_files =  "src/nodekit/NKScripting/**/*.{swift,h,m}", "src/nodekit/NKScriptingLite/**/*.{swift,h,m}"
s.resources =  [
'src/nodekit/NKScripting/lib-scripting.nkar',
]

end
