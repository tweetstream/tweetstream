source 'https://rubygems.org'

gem 'rake'
gem 'yard'

group :development do
  gem 'kramdown'
  gem 'pry'
end

group :test do
  gem 'coveralls'
  gem 'rspec', '>= 3'
  # Go back to using the RuboCop gem after https://github.com/bbatsov/rubocop/pull/1956 is released
  gem 'rubocop', :git => 'https://github.com/bbatsov/rubocop.git', :ref => 'f8fbd50e02a19669727bd3a811419b7df6337b4b'
  gem 'simplecov', '>= 0.9'
  gem 'webmock'
end

gemspec
