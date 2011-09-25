require 'spec_helper'

describe TweetStream::DirectMessage do
  it 'modifies the :sender key into a TweetStream::User object called #user' do
    @status = TweetStream::DirectMessage.new({:sender => {:screen_name => 'bob'}})
    @status.user.is_a?(TweetStream::User).should be_true
    @status.user.screen_name.should == 'bob'
  end

  it 'transforms the sender into a TweetStream::User object called #sender' do
    @status = TweetStream::DirectMessage.new({:sender => {:screen_name => 'bob'}})
    @status.sender.is_a?(TweetStream::User).should be_true
    @status.sender.screen_name.should == 'bob'
  end

  it 'overrides the #id method for itself and the user' do
    @status = TweetStream::DirectMessage.new({:id => 123, :sender => {:id => 345}})
    @status.id.should == 123
    @status.user.id.should == 345
  end
end
