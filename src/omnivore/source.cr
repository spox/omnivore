module Omnivore
  # Sources for receiving and transmitting messages
  abstract class Source

    include Omnivore::Utils::Logger

    @@sources = {"raw" => Omnivore::Source}

    # @return [Hash(String, Omnivore::Source+)] registered source types
    def self.sources
      @@sources
    end

    macro inherited
      class_key = "{{@type.name}}".sub("Omnivore::Source::", "")
      snake_key = snake_case("{{@type.name}}".sub("Omnivore::Source::", ""))
      Omnivore::Source.sources[class_key] = {{@type.name.id}}
      Omnivore::Source.sources[snake_key] = {{@type.name.id}}
    end

    property name : String
    property mailbox : Channel::Buffered(Message | Exception)
    property consuming : Bool
    property config : Configuration

    # Create a new instance
    #
    # @param name [String] name of source
    # @param mailbox [Channel::Buffered(Message)]
    # @return [self]
    def initialize(@name : String, @mailbox : Channel::Buffered(Message | Exception), @config : Configuration = Configuration.new)
      @consuming = false
      setup
    end

    # Start the source
    #
    # @return [Bool] source was started
    def start : Bool
      debug "Starting up source"
      if(consuming)
        warn "Source is currently in consume state. No action taken."
        false
      else
        connect
        @consuming = true
        debug "Enabling message processing"
        spawn do
          process
        end
        true
      end
    end

    # Stop the source
    #
    # @return [Bool] source was stopped
    def stop : Bool
      if(consuming)
        debug "Stopping running source"
        @consuming = false
        shutdown
        debug "Source has been stopped"
        true
      else
        debug "Stop request for non-running source. Ignored."
        false
      end
    end

    # @return [Bool] currently running
    def consuming?
      @consuming
    end

    # Actions to run on source setup
    #
    # @return [self]
    def setup : Source
      self
    end

    # Actions to run for connecting source
    #
    # @return [self]
    def connect : Source
      self
    end

    # Actions to run for shutting down source
    #
    # @return [self]
    def shutdown : Source
      self
    end

    # Receive new message from source
    #
    # @return [Message]
    abstract def receive : Message?

    # Transmit message to source
    #
    # @param msg [Message]
    # @return [self]
    abstract def transmit(msg : Message) : Source

    # Touch message to prevent timeout on long processing
    #
    # @param msg [Message]
    # @return [self]
    def touch(msg : Message) : Source
      self
    end

    # Confirm message has been successfully processed
    #
    # @param msg [Message]
    # @return [self]
    def confirm(msg : Message) : Source
      self
    end

    # Start receiving messages from the source
    def process
      while(consuming)
        begin
          msg = receive
          if(msg)
            debug "Received new message for processing `#{msg}`"
            mailbox.send(msg)
          end
        rescue e
          error "Message receive error - #{e.class}: #{e}"
          begin
            mailbox.send(e)
          rescue Channel::ClosedError
            debug "Mailbox has been closed. Error message not delivered."
          end
        end
      end
    end

  end
end

require "./source/*"
