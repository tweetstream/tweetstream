require 'daemons'

# A daemonized TweetStream client that will allow you to
# create backgroundable scripts for application specific
# processes. For instance, if you create a script called
# <tt>tracker.rb</tt> and fill it with this:
#
#     require 'rubygems'
#     require 'tweetstream'
#
#     TweetStream.configure do |config|
#       config.consumer_key = 'abcdefghijklmnopqrstuvwxyz'
#       config.consumer_secret = '0123456789'
#       config.oauth_token = 'abcdefghijklmnopqrstuvwxyz'
#       config.oauth_token_secret = '0123456789'
#       config.auth_method = :oauth
#     end
#
#     TweetStream::Daemon.new('tracker').track('intridea') do |status|
#       # do something here
#     end
#
# And then you call this from the shell:
#
#     ruby tracker.rb start
#
# A daemon process will spawn that will automatically
# run the code in the passed block whenever a new tweet
# matching your search term ('intridea' in this case)
# is posted.
#
class TweetStream::Daemon < TweetStream::Client

  DEFAULT_NAME = 'tweetstream'.freeze
  DEFAULT_OPTIONS = { :multiple => true }

  attr_accessor :app_name, :daemon_options

  # The daemon has an optional process name for use when querying
  # running processes.  You can also pass daemon options.
  def initialize(name = DEFAULT_NAME, options = DEFAULT_OPTIONS)
    @app_name = name
    @daemon_options = options
    super({})
  end

  def start(path, query_parameters = {}, &block) #:nodoc:
    Daemons.run_proc(@app_name, @daemon_options) do
      super(path, query_parameters, &block)
    end
  end
end
