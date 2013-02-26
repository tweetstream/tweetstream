source 'https://rubygems.org'

gem 'rake'
gem 'yard'

group :development do
  gem 'guard-rspec'
  gem 'kramdown'
  gem 'pry'
  gem 'pry-debugger', :platforms => :mri_19
end

group :test do
  gem 'coveralls', :require => false
  gem 'json', :platforms => :ruby_18
  gem 'rspec', '>= 2.11'
  gem 'simplecov', :require => false
  gem 'webmock'
end

gemspec
