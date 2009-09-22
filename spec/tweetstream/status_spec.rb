require File.dirname(__FILE__) + '/../spec_helper'

describe TweetStream::Status do
  it 'should modify the :user key into a TweetStream::User object' do
    @status = TweetStream::Status.new(:user => {:screen_name => 'bob'})
    @status.user.is_a?(TweetStream::User).should be_true
    @status.user.screen_name.should == 'bob'
  end
end
