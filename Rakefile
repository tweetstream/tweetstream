require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "tweetstream"
    gem.summary = %Q{TweetStream is a simple wrapper for consuming the Twitter Streaming API.}
    gem.description = %Q{TweetStream allows you to easily consume the Twitter Streaming API utilizing the YAJL Ruby gem.}
    gem.email = "michael@intridea.com"
    gem.homepage = "http://github.com/intridea/tweetstream"
    gem.authors = ["Michael Bleigh"]
    gem.files = FileList["[A-Z]*", "{lib,spec}/**/*"] - FileList["**/*.log"]
    gem.add_development_dependency "rspec"
    gem.add_dependency 'yajl-ruby', '>= 0.6.6'
    gem.add_dependency 'daemons'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

namespace :release do
  %w(patch minor major).each do |level|
    desc "Tag a #{level} version and push it to Gemcutter."
    task level.to_sym => %w(version:bump:patch release gemcutter:release)
  end
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %w{--exclude "spec\/*,gems\/*"}
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tweetstream #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
