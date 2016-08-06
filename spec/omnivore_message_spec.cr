require "./spec_helper"

describe Omnivore::Message do

  it "should create a new message and set identifier" do
    source = Omnivore::Source::Internal.new("test", Channel(Omnivore::Message | Exception).new(1))
    message = Omnivore::Message.new(source)
    message.identifier.should be_a(String)
    message.identifier.size.should be > 0
  end

  it "should create a message using given data" do
    data = {"id" => "fubar"} of String => JSON::Type
    source = Omnivore::Source::Internal.new("test", Channel(Omnivore::Message | Exception).new(1))
    message = Omnivore::Message.new(data, source)
    message.identifier.should eq("fubar")
  end

  it "should fetch data via hashy helpers" do
    data = {"id" => "fubar", "data" => "value"} of String => JSON::Type
    source = Omnivore::Source::Internal.new("test", Channel(Omnivore::Message | Exception).new(1))
    message = Omnivore::Message.new(data, source)
    message.get(:data, type: :string).should eq("value")
  end

  it "should set data via hashy helpers" do
    data = {"id" => "fubar"} of String => JSON::Type
    source = Omnivore::Source::Internal.new("test", Channel(Omnivore::Message | Exception).new(1))
    message = Omnivore::Message.new(data, source)
    message.set(:data, :content, value: "testing")
    message.get(:data, :content, type: :string).should eq("testing")
  end

  it "should mark itself confirmed after being confirmed" do
    data = {"id" => "fubar"} of String => JSON::Type
    source = Omnivore::Source::Internal.new("test", Channel(Omnivore::Message | Exception).new(1))
    message = Omnivore::Message.new(data, source)
    message.confirmed?.should be_false
    message.confirm
    message.confirmed?.should be_true
  end

end
