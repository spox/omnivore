module Omnivore
  class Application
    class Star < Application

      # Determine next endpoint to send message.
      #
      # @param msg [Message]
      # @return [String] name of endpoint
      def next_endpoint(msg)
        star_name = configuration.get(:delivery, :star, :endpoint_name, type: :string).to_s
        star_name = "star" if star_name.empty?
        current_target = msg.get(:target, type: :string).to_s
        if(current_target == star_name)
          debug "Star processing on current message"
          points = msg.get(:delivery, :star, :path, type: :array)
          unless(points.nil?)
            points = points.as(Array(JSON::Type)).map{|point| point.to_s}
            e_name = points.shift
            if(e_name.nil?)
              msg.set(:target, value: nil)
            end
            msg.set(:delivery, :star, :path, value: points)
            debug "Star processing determined next endpoint: #{e_name}"
            e_name
          else
            debug "Star processing determined no new endpoints in path (complete)"
            msg.set(:target, value: nil)
            nil
          end
        elsif(!current_target.empty?)
          debug "Payload target is set as: #{current_target}. Enabling round trip."
          msg.set(:target, value: star_name)
          current_target
        else
          msg.set(:target, value: star_name)
          star_name
        end
      end

    end
  end
end
