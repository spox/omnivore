module Omnivore
  class Source
    class Spec < Internal

      property spec_mailbox = Channel(Message).new

      # Fetch message from source
      #
      # @return [Message?]
      def receive
        result = super
        spec_mailbox.send(result) unless result.nil?
        result
      end

    end
  end
end
