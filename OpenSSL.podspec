Pod::Spec.new do |s|
  s.name         = "OpenSSL"
  s.version      = "1.1.0c"
  s.summary      = "OpenSSL for iOS."
  s.description  = "Supports iPhone Simulator (i386 & x86_64), armv7, and arm64."
  s.homepage     = "http://www.openssl.org"
  s.license      = 'OpenSSL (OpenSSL/SSLeay)'

  s.author       = 'ZHANG Yi'
  s.source       = { :git => "https://github.com/dorentus/openssl-pod.git", :tag => "1.1.0c" }

  s.prepare_command = 'rake'

  s.platform     = :ios, '7.0'
  s.public_header_files = 'dist/include/openssl/**/.h'
  s.vendored_libraries = 'dist/lib/*.a'
  s.library	  = 'crypto', 'ssl'
end
