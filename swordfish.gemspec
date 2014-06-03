Gem::Specification.new do |s|
  s.name = 'swordfish'
  s.version = '0.0.5'
  s.date = '2014-06-03'
  s.summary = 'A simple library for various word processor formats'
  s.description = 'A simple library for various word processor formats focusing primarily around conversion to HTML'
  s.homepage = 'https://github.com/voikya/swordfish'
  s.license = 'MIT'
  s.authors = ['Martin Posthumus']
  s.email = 'martin.posthumus@gmail.com'
  s.files = Dir['lib/**/*.rb', 'README*']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.3'
  s.add_development_dependency 'bundler'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'rubyzip'
end
