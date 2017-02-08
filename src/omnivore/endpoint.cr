module Omnivore
  # Endpoints receive messages from source(s) and process
  # messages through defined actions
  class Endpoint

    include Omnivore::Utils::Logger

    property name : String
    property application : Application
    property sources : Array(Source)
    property actions = [Omnivore::Action]
    property processors = {"pre" => [Omnivore::Processor], "post" => [Omnivore::Processor]}
    property auto_confirm : Bool
    property processing : Bool
    property mailbox : Channel::Buffered(Message | Exception)

    # Create a new instance
    #
    # @param application [Application] application this endpoint belongs to
    # @param name [String] name of endpoint
    # @param auto_confirm [Bool] automatically confirm received messages
    # @return [self]
    def initialize(@application : Application, @name : String, @auto_confirm : Bool = false)
      @processing = false
      @mailbox = Channel(Message | Exception).new(1)
      @sources = Array(Source).new
      @actions.clear
      @processors["pre"].clear
      @processors["post"].clear
      load_sources
      load_actions
      load_processors
    end

    # @return [Configuration] endpoint configuration
    def config
      result = application.configuration.get(:endpoints, name, :config, type: :hash)
      if(result.nil?)
        result = {} of String => JSON::Type
      else
        result = result.as(Hash(String, JSON::Type))
      end
      Configuration.new(result)
    end

    # Load any actions defined for this endpoint within configuration
    #
    # @return [Nil]
    def load_actions
      action_names = application.configuration.get(
        "endpoints", name, "actions", type: :array
      )
      if(action_names)
        action_names.as(Array).each do |a_name|
          new_action = Omnivore::Action.actions[a_name.to_s]
          actions << new_action
          debug "Registered action: #{new_action}"
        end
      end
      nil
    end

    # Load all sources defined for this endpoint within configuration
    #
    # @return [nil]
    def load_sources
      e_sources = application.configuration.get(:endpoints, name, :sources, type: :array)
      if(e_sources)
        e_sources = e_sources.as(Array(JSON::Type))
        e_sources.each do |src_config|
          src_config = src_config.as(Hash(String, JSON::Type))
          new_source = Source.sources[src_config["type"].to_s].new(
            src_config["name"].to_s, mailbox, Configuration.new(src_config)
          )
          sources << new_source
          debug "New source: #{new_source}"
        end
      end
      nil
    end

    # Load any processors defined for this endpoint within configuration
    #
    # @return [Nil]
    def load_processors
      processor_names = application.configuration.get(
        "endpoints", name, "processors", type: :hash
      )
      if(processor_names)
        processor_names = processor_names.as(Hash(String, JSON::Type))
        ["pre", "post"].each do |p_key|
          unless(processor_names[p_key]?.nil?)
            processor_names[p_key].as(Array).each do |p_name|
              new_processor = Omnivore::Processor.processors[p_name.to_s]
              processors[p_key] << new_processor
              debug "Registered #{p_key} processor: #{new_processor}"
            end
          end
        end
      end
      nil
    end

    # Send a message to this endpoint
    #
    # @param msg [Message]
    # @return [Bool]
    def transmit(msg : Message)
      src = sources.first
      if(src)
        src.transmit(msg)
        true
      else
        raise "No sources registered for this endpoint"
      end
    end

    # Start the endpoint which will cause message consumption to begin
    #
    # @return [Bool] endpoint started
    def start!
      if(!actions.empty? || config.get(:force_processing, type: :bool))
        unless(processing)
          @processing = true
          sources.each do |src|
            debug "Starting source - #{src}"
            src.start
          end
          spawn do
            while(processing)
              debug "Waiting for new message from sources"
              c_msg = mailbox.receive?
              unless(c_msg.nil?)
                if(c_msg.is_a?(Message))
                  handle_message(c_msg)
                else
                  error "Unexpected exception received from source. Halting application!"
                  error "Exception received from source: #{c_msg.class}: #{c_msg}"
                  application.halt!
                end
              end
            end
          end
          true
        else
          warn "Processing already enabled. Not starting as already started."
          false
        end
      else
        warn "Processing not enabled for endpoint. No actions available for processing."
        false
      end
    end

    # Stop the endpoint from processing messages
    #
    # @return [Bool] endpoint stopped
    def stop!
      if(processing)
        @processing = false
        debug "Closing mailbox"
        mailbox.close
        debug "Stopping all sources"
        sources.each do |src|
          debug "Stopping #{src}"
          src.stop
        end
        debug "Endpoint is stopped"
        true
      else
        warn "Processing not enabled. Not stopping as already stopped."
        false
      end
    end

    # Handle a new message by running it through all configured
    # processors and actions
    #
    # @param msg [Message]
    # @return [self]
    def handle_message(msg : Message)
      debug "New message received - `#{msg}`"
      apply_processors("pre", msg)
      success = true
      complete_notifiers = Channel(Bool).new(actions.size)
      actions.each do |action_klass|
        action = action_klass.new(msg, self)
        spawn do
          begin
            action.execute if action.valid?
            complete_notifiers.send(true)
          rescue e
            error "Unexpected error encountered! #{e.class} - #{e.message}"
            debug "#{e.backtrace.join("\n")}"
            success = false
            complete_notifiers.send(true)
          end
        end
      end
      completed = [] of Bool
      until(completed.size == actions.size)
        result = complete_notifiers.receive?
        completed << result if result
      end
      if(success)
        apply_processors("post", msg)
        debug "Sending message to application for handling - `#{msg}`"
        application.next_delivery(msg)
      else
        error "Halting delivery due to previous error - `#{msg}`"
        application.finalize_message(msg, :error)
      end
      self
    end

    # Apply processor to message
    #
    # @param type [String] processor type (pre or post)
    # @param msg [Message] message to process
    # @return [Message]
    def apply_processors(type : String, msg : Message) : Message
      processors[type].each do |klass|
        processor = klass.new(msg, self)
        processor.apply if processor.apply?
      end
      msg
    end

  end
end
