module Omnivore
  # Processor to apply to message
  class Processor

    include Omnivore::Utils::Logger

    @@processors = {"raw" => Processor}

    # @return [Hash(String, Omnivore::Processor+)] registered processor types
    def self.processors
      @@processors
    end

    macro inherited
      class_key = "{{@type.name}}".sub("Omnivore::Processor::", "")
      snake_key = snake_case("{{@type.name}}".sub("Omnivore::Processor::", ""))
      Omnivore::Processor.processors[class_key] = {{@type.name.id}}
      Omnivore::Processor.processors[snake_key] = {{@type.name.id}}
    end

    property message : Message
    property endpoint : Endpoint

    # Create a new instance
    #
    # @param message [Message]
    # @param configuration [Configuration]
    # @return [self]
    def initialize(@message : Message, @endpoint : Endpoint)
    end

    # @return [String]
    def name
      valid_parts = self.class.name.split("::")[0, 3]
      valid_parts.map do |part|
        part.gsub(/([a-z])([A-Z])/, "\1_\2").gsub("-", "_").downcase
      end.join("_").sub(/^omnivore_processor_/, "")
    end

    # @return [Configuration] full application configuration
    def configuration : Configuration
      endpoint.application.configuration
    end

    # @return [Configuration] processor specific configuration
    def config : Configuration
      base = configuration.get(:defaults, :processors, name, type: :hash)
      overlay = configuration.get(:endpoints, endpoint.name, :config, :processors, name, type: :hash)
      base = base.nil? ? {} of String => JSON::Type : base as Hash(String, JSON::Type)
      overlay = overlay.nil? ? {} of String => JSON::Type : overlay as Hash(String, JSON::Type)
      Configuration.new(base.to_smash.deep_merge(overlay.to_smash).unsmash)
    end

    # @return [Bool] processor should be applied
    def apply? : Bool
      true
    end

    # Execute action on message
    #
    # @return [Nil]
    def apply : Message
      message
    end

  end
end

require "./processor/*"
