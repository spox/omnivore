module Omnivore
  class Message

    property identifier : String
    property source : Source
    property confirmed : Bool = false
    property confirmation_waiter = Mutex.new

    @confirmation_channel = Channel(Bool).new(1)

    include Crogo::Utils::HashyJson

    # Create new instance using payload
    #
    # @param data [Hash(String, JSON::Type)] payload data
    # @param source [Source]
    # @return [self]
    def initialize(base_data : Hash, @source : Source)
      base_data = base_data.unsmash
      @data = base_data
      @identifier = SecureRandom.uuid
      payload_id = get(:id, type: :string).to_s
      if(payload_id.empty?)
        @data["id"] = @identifier
      else
        @identifier = payload_id
      end
      locker_init
    end

    # Create a new instance
    #
    # @param source [Source]
    # @return [self]
    def initialize(@source : Source)
      @identifier = SecureRandom.uuid
      @data = {} of String => JSON::Type
      set(:id, value: @identifier)
      locker_init
    end

    def locker_init
      spawn do
        confirmation_waiter.lock
        result = @confirmation_channel.receive?
        until(result || @confirmation_channel.closed?)
          result = @confirmation_channel.receive?
        end
        confirmation_waiter.unlock
      end
    end

    # @return [Bool] message has been confirmed with source
    def confirmed?
      @confirmed
    end

    # Confirm message from source
    def confirm
      source.confirm(self)
      @confirmed = true
      @confirmation_channel.send(true)
      nil
    end

    def confirm_wait
      confirmation_waiter.synchronize do
        until(confirmed?)
          Fiber.yield
        end
      end
    end

    # Touch message on source
    def touch
      source.touch(self)
    end

    def to_s(io)
      io << "<" << self.class.name << ":" << identifier << ">"
    end

  end
end
