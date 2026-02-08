Pod::Spec.new do |s|
  s.name             = 'media_controller'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for controlling media sessions on iOS.'
  s.description      = <<-DESC
A Flutter plugin for controlling media sessions on iOS devices.
                       DESC
  s.homepage         = 'https://github.com/shixin627/media_controller'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'

  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
