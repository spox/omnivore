module Omnivore
  class Action
    class Test < Action

      # Execute test action on message
      #
      # @return [Nil]
      def execute
        if(message.get(:data, :test, :value, type: :string) == "testing")
          message.set(:target, value: nil)
          message.set(:data, :test, :target_unset, value: true)
        else
          message.set(:data, :test, :value, value: "testing")
        end
        nil
      end

    end
  end
end
