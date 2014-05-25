Gem::Specification.new do |s|
  s.name = 'paper'
  s.version = '0.0.0'
  s.date = '2014-05-24'
  s.summary = 'A simple library for various word processor formats'
  s.description = 'A simple library for various word processor formats focusing primarily around conversion to HTML'
  s.homepage = 'https://github.com/voikya/paper'
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
