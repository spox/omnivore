require "./spec_helper"

describe Omnivore::Application::Star do

  it "should automatically send message to defined path" do
    config = generate_omnivore_config("pathed")
    app = Omnivore::Application::Pathed.new(config)
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    final = app.endpoints["spec"].sources.first.as(Omnivore::Source::Spec)
    payload = Crogo::Smash.new
    payload.set(:delivery, :pathed, :path, value: ["tester", "tester", "spec"])
    message = Omnivore::Message.new(payload.unsmash, source)
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

  it "should automatically send message to defined path" do
    config = generate_omnivore_config("pathed")
    app = Omnivore::Application::Pathed.new(config)
    endpoint = app.endpoints["stub"]
    source = endpoint.sources.first
    final = app.endpoints["spec"].sources.first.as(Omnivore::Source::Spec)
    payload = Crogo::Smash.new
    payload.set(:delivery, :pathed, :path, value: ["tester", "tester", "spec"])
    payload.set(:target, value: "tester")
    message = Omnivore::Message.new(payload.unsmash, source)
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
