require "./spec_helper"

describe Omnivore::Processor do

  it "should modify message via preprocessor" do
    app = generate_omnivore_app("preprocessor")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    final = app.endpoints["spec"].sources.first as Omnivore::Source::Spec
    message = Omnivore::Message.new({"data" => {"process" => true}}, source)
    app.consume!
    endpoint.transmit(message)
    message = final.spec_mailbox.receive
    app.halt!
    if(message.nil?)
      fail "Expected message not received"
    else
      message.get(:data, :processor, :test, type: :string).should eq("set")
    end
  end

  it "should modify message via postprocessor" do
    app = generate_omnivore_app("postprocessor")
    endpoint = app.endpoints["tester"]
    source = endpoint.sources.first
    final = app.endpoints["spec"].sources.first as Omnivore::Source::Spec
    message = Omnivore::Message.new({"data" => {"process" => true}}, source)
    app.consume!
    endpoint.transmit(message)
    message = final.spec_mailbox.receive
    app.halt!
    if(message.nil?)
      fail "Expected message not received"
    else
      message.get(:data, :processor, :test, type: :string).should eq("set")
    end
  end

  it "should not modify message via postprocessor if not applicable" do
    app = generate_omnivore_app("postprocessor")
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
      message.get(:data, :processor, :test, type: :string).should_not eq("set")
    end
  end

end
