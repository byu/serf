require 'serf/util/options_extraction'

module Serf
module Routing

  ##
  # An endpoint is the description of how to build a Unit of Work
  # for a given matched message. It builds an instance that
  # responds to the `call` method that will actually execute the work.
  # Units of work is built on every received message with the request,
  # given arguments, options (merged with serf infrastructure options)
  # and given block.
  #
  class Endpoint
    include Serf::Util::OptionsExtraction

    def initialize(connect, handler_factory, *args, &block)
      # If we want to connect serf options, then we try to extract
      # any possible options from the args list. If a hash exists at the
      # end of the args list, then we'll merge into it. Otherwise a new hash
      # will be added on.
      extract_options! args if @connect = connect

      @handler_factory= handler_factory
      @args = args
      @block = block
    end

    ##
    # Builds a Unit of Work object.
    #
    def build(env, serf_options={})
      # If we are connecting serf options, then we need to pass these
      # options on to the builder.
      if @connect
        @handler_factory.build(
          env.dup,
          *@args,
          options.merge(serf_options),
          &@block)
      else
        @handler_factory.build env.dup, *@args, &@block
      end
    end

  end

end
end
