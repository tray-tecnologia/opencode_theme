# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opencode_theme/version'

Gem::Specification.new do |spec|
  spec.name          = "opencode_theme"
  spec.version       = OpencodeTheme::VERSION
  spec.authors       = ["Rafael Takashi Tanaka"]
  spec.email         = ["rtanaka@tray.net.br"]
  spec.description   = %q{Command Line tool for developing themes in Tray E-commerce}
  spec.summary       = %q{Provides simple commands to upload and donwload files from a themes}
  spec.homepage      = "http://tray-tecnologia.github.io/theme-template/"
  spec.license       = "MIT"

  spec.add_dependency('thor', '>= 0.14.4')
  spec.add_dependency('httparty', '~> 0.13.0')
  spec.add_dependency('json', '~> 1.8.0')
  spec.add_dependency('mimemagic')
  spec.add_dependency('filewatcher')
  spec.add_dependency('launchy')

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'http_logger'

  spec.add_development_dependency "bundler", "~> 1.3"


  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables  << 'opencode'
  spec.require_paths = ['lib']
end
