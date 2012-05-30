module Serf
module Util

  ##
  # Rescues exceptions raised when calling blocks.
  #
  module ProtectedCall

    ##
    # A block wrapper to catch errors when executing a block. Instead of
    # raising the error, the error is caught and returned in place of
    # the block's results.
    #
    #   ok, results = protected_call do
    #     1 + 1
    #   end
    #   => [true, 2]
    #
    #   ok, results = protected_call do
    #     raise 'My Error'
    #   end
    #   => [false, RuntimeError]
    #
    # @return boolean success and the block's (or caught exception) results.
    #
    def pcall(*args)
      return true, yield(*args)
    rescue => e
      return false, e
    end
    alias_method :protected_call, :pcall

  end

end
end
