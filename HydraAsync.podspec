Pod::Spec.new do |spec|
  spec.name = 'HydraAsync'
  spec.version = '2.0.6'
  spec.summary = 'Promises & Await: Write better async in Swift'
  spec.homepage = 'https://github.com/malcommac/Hydra'
  spec.license = { :type => 'MIT', :file => 'LICENSE' }
  spec.author = { 'Daniele Margutti' => 'me@danielemargutti.com' }
  spec.social_media_url = 'http://twitter.com/danielemargutti'
  spec.source = { :git => 'https://github.com/malcommac/Hydra.git', :tag => "#{spec.version}" }
  spec.source_files = 'Sources/**/*.swift'
  spec.ios.deployment_target = '9.0'
  spec.watchos.deployment_target = '2.0'
  spec.osx.deployment_target = '10.10'
  spec.tvos.deployment_target = '9.0'
  spec.requires_arc = true
  spec.module_name = 'Hydra'
  spec.frameworks  = "Foundation"
  spec.swift_versions = ['4.0', '4.1', '4.2', '5.0', '5.1', '5.3']
end
