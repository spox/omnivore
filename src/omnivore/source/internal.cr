module Omnivore
  class Source
    class Internal < Source

      property source_mailbox = Channel(String).new
      property connect_called : Bool = false
      property shutdown_called : Bool = false

      # Send message to source
      #
      # @param msg [Message]
      # @return [self]
      def transmit(msg : Message)
        payload = msg.data
        debug ">> #{payload.to_json}"
        source_mailbox.send(payload.to_json)
        self
      end

      # Fetch message from source
      #
      # @return [Message?]
      def receive
        debug "Waiting for new message"
        payload = source_mailbox.receive?
        until(payload || source_mailbox.closed?)
          source_mailbox.wait_for_receive
          payload = source_mailbox.receive?
        end
        if(payload)
          debug "<< #{payload}"
          payload = JSON.parse(payload).as_h.unsmash
          Message.new(payload, self)
        end
      end

      # Shutdown the source
      #
      # @return [self]
      def shutdown
        source_mailbox.close
        @shutdown_called = true
        self
      end

      # Connect the source (no-op)
      #
      # @return [self]
      def connect
        @connect_called = true
        self
      end

    end
  end
end
