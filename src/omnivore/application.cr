module Omnivore
  # Omnivore application implementation. Application
  # determines message handling behavior
  class Application

    include Omnivore::Utils::Logger

    @@applications = {"default" => Omnivore::Application}

    # @return [Hash(String, Omnivore::Application+)] registered application types
    def self.applications
      @@applications
    end

    macro inherited
      class_key = "{{@type.name}}".sub("Omnivore::Application::", "")
      snake_key = snake_case("{{@type.name}}".sub("Omnivore::Application::", ""))
      Omnivore::Application.applications[class_key] = {{@type.name.id}}
      Omnivore::Application.applications[snake_key] = {{@type.name.id}}
    end

    @halter : Channel::Buffered(Nil) = Channel(Nil).new(1)
    @starter : Channel::Buffered(Nil) = Channel(Nil).new(1)
    property active : Bool = false
    property configuration : Configuration
    property endpoints : Hash(String, Endpoint)

    # Create a new application instance
    #
    # @param configuration [Configuration]
    # @return [self]
    def initialize(@configuration : Configuration)
      @endpoints = {} of String => Endpoint
      setup_endpoints
    end

    # Start message consumption for this application
    #
    # @return [Nil]
    # @note this spawns the application
    def consume!
      info "Starting message consumption under application type - #{self.class.name}"
      if(active)
        warn "This application is already running! - #{self.class.name}"
      else
        debug "Spawning consumption to start application"
        spawn{ consume }
        debug "Waiting for application starter to notify"
        @starter.receive
        debug "Spawning for consumption is complete. All systems are go."
      end
      nil
    end

    # Start message consumption for this application
    #
    # @return [Nil]
    # @note this spawns the application
    def consume
      debug "Starting application endpoints"
      endpoints.values.each do |point|
        debug "Starting endpoint - #{point}"
        point.start!
      end
      info "Consumption active for application type - #{self.class.name}"
      @active = true
      @starter.send(nil)
      @halter.receive
      @active = false
      nil
    end

    # Halt message consumption for this application
    #
    # @return [Nil]
    def halt!
      warn "Halting application"
      endpoints.values.each do |point|
        debug "Stopping endpoint - #{point}"
        point.stop!
      end
      debug "Setting application to inactive"
      @halter.send(nil)
      nil
    end

    # Pass message to next endpoint
    #
    # @param msg [Message]
    # @return [self]
    def next_delivery(msg : Message)
      if(msg.get(:finalized, type: :string).nil?)
        target = next_endpoint(msg)
        if(target)
          spawn{ endpoint(target.to_s).transmit(msg) }
        else
          finalize_message(msg)
        end
        msg.confirm
        post_delivery(msg, target.to_s)
      else
        info "Message previously finalized. Cannot re-transmit. (`#{msg}`)"
      end
      self
    end

    # Determine next endpoint to send message. This default
    # implementation will pass to the endpoint named in the
    # payload target.
    #
    # @param msg [Message]
    # @return [String?] name of endpoint
    def next_endpoint(msg : Message) : String?
      result = msg.get(:target, type: :string)
      if(result)
        result.to_s
      end
    end

    # @return [Endpoint] get endpoint by name
    def endpoint(name)
      endpoints[name]
    end

    # Custom action to be run after message delivery
    #
    # @param msg [Message]
    # @param target [String] name of endpoint
    # @return [self]
    def post_delivery(msg : Message, target : String)
      self
    end

    # Apply any finalizations to message when delivery is complete
    #
    # @param msg [Message]
    # @param kind [Symbol] kind of finalization (:complete, :error)
    # @return [self]
    def finalize_message(msg : Message, kind : Symbol = :complete)
      finalizers = configuration.get(:finalizers, kind, type: :array)
      msg.set(:finalized, value: kind.to_s)
      unless(finalizers.nil?)
        finalizers.as(Array).each do |finalize_action|
          debug "Sending message to completion finalizer (#{kind}): #{finalize_action}"
          spawn{ endpoint(finalize_action.to_s).transmit(msg) }
        end
      end
      self
    end

    # Initialize all application endpoints
    #
    # @return [Nil]
    def setup_endpoints
      points = configuration.get(:endpoints, type: :hash)
      if(points)
        points = points.as(Hash(String, JSON::Type))
        points.each do |point_name, point_config|
          debug "Building new endpoint: #{point_name}"
          point_config = point_config.as(Hash(String, JSON::Type)).to_smash
          auto_confirm = point_config.get(:auto_confirm, type: :bool)
          if(auto_confirm.nil?)
            auto_confirm = false
          else
            auto_confirm = !!auto_confirm
          end
          new_point = Endpoint.new(self, point_name, auto_confirm)
          endpoints[point_name] = new_point
          info "New endpoint initialized - #{point_name} -> #{new_point}"
        end
      else
        warn "No endpoints detected"
      end
      nil
    end

  end
end

require "./application/*"
