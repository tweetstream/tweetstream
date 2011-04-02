require 'daemons'

# A daemonized TweetStream client that will allow you to
# create backgroundable scripts for application specific
# processes. For instance, if you create a script called
# <tt>tracker.rb</tt> and fill it with this:
#
#     require 'rubygems'
#     require 'tweetstream'
#
#     TweetStream::Daemon.new('user','pass', 'tracker').track('intridea') do |status|
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
  # Initialize a Daemon with the credentials of the
  # Twitter account you wish to use. The daemon has
  # an optional process name for use when querying
  # running processes.
  def initialize(user, pass, app_name=nil, parser=:json_gem)
    @app_name = app_name
    super(user, pass, parser)
  end

  def start(path, query_parameters = {}, &block) #:nodoc:
    # Because of a change in Ruvy 1.8.7 patchlevel 249, you cannot call anymore
    # super inside a block. So I assign to a variable the base class method before
    # the Daemons block begins.
    startmethod = super.start
    Daemons.run_proc(@app_name || 'tweetstream', :multiple => true) do
      startmethod(path, query_parameters, &block)
    end
  end
end
