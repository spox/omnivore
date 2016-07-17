module Omnivore
  # Processor to apply to message
  class Processor
    # Test processor
    class Test < Processor

      # @return [Bool] apply processor
      def apply?
        !message.get(:data, :process, type: :bool).nil?
      end

      # Apply the processor logic to message
      #
      # @return [Message]
      def apply
        message.set(:data, :processor, :test, value: "set")
      end

    end
  end
end
