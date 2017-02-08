require "spec"

ENV["OMNIVORE_SPEC"] = "true"

require "../src/omnivore"

# Keep logger silent by default
unless(ENV["DEBUG"]?)
  Omnivore.configure_logger({"log_path" => "/dev/null"}, {} of String => String)
else
  Omnivore.logger.level = Logger::DEBUG
end

def generate_omnivore_app(config_name)
  config = generate_omnivore_config(config_name)
  Omnivore::Application.new(config)
end

def generate_omnivore_config(config_name)
  Omnivore::Configuration.new(File.expand_path("spec/configs/#{config_name}.json", Dir.current))
end
