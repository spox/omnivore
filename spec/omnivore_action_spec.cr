require "./spec_helper"

describe Omnivore::Action do

  it "should create a new action" do
    app = generate_omnivore_app("simple")
    message = Omnivore::Message.new(app.endpoints["tester"].sources.first)
    action = Omnivore::Action::Test.new(message, app.endpoints["tester"])
    action.execute.should be_nil
  end

  it "should merge action configuration" do
    app = generate_omnivore_app("simple")
    message = Omnivore::Message.new(app.endpoints["tester"].sources.first)
    action = Omnivore::Action::Test.new(message, app.endpoints["tester"])
    action.config.get(:key0, type: :string).should eq("value0")
    action.config.get(:key1, type: :string).should eq("value1")
  end

  it "should have access to message for processing" do
    app = generate_omnivore_app("simple")
    message = Omnivore::Message.new(app.endpoints["tester"].sources.first)
    action = Omnivore::Action::Test.new(message, app.endpoints["tester"])
    action.message.identifier.should eq(message.identifier)
  end

  it "should modify message when executed" do
    app = generate_omnivore_app("simple")
    message = Omnivore::Message.new(app.endpoints["tester"].sources.first)
    action = Omnivore::Action::Test.new(message, app.endpoints["tester"])
    action.execute
    message.get(:data, :test, :value, type: :string).should eq("testing")
  end

end
