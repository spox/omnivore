require "./spec_helper"

describe Omnivore do

  it "should provide default logger" do
    Omnivore.logger.should be_a(Logger)
  end

  it "should raise exception when application is not initialized" do
    expect_raises(Omnivore::Error::NoApplication) do
      Omnivore.application
    end
  end

  it "should start empty application" do
    spawn{ Omnivore.run!({} of String => String) }
    Omnivore.wait_for_startup.should eq(true)
    Omnivore.application.should be_a(Omnivore::Application)
    Omnivore.application.halt!
  end

end
