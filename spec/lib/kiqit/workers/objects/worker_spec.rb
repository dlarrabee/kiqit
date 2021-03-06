require 'spec_helper'

class DummyClass 
  def self.do_somthing_with_array_of_hashes(arr)
    arr[0][:foo]
  end

  def self.do_something_without_args
    true
  end

  def self.identity_function(data)
    data
  end

  def self.join(arg1, arg2)
    "#{arg1}|#{arg2}"
  end
end

describe Kiqit::Workers::Objects::Worker do
  subject { Kiqit::Workers::Objects::Worker.new }

  it "should pass an array of hashes into the method" do
    arr = [
      { foo: "bar" },
      { bar: "foo" }
    ]
    arr = Kiqit::ArgsParser.args_to_sidekiq(arr)
    subject.perform("DummyClass", :do_somthing_with_array_of_hashes, arr).should == "bar"
  end

  it "should pass no args to the method" do
    subject.perform("DummyClass", :do_something_without_args).should == true
  end

  it "should pass a single argument (user)" do
    user = User.create
    args = Kiqit::ArgsParser.args_to_sidekiq(user)
    subject.perform("DummyClass", :identity_function, args).should == user
  end

  it "should pass a single argument (user) when translated args are passed in" do
    user = User.create
    user_arg = "AR:User:#{user.id}"
    mock_user = double(:user, first: nil)
    User.should_receive(:where).with(id: user.id.to_s).and_return { mock_user }
    
    subject.perform("DummyClass", :identity_function, user_arg).should == nil
  end

  it "should pass an array with one entry" do
    users = [User.create]
    args = Kiqit::ArgsParser.args_to_sidekiq(users)
    subject.perform("DummyClass", :identity_function, args).should == users
  end

  it "should pass multi dimension arrays" do
    data = [1, 2, User.create, ["a", "b", "c"]]
    args = Kiqit::ArgsParser.args_to_sidekiq(data)
    subject.perform("DummyClass", :identity_function, args).should == data
  end

  it 'should pass AR and hash' do
    user = User.create
    arr = {
        something_a: "aaa",
        something_b: "bbb"
      }
    arg1 = Kiqit::ArgsParser.args_to_sidekiq(user)
    arg2 = Kiqit::ArgsParser.args_to_sidekiq(arr)
    subject.perform("DummyClass", :join, arg1, arg2).split("|")[1].should == "{:something_a=>\"aaa\", :something_b=>\"bbb\"}"
  end
end