module Omnivore
  class Action
    class Test
      class Chain < Action

        # Execute test action on message
        #
        # @return [Nil]
        def execute
          next_target = config.get(:target, type: :string)
          if(next_target.nil?)
            next_target = "test"
          end
          message.set(:target, value: next_target.to_s)
          nil
        end

      end
    end
  end
end
