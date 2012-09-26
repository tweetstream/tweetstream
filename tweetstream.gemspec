# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tweetstream/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'tweetstream'
  s.version     = TweetStream::VERSION

  s.authors     = ['Michael Bleigh', 'Steve Agalloco']
  s.email       = ['michael@intridea.com', 'steve.agalloco@gmail.com']
  s.description = %q{TweetStream allows you to easily consume the Twitter Streaming API utilizing the YAJL Ruby gem.}
  s.summary     = %q{TweetStream is a simple wrapper for consuming the Twitter Streaming API.}
  s.homepage    = 'http://github.com/intridea/tweetstream'

  s.add_dependency 'em-twitter', '~> 0.1'
  s.add_dependency 'twitter', '~> 4.0'
  s.add_dependency 'daemons', '~> 1.1'
  s.add_dependency 'multi_json', '~> 1.3'
  s.add_dependency 'em-http-request', '~> 1.0.2'

  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'json'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdiscount'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'yajl-ruby'
  s.add_development_dependency 'yard'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
