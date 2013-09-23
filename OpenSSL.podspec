Pod::Spec.new do |s|
  s.name         = "OpenSSL"
  s.version      = "1.0.1e"
  s.summary      = "OpenSSL for iOS."
  s.description  = "Supports iPhone Simulator (i386 & x86_64), armv7, armv7s and arm64."
  s.homepage     = "http://www.openssl.org"
  s.license	     = 'OpenSSL (OpenSSL/SSLeay)'

  s.author       = 'ZHANG Yi'
  s.source       = { :git => "https://github.com/dorentus/openssl-pod.git", :tag => "1.0.1e" }

  s.prepare_command = 'rake'

  s.platform     = :ios, '5.0'
  s.public_header_files = 'dist/include/openssl/**/.h'
  s.vendored_libraries = 'dist/lib/*.a'
  s.library	  = 'crypto', 'ssl'
end
