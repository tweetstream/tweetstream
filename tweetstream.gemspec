# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tweetstream/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'tweetstream'
  spec.version     = TweetStream::VERSION

  spec.authors     = ['Michael Bleigh', 'Steve Agalloco']
  spec.email       = ['michael@intridea.com', 'steve.agalloco@gmail.com']
  spec.description = %q{TweetStream allows you to easily consume the Twitter Streaming API utilizing the YAJL Ruby gem.}
  spec.summary     = %q{TweetStream is a simple wrapper for consuming the Twitter Streaming API.}
  spec.homepage    = 'http://github.com/intridea/tweetstream'
  spec.licenses    = ['MIT']

  spec.add_dependency 'em-twitter', '~> 0.2'
  spec.add_dependency 'twitter', '~> 4.0'
  spec.add_dependency 'daemons', '~> 1.1'
  spec.add_dependency 'multi_json', '~> 1.3'
  spec.add_dependency 'em-http-request', '~> 1.0.2'

  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'json'
  spec.add_development_dependency 'kramdown'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-debugger'
  spec.add_development_dependency 'simplecov'

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
