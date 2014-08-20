Gem::Specification.new do |s|
  s.name = 'swordfish'
  s.version = '0.0.13'
  s.date = '2014-08-20'
  s.summary = 'A simple library for various word processor formats'
  s.description = 'A simple library for various word processor formats focusing primarily around conversion to HTML'
  s.homepage = 'https://github.com/voikya/swordfish'
  s.license = 'MIT'
  s.authors = ['Martin Posthumus']
  s.email = 'martin.posthumus@gmail.com'
  s.files = Dir['lib/**/*.rb', 'README*']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.3'
  s.add_development_dependency 'bundler', '~> 1'
  s.add_runtime_dependency 'nokogiri', '~> 1.6', '>= 1.6.0'
  s.add_runtime_dependency 'rubyzip', '~> 1.1', '>= 1.1.0'
end
