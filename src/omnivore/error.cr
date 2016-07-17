module Omnivore
  # Default error class
  class Error < Exception

    class NoApplication < Error
    end

    class TypeMismatch < Error
    end

  end
end
