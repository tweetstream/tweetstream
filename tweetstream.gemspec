# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tweetstream/version"

Gem::Specification.new do |s|
  s.name        = 'tweetstream'
  s.version     = TweetStream::VERSION

  s.authors     = ['Michael Bleigh']
  s.email       = ['michael@intridea.com']
  s.description = %q{TweetStream allows you to easily consume the Twitter Streaming API utilizing the YAJL Ruby gem.}
  s.summary     = %q{TweetStream is a simple wrapper for consuming the Twitter Streaming API.}
  s.homepage    = 'http://github.com/intridea/tweetstream'

  s.platform                  = Gem::Platform::RUBY
  s.rubygems_version          = %q{1.3.6}
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=

  s.add_dependency('twitter-stream', '~> 0.1.13')
  s.add_dependency('daemons', '~> 1.1.2')
  s.add_dependency('multi_json', '~> 1.0.0')
  s.add_development_dependency('simplecov', '~> 0.4')
  s.add_development_dependency('yard', '~> 0.7')
  s.add_development_dependency('maruku', '~> 0.6')
  s.add_development_dependency('rspec', '~> 2.6.0')
  s.add_development_dependency('yajl-ruby', '~> 0.8.2')
  s.add_development_dependency('json', '~> 1.5.1')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
