require 'serf/util/options_extraction'
require 'serf/util/protected_call'
require 'serf/util/uuidable'

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
  #     def call(headers, message)
  #       # Do something w/ message, opts and headers.
  #       # Our headers and message are the simple data structures
  #       # for the Interactor's "Request".
  #
  #       item = @model.find message.model_id
  #
  #       # Make a simple data structure as the Interactor "Response".
  #       response = Hashie::Mash.new
  #       response.item = item
  #       # Return the response 'kind' and the response data.
  #       return 'my_app/events/did_something', response
  #     end
  #   end
  #
  #   constructor_params = [1, 2, 3, 4, etc]
  #   block = Proc.new {}
  #   message = ::Hashie::Mash.new
  #   headers = ::Hashie::Mash.new user: current_user
  #   MyInteractor.call(headers, message, *contructor_params, &block)
  #
  module Interactor
    # Including Serf::Util::*... Order matters, kind of, here.
    include Serf::Util::OptionsExtraction
    include Serf::Util::ProtectedCall

    def self.included(base)
      base.extend(ClassMethods)
    end

    def call(headers, message, *args, &block)
      raise NotImplementedError
    end

    module ClassMethods

      ##
      # Class method that both builds then executes the interactor.
      #
      # @param headers the headers about the message. Things like the
      #   requesting :user for ACL.
      # @param message the message
      # @param *args remaining contructor arguments
      # @param &block the block to pass to constructor
      #
      def call(headers, message, *args, &block)
        self.build(*args, &block).call(headers, message)
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
