require 'serf/loader/loader'

module Serf

  module Loader

    ##
    # @see Serf::Loader::Loader
    #
    def self.serfup(config, *args)
      Serf::Loader::Loader.new.serfup config, *args
    end

  end

end
