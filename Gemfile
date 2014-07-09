source 'https://rubygems.org'

gem 'rake'
gem 'yard'

group :development do
  platforms :mri_19, :mri_20, :mri_21 do
    gem 'guard-rspec'
  end
  gem 'kramdown'
  gem 'pry'
end

group :test do
  gem 'coveralls', :require => false
  gem 'json', :platforms => :ruby_18
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'rest-client', '~> 1.6.0', :platforms => [:jruby, :ruby_18]
  gem 'rspec', '>= 3'
  gem 'rubocop', '>= 0.23', :platforms => [:ruby_19, :ruby_20, :ruby_21]
  gem 'simplecov', :require => false
  gem 'webmock'
end

gemspec
