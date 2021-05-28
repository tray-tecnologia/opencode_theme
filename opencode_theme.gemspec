# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opencode_theme/version'

Gem::Specification.new do |spec|
  spec.name          = 'opencode_theme'
  spec.version       = OpencodeTheme::VERSION
  spec.authors       = ['Rafael Takashi Tanaka']
  spec.email         = ['rtanaka@tray.net.br']
  spec.description   = 'Command Line tool for developing themes in Tray E-commerce'
  spec.summary       = 'Provides simple commands to upload and download files from a themes'
  spec.homepage      = 'https://www.tray.com.br/opencode/'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.1.3'

  spec.add_dependency('thor', '>= 0.14.4')
  spec.add_dependency('httparty', '~> 0.14.0')
  spec.add_dependency('mimemagic', '~> 0.4.3')
  spec.add_dependency('filewatcher', '= 0.5.4')
  spec.add_dependency('launchy', '~> 2.5.0')

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'http_logger'

  spec.add_development_dependency "bundler", "~> 1.3"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables  << 'opencode'
  spec.require_paths = ['lib']
end
