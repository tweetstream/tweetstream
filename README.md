# TweetStream

[![Gem Version](https://badge.fury.io/rb/tweetstream.png)][gem]
[![Build Status](https://secure.travis-ci.org/tweetstream/tweetstream.png?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/tweetstream/tweetstream.png?travis)][gemnasium]
[![Code Climate](https://codeclimate.com/github/tweetstream/tweetstream.png)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/tweetstream/tweetstream/badge.png?branch=master)][coveralls]

[gem]: https://rubygems.org/gems/tweetstream
[travis]: http://travis-ci.org/tweetstream/tweetstream
[gemnasium]: https://gemnasium.com/tweetstream/tweetstream
[codeclimate]: https://codeclimate.com/github/tweetstream/tweetstream
[coveralls]: https://coveralls.io/r/tweetstream/tweetstream

TweetStream provides simple Ruby access to [Twitter's Streaming API](https://dev.twitter.com/docs/streaming-api).

## Installation

    gem install tweetstream

## Usage

Using TweetStream is quite simple:

```ruby
require 'tweetstream'

TweetStream.configure do |config|
  config.consumer_key       = 'abcdefghijklmnopqrstuvwxyz'
  config.consumer_secret    = '0123456789'
  config.oauth_token        = 'abcdefghijklmnopqrstuvwxyz'
  config.oauth_token_secret = '0123456789'
  config.auth_method        = :oauth
end

# This will pull a sample of all tweets based on
# your Twitter account's Streaming API role.
TweetStream::Client.new.sample do |status|
  # The status object is a special Hash with
  # method access to its keys.
  puts "#{status.text}"
end
```

You can also use it to track keywords or follow a given set of
user ids:

```ruby
# Use 'track' to track a list of single-word keywords
TweetStream::Client.new.track('term1', 'term2') do |status|
  puts "#{status.text}"
end

# Use 'follow' to follow a group of user ids (integers, not screen names)
TweetStream::Client.new.follow(14252, 53235) do |status|
  puts "#{status.text}"
end
```

The methods available to TweetStream::Client are kept in parity
with the methods available on the Streaming API wiki page.

## Changes in 2.0

TweetStream 2.0 introduces a number of requested features and bug fixes. For
the complete list refer to the [changelog](CHANGELOG.md#version-200). Notable
additions in 2.0 include:

### OAuth

OAuth is now the default authentication method.  Both userstreams and Site
Streams exclusively work with OAuth.  TweetStream still supports Basic Auth,
however it is no longer the default.  If you are still using Basic Auth, you
should plan to move to OAuth as soon as possible.

### Site Stream Support

Site Streams are now fully supported, including the connection management functionality.

### Compatability with the Twitter gem

TweetStream now emits objects from the [Twitter gem](https://github.com/sferik/twitter) instead of custom hashes. These objects are already defined in the `twitter` gem and are superior to the custom objects in the following ways:

1. Object equivalence (`#==` returns true if `#id`s are the same).
2. The `#created_at` method returns a `Date` instead of a `String`.
3. Allows boolean methods to be called with a question mark (e.g.
   `User#protected?`)

Additionally, any new features that are added to objects in the
`twitter` gem (e.g. identity map) will be automatically inherited by TweetStream.

### em-twitter

We've replaced the underlying gem that connects to the streaming API. [twitter-stream](https://github.com/voloko/twitter-stream) has been replaced with [em-twitter](https://github.com/spagalloco/em-twitter).
It offers functionality parity with twitter-stream while also supporting several new features.

### Removal of on_interval callback

We have removed the `on_interval` callback.  If you require interval-based timers, it is possible to run
TweetStream inside an already running EventMachine reactor in which you can define `EM::Timer` or `EM::PeriodicTimer`
for time-based operations:

```ruby
EM.run do
  client = TweetStream::Client.new

  EM::PeriodicTimer.new(10) do
    # do something on an interval
  end
end
```

### Additional Notes

The parser configuration method has been removed as MultiJson automatically detects existing parsers.

## Using the Twitter Userstream

Using the Twitter userstream works similarly to regular streaming, except you use the `userstream` method.

```ruby
# Use 'userstream' to get message from your stream
client = TweetStream::Client.new

client.userstream do |status|
  puts status.text
end
```

## Using Twitter Site Streams

```ruby
client = TweetStream::Client.new

client.sitestream(['115192457'], :followings => true) do |status|
  puts status.inspect
end
```

Once connected, you can [control the Site Stream connection](https://dev.twitter.com/docs/streaming-apis/streams/site/control):

```ruby
# add users to the stream
client.control.add_user('2039761')

# remove users from the stream
client.control.remove_user('115192457')

# obtain a list of followings of users in the stream
client.control.friends_ids('115192457') do |friends|
  # do something
end

# obtain the current state of the stream
client.control.info do |info|
  # do something
end
```

Note that per Twitter's documentation, connection management features are not
immediately available when connected

You also can use method hooks for both regular timeline statuses and direct messages.

```ruby
client = TweetStream::Client.new

client.on_direct_message do |direct_message|
  puts "direct message"
  puts direct_message.text
end

client.on_timeline_status do |status|
  puts "timeline status"
  puts status.text
end

client.userstream
```

## Authentication

TweetStream supports OAuth and Basic Auth.  `TweetStream::Client` now accepts
a hash:

```ruby
TweetStream::Client.new(:username => 'you', :password => 'pass')
```

Alternatively, you can configure TweetStream via the configure method:

```ruby
TweetStream.configure do |config|
  config.consumer_key       = 'cVcIw5zoLFE2a4BdDsmmA'
  config.consumer_secret    = 'yYgVgvTT9uCFAi2IuscbYTCqwJZ1sdQxzISvLhNWUA'
  config.oauth_token        = '4618-H3gU7mjDQ7MtFkAwHhCqD91Cp4RqDTp1AKwGzpHGL3I'
  config.oauth_token_secret = 'xmc9kFgOXpMdQ590Tho2gV7fE71v5OmBrX8qPGh7Y'
  config.auth_method        = :oauth
end
```

If you are using Basic Auth:

```ruby
TweetStream.configure do |config|
  config.username     = 'username'
  config.password     = 'password'
  config.auth_method  = :basic
end
```

TweetStream assumes OAuth by default.  If you are using Basic Auth, it is recommended
that you update your code to use OAuth as Twitter is likely to phase out Basic Auth
support.  Basic Auth is only available for public streams as User Stream and Site Stream
functionality [only support OAuth](https://dev.twitter.com/docs/streaming-apis/connecting#Authentication).

## Parsing JSON

TweetStream supports swappable JSON backends via MultiJson. Simply require your preferred
JSON parser and it will be used to parse responses.

## Handling Deletes and Rate Limitations

Sometimes the Streaming API will send messages other than statuses.
Specifically, it does so when a status is deleted or rate limitations
have caused some tweets not to appear in the stream. To handle these,
you can use the on_delete, on_limit and on_enhance_your_calm methods. Example:

```ruby
@client = TweetStream::Client.new

@client.on_delete do |status_id, user_id|
  Tweet.delete(status_id)
end

@client.on_limit do |skip_count|
  # do something
end

@client.on_enhance_your_calm do
  # do something
end

@client.track('intridea')
```

The on_delete and on_limit methods can also be chained:

```ruby
TweetStream::Client.new.on_delete{ |status_id, user_id|
  Tweet.delete(status_id)
}.on_limit { |skip_count|
  # do something
}.track('intridea') do |status|
  # do something with the status like normal
end
```

You can also provide `:delete` and/or `:limit`
options when you make your method call:

```ruby
TweetStream::Client.new.track('intridea',
  :delete => Proc.new{ |status_id, user_id| # do something },
  :limit => Proc.new{ |skip_count| # do something }
) do |status|
  # do something with the status like normal
end
```

Twitter recommends honoring deletions as quickly as possible, and
you would likely be wise to integrate this functionality into your
application.

## Errors and Reconnecting

TweetStream uses EventMachine to connect to the Twitter Streaming
API, and attempts to honor Twitter's guidelines in terms of automatic
reconnection. When Twitter becomes unavailable, the block specified
by you in `on_error` will be called. Note that this does not
indicate something is actually wrong, just that Twitter is momentarily
down. It could be for routine maintenance, etc.

```ruby
TweetStream::Client.new.on_error do |message|
  # Log your error message somewhere
end.track('term') do |status|
  # Do things when nothing's wrong
end
```

However, if the maximum number of reconnect attempts has been reached,
TweetStream will raise a `TweetStream::ReconnectError` with
information about the timeout and number of retries attempted.

On reconnect, the block specified by you in `on_reconnect` will be called:

```ruby
TweetStream::Client.new.on_reconnect do |timeout, retries|
  # Do something with the reconnect
end.track('term') do |status|
  # Do things when nothing's wrong
end
```

## Terminating a TweetStream

It is often the case that you will need to change the parameters of your
track or follow tweet streams. In the case that you need to terminate
a stream, you may add a second argument to your block that will yield
the client itself:

```ruby
# Stop after collecting 10 statuses
@statuses = []
TweetStream::Client.new.sample do |status, client|
  @statuses << status
  client.stop if @statuses.size >= 10
end
```

When `stop` is called, TweetStream will return from the block
the last successfully yielded status, allowing you to make note of
it in your application as necessary.

## Daemonizing

It is also possible to create a daemonized script quite easily
using the TweetStream library:

```ruby
# The third argument is an optional process name
TweetStream::Daemon.new('tracker').track('term1', 'term2') do |status|
  # do something in the background
end
```

If you put the above into a script and run the script with `ruby scriptname.rb`,
you will see a list of daemonization commands such as start, stop, and run.

A frequent use case is to use TweetStream along with ActiveRecord to insert new
statuses to a database. The library TweetStream uses the `daemons` gem for
daemonization which forks a new process when the daemon is created. After forking,
you'll need to reconnect to the database:

```ruby
ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(root, "config", "environment")

daemon = TweetStream::Daemon.new('tracker', :log_output => true)
daemon.on_inited do
  ActiveRecord::Base.connection.reconnect!
  ActiveRecord::Base.logger = Logger.new(File.open('log/stream.log', 'w+'))
end
daemon.track('term1') do |tweet|
  Status.create_from_tweet(tweet)
end
```

## Proxy Support

TweetStream supports a configurable proxy:

```ruby
TweetStream.configure do |config|
  config.proxy = { :uri => 'http://myproxy:8081' }
end
```

Your proxy will now be used for all connections.

## REST

To access the Twitter REST API, we recommend the [Twitter][] gem.

[twitter]: https://github.com/sferik/twitter

## Contributors

* [Michael Bleigh](https://github.com/mbleigh) (initial gem)
* [Steve Agalloco](https://github.com/spagalloco) (current maintainer)
* [Erik Michaels-Ober](https://github.com/sferik) (current maintainer)
* [Countless others](https://github.com/intridea/tweetstream/graphs/contributors)

## Copyright

Copyright (c) 2012-2013 Intridea, Inc. (http://www.intridea.com/). See
[LICENSE](LICENSE.md) for details.
