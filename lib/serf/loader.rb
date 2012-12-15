require 'serf/loader/loader'

module Serf

  module Loader

    ##
    # @see Serf::Loader::Loader
    #
    def self.serfup(*args)
      Serf::Loader::Loader.new.serfup *args
    end

  end

end
