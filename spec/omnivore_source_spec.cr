require "./spec_helper"

describe Omnivore::Source do

  it "should create a new source" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    endpoint.sources.first.should be_a(Omnivore::Source)
  end

  it "should accept message and send to endpoint mailbox" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    message = Omnivore::Message.new(source)
    source.start.should be_true
    source.transmit(message).should eq(source)
    e_msg = endpoint.mailbox.receive.as(Omnivore::Message)
    source.stop
    message.identifier.should eq(e_msg.identifier)
  end

  it "should return false if started when already running" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    source.start.should be_true
    source.start.should be_false
    source.stop
  end

  it "should return false if stopped when not running" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    source.start.should be_true
    source.stop.should be_true
    source.stop.should be_false
  end

  it "should show as consuming when running" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    source.start.should be_true
    source.consuming?.should be_true
  end

  it "should run connect when source starts" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    source.start.should be_true
    source.as(Omnivore::Source::Internal).connect_called.should be_true
  end

  it "should run shutdown when source stops" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    source.start.should be_true
    source.stop.should be_true
    source.as(Omnivore::Source::Internal).shutdown_called.should be_true
  end

end
