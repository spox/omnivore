require "./spec_helper"

describe Omnivore::Application do

  it "should create an application instance" do
    app = generate_omnivore_app("simple")
    app.should be_a(Omnivore::Application)
  end

  it "should process messages when running" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    final = app.endpoints["spec"].sources.first as Omnivore::Source::Spec
    message = Omnivore::Message.new(source)
    app.consume!
    endpoint.transmit(message)
    message = final.spec_mailbox.receive
    app.halt!
    if(message.nil?)
      fail "Expected message not received"
    else
      message.get(:data, :test, :value, type: :string).should eq("testing")
    end
  end

  it "should determine next endpoint" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    message = Omnivore::Message.new({"target" => "tester"} of String => JSON::Type, source)
    app.next_endpoint(message).should eq("tester")
  end

  it "should automatically route message to target" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    final = app.endpoints["spec"].sources.first as Omnivore::Source::Spec
    message = Omnivore::Message.new({"target" => "tester"} of String => JSON::Type, source)
    app.consume!
    endpoint.transmit(message)
    message = final.spec_mailbox.receive
    app.halt!
    if(message.nil?)
      fail "Expected message not received"
    else
      message.get(:data, :test, :value, type: :string).should eq("testing")
      message.get(:data, :test, :target_unset, type: :bool).should be_true
    end
  end

  it "should automatically route message to target via chaining" do
    app = generate_omnivore_app("chain")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    final = app.endpoints["spec"].sources.first as Omnivore::Source::Spec
    message = Omnivore::Message.new(source)
    app.consume!
    endpoint.transmit(message)
    message = final.spec_mailbox.receive
    app.halt!
    if(message.nil?)
      fail "Expected message not received"
    else
      message.get(:data, :test, :value, type: :string).should eq("testing")
      message.get(:data, :test, :target_unset, type: :bool).should be_true
    end
  end

end
