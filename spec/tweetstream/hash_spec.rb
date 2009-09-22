require File.dirname(__FILE__) + '/../spec_helper'

describe TweetStream::Hash do
  it 'should be initialized by passing in an existing hash' do
    TweetStream::Hash.new(:abc => 123)[:abc].should == 123
  end
  
  it 'should symbolize incoming keys' do
    TweetStream::Hash.new('abc' => 123)[:abc].should == 123
  end
  
  it 'should allow access via method calls' do
    TweetStream::Hash.new(:abc => 123).abc.should == 123
  end
  
  it 'should still throw NoMethod for non-existent keys' do
    lambda{TweetStream::Hash.new({}).akabi}.should raise_error(NoMethodError)
  end
end