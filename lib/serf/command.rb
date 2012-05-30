require 'active_support/concern'
require 'active_support/core_ext/class/attribute'

require 'serf/util/error_handling'
require 'serf/util/options_extraction'
require 'serf/util/protected_call'
require 'serf/util/uuidable'

module Serf

  ##
  # A base class for Serf users to implement a Command pattern.
  #
  #   class MyCommand
  #     include Serf::Command
  #
  #     def initialize(*contructor_params, &block)
  #       # Do some validation here, or extra parameter setting with the args
  #       @model = opts :model, MyModel
  #     end
  #
  #     def call(request, context)
  #       # Do something w/ request, opts and context.
  #       item = @model.find request.model_id
  #       # create a new hashie of UUIDs, which we will use as the base
  #       # hash of our response
  #       response = create_uuids request
  #       response.kind = 'my_command/events/did_something'
  #       response.item = item
  #       return response
  #     end
  #   end
  #
  #   constructor_params = [1, 2, 3, 4, etc]
  #   block = Proc.new {}
  #   request = ::Hashie::Mash.new
  #   context = ::Hashie::Mash.new user: current_user
  #   MyCommand.call(request, context, *contructor_params, &block)
  #
  module Command
    extend ActiveSupport::Concern

    # Including Serf::Util::*... Order matters, kind of, here.
    include Serf::Util::Uuidable
    include Serf::Util::OptionsExtraction
    include Serf::Util::ProtectedCall
    include Serf::Util::ErrorHandling

    def call(request, context=nil *args, &block)
      raise NotImplementedError
    end

    module ClassMethods

      ##
      # Class method that both builds then executes the unit of work.
      #
      # @param request the request
      # @param context the context about the request. Things like the
      #   requesting :user for ACL.
      # @param *args remaining contructor arguments
      # @param &block the block to pass to constructor
      #
      def call(request, context=::Hashie::Mash.new, *args, &block)
        self.build(*args, &block).call(request, context)
      end

      ##
      # Factory build method that creates an object of the implementing
      # class' unit of work with the given parameters. By default,
      # This just calls the class new method.
      #
      def build(*args, &block)
        new *args, &block
      end

    end
  end
end
