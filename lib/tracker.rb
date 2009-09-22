require 'rubygems'
require 'tweetstream'
require 'logger'

File.open('tracker.log', File::WRONLY | File::APPEND | File::CREAT) do |file|
  log = Logger.new(file)

  TweetStream::Daemon.new('mbleigh','hotmail', 'tracker').track('fail') do |status|
    log.info "[#{status.user.screen_name}] #{status.text}"
    puts "[#{status.user.screen_name}] #{status.text}"
  end
end