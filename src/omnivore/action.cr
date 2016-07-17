module Omnivore
  # Action to run on a message
  class Action

    include Omnivore::Utils::Logger

    @@actions = {"raw" => Action}

    # @return [Hash(String, Omnivore::Action+)] registered action types
    def self.actions
      @@actions
    end

    macro inherited
      class_key = "{{@type.name}}".sub("Omnivore::Action::", "")
      snake_key = snake_case("{{@type.name}}".sub("Omnivore::Action::", ""))
      Omnivore::Action.actions[class_key] = {{@type.name.id}}
      Omnivore::Action.actions[snake_key] = {{@type.name.id}}
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
      end.join("_").sub(/^omnivore_action_/, "")
    end

    # @return [Configuration] full application configuration
    def configuration : Configuration
      endpoint.application.configuration
    end

    # @return [Configuration] action specific configuration
    def config : Configuration
      base = configuration.get(:defaults, name, type: :hash)
      overlay = configuration.get(:endpoints, endpoint.name, :config, name, type: :hash)
      base = base.nil? ? {} of String => JSON::Type : base as Hash(String, JSON::Type)
      overlay = overlay.nil? ? {} of String => JSON::Type : overlay as Hash(String, JSON::Type)
      Configuration.new(base.to_smash.deep_merge(overlay.to_smash).unsmash)
    end

    # @return [Bool] message should be executed
    def valid? : Bool
      true
    end

    # Execute action on message
    #
    # @return [Nil]
    def execute : Nil
      nil
    end

  end
end

require "./action/*"
