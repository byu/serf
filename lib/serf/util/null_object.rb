module Serf
module Util

  ##
  # A simple NullOject pattern implementation for some Serf code that
  # assumes the existence of a logger.
  #
  class NullObject
    def method_missing(*args, &block)
      self
    end
  end

end
end
