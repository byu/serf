require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/blank'
require 'active_support/ordered_options'

require 'serf/error'

module Serf

  module Handler
    extend ActiveSupport::Concern

    included do
      # In the class that includes this module, we're going to
      # create an inheritable class attribute that will store
      # our mappings between messages and the methods to call.
      class_attribute :serf_actions
      send(
        'serf_actions=',
        ActiveSupport::InheritableOptions.new)

      def self.inherited(kls) #:nodoc:
        super
        # Sets the current subclass class attribute to be an
        # inheritable copy of the superclass options.
        kls.send(
          'serf_actions=',
          self.serf_actions.inheritable_copy)
      end

    end

    module InstanceMethods

      ##
      # Rack-like call. It receives an environment hash, which we
      # assume is a message.
      #
      def call(env={})
        # Just to stringify the environment keys
        env = env.symbolize_keys
        # Make sure a kind was set, and that we can handle it.
        message_kind = env[:kind]
        raise ArgumentError, 'No "kind" in call env' if message_kind.blank?
        method = self.class.serf_actions[message_kind]
        raise ArgumentError, "#{message_kind} not found" if method.blank?
        # Now execute the method with the environment parameters
        self.send method, env
      rescue => e
        e.extend ::Serf::Error
        raise e
      end
    end

    module ClassMethods

      ##
      # registers a method to handle the receipt of a message type.
      # @param *args splat list of message kinds
      # @options opts [Symbol] :with The method to call.
      #
      def receives(*args)
        options = args.last.kind_of?(Hash) ? args.pop : {}
        exposed_method = options[:with]
        raise ArgumentError, 'Missing "with" option' if exposed_method.blank?
        args.each do |kind|
          raise ArgumentError, 'Blank kind' if kind.blank?
          self.serf_actions[kind] = exposed_method
        end
      end

    end

  end

end
