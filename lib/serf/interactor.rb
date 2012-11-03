require 'serf/util/options_extraction'
require 'serf/util/protected_call'

module Serf

  ##
  # A base module so Interactors are implemented with a uniform "interface".
  #
  #   require 'hashie'
  #   require 'serf/interactor'
  #
  #   class MyInteractor
  #     include Serf::Interactor
  #
  #     def initialize(*contructor_params, &block)
  #       # Do some validation here, or extra parameter setting with the args
  #       @model = opts :model, MyModel
  #     end
  #
  #     def call(message)
  #       # Do something w/ the message and opts.
  #       # Simple data structures for the Interactor's "Request".
  #
  #       item = @model.find message.model_id
  #
  #       # Make a simple data structure as the Interactor "Response".
  #       response = Hashie::Mash.new
  #       response.item = item
  #       # Return the response 'kind' and the response data.
  #       return response, 'my_app/events/did_something'
  #     end
  #   end
  #
  #   constructor_params = [1, 2, 3, 4, etc]
  #   block = Proc.new {}
  #   message = ::Hashie::Mash.new model_id: 1
  #   response, kind = MyInteractor.call(message, *contructor_params, &block)
  #
  module Interactor
    include Serf::Util::OptionsExtraction
    include Serf::Util::ProtectedCall

    def self.included(base)
      base.extend(ClassMethods)
    end

    def call(*args, &block)
      raise NotImplementedError
    end

    module ClassMethods

      ##
      # Class method that both builds then executes the interactor.
      #
      # @param message the raw simple data structure of the request
      # @param *args remaining contructor arguments
      # @param &block the block to pass to constructor
      #
      def call(message, *args, &block)
        build(*args, &block).call(message)
      end

      ##
      # Factory build method that creates an object of the implementing
      # interactor with the given parameters. By default,
      # This just calls the class new method.
      #
      def build(*args, &block)
        new *args, &block
      end

    end
  end
end
