Pod::Spec.new do |s|
  s.name = 'HanekeSwift'
  s.version = '0.8.1'
  s.license = 'Apache'
  s.summary = 'A lightweight generic cache for iOS written in Swift with extra love for images.'
  s.homepage = 'https://github.com/Haneke/HanekeSwift'
  s.authors = { 'Hermes Pique' => 'https://twitter.com/hpique' }
  s.source = { :git => 'https://github.com/Haneke/HanekeSwift.git', :tag => '0.8.1' }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'Haneke/*.swift'
end
