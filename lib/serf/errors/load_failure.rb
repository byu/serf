module Serf
module Errors

  ##
  # An error occurred while loading serfs.
  #
  class LoadFailure < RuntimeError
    attr_accessor :cause

    def initialize(message=nil, cause=nil)
      @cause = cause
      super(message)
    end
  end

end
end
