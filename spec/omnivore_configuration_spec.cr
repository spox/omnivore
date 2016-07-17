require "./spec_helper"

describe Omnivore::Configuration do

  it "should create instance using data hash" do
    data = {"value1" => true, "value2" => "yay!"} of String => JSON::Type
    config = Omnivore::Configuration.new(data)
    config.get("value1", type: :bool).should be_true
    config.get("value2", type: :string).should eq("yay!")
  end

  it "should create instance using file" do
    config = generate_omnivore_config("test")
    config.get("value1", type: :bool).should be_true
    config.get("value2", type: :string).should eq("yay!")
  end

  it "should handle fetching deeply nested configuration" do
    config = generate_omnivore_config("test")
    config.get(:deep, :nesting, :value, type: :string).should eq("test")
  end

  it "should support hash style access" do
    config = generate_omnivore_config("test")
    config["value1"].should be_true
  end

end
