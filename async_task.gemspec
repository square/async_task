# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'async_task/version'

Gem::Specification.new do |spec|
  spec.name          = 'async_task'
  spec.version       = AsyncTask::VERSION
  spec.authors       = ['James Chang']
  spec.email         = ['jchang@squareup.com']

  spec.summary       = 'Lightweight, asynchronous, and database-backed execution of singleton methods.'
  spec.homepage      = 'https://github.com/square/async_task'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency 'activejob', '>= 4.2.0', '< 5.2'
  spec.add_runtime_dependency 'activerecord', '>= 4.2.0', '< 5.2'
  spec.add_runtime_dependency 'activesupport', '>= 4.2.0', '< 5.2'

  spec.add_runtime_dependency 'enumerize'
  spec.add_runtime_dependency 'with_advisory_lock'
end
