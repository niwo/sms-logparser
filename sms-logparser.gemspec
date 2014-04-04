# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sms-logparser/version'

Gem::Specification.new do |spec|
  spec.name          = "sms-logparser"
  spec.version       = SmsLogparser::VERSION
  spec.authors       = ["niwo"]
  spec.email         = ["nik.wolfgramm@gmail.com"]
  spec.description   = %q{Reads access logs stored in a MySQL database (coming from the SWISS TXT CDN) and sends them to the SMS API.}
  spec.summary       = %q{sms-logparser - Logparser for Simplex Media Server (SMS)}
  spec.homepage      = "https://github.com/swisstxt/sms-logparser"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.3'
  
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'webmock'

  spec.add_dependency 'thor', '~> 0.19.1'
  spec.add_dependency 'mysql2'
  spec.add_dependency 'faraday', '~> 0.9.0'
  spec.add_dependency 'net-http-persistent', '>= 2.9.4'
end