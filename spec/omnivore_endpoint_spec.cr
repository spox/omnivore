require "./spec_helper"

describe Omnivore::Endpoint do

  it "should create a new endpoint" do
    app = generate_omnivore_app("simple")
    app.endpoints["tester"].should be_a(Omnivore::Endpoint)
  end

  it "should create a single source within endpoint" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    endpoint.sources.first.should be_a(Omnivore::Source)
  end

  it "should have single action class defined" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    endpoint.actions.size.should eq(1)
    endpoint.actions.first.should eq(Omnivore::Action::Test)
  end

  it "should provide endpoint specific configuration" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    endpoint.config.should be_a(Omnivore::Configuration)
    endpoint.config["test"].should eq({"key1" => "value1"})
  end

  it "should process messages delivered to defined sources" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    message = Omnivore::Message.new(endpoint.sources.first)
    spawn do
      endpoint.start!
    end
    endpoint.mailbox.send(message)
    Fiber.yield
    endpoint.stop!
    message.get(:data, :test, :value, type: :string).should eq("testing")
  end

  it "should halt application on unexpected exception" do
    app = generate_omnivore_app("simple")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    error = Exception.new("stub")
    app.consume!
    endpoint.mailbox.send(error)
    10.times do
      Fiber.yield
      break unless app.active
    end
    app.active.should be_false
  end

end
