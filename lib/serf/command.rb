require 'active_support/concern'

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
  #     def call(headers, message)
  #       # Do something w/ message, opts and headers.
  #       item = @model.find message.model_id
  #       # create a new hashie of UUIDs, which we will use as the base
  #       # hash of our response
  #       response = create_uuids message
  #       response.kind = 'my_command/events/did_something'
  #       response.item = item
  #       return response
  #     end
  #   end
  #
  #   constructor_params = [1, 2, 3, 4, etc]
  #   block = Proc.new {}
  #   message = ::Hashie::Mash.new
  #   headers = ::Hashie::Mash.new user: current_user
  #   MyCommand.call(headers, message, *contructor_params, &block)
  #
  module Command
    extend ActiveSupport::Concern

    # Including Serf::Util::*... Order matters, kind of, here.
    include Serf::Util::Uuidable
    include Serf::Util::OptionsExtraction
    include Serf::Util::ProtectedCall

    def call(headers, message, *args, &block)
      raise NotImplementedError
    end

    module ClassMethods

      ##
      # Class method that both builds then executes the unit of work.
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
      # class' unit of work with the given parameters. By default,
      # This just calls the class new method.
      #
      def build(*args, &block)
        new *args, &block
      end

    end
  end
end
