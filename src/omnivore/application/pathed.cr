module Omnivore
  class Application
    class Pathed < Application

      # Determine next endpoint to send message.
      #
      # @param msg [Message]
      # @return [String] name of endpoint
      def next_endpoint(msg)
        points = msg.get(:delivery, :pathed, :path, type: :array)
        if(points.nil?)
          msg.set(:target, value: nil)
        else
          points = points.as(Array(JSON::Type)).map{|point| point.to_s}
          e_name = points.shift
          msg.set(:delivery, :pathed, :path, value: points)
          msg.set(:target, value: e_name)
        end
        super(msg)
      end

    end
  end
end
