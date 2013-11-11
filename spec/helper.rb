require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '.bundle'
end

require 'tweetstream'
require 'tweetstream/site_stream_client'
require 'json'
require 'rspec'
require 'webmock/rspec'

WebMock.disable_net_connect!(:allow => 'coveralls.io')

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:each) do
    TweetStream.reset
  end
end

def samples(fixture)
  samples = []
  fixture(fixture).each_line do |line|
    samples << JSON.parse(line, :symbolize_names => true)
  end
  samples
end

def sample_tweets
  return @tweets if @tweets
  @tweets = samples('statuses.json')
end

def sample_direct_messages
  return @direct_messages if @direct_messages
  @direct_messages = samples('direct_messages.json')
end

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end

FakeHttp = Class.new do
  def callback; end
  def errback; end
end
