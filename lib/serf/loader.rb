require 'serf/loader/loader'

module Serf

  module Loader

    ##
    # @see Serf::Loader::Loader
    #
    def self.serfup(serfup, base_path)
      Serf::Loader::Loader.new.serfup serfup, base_path
    end

  end

end
