require 'active_model'
require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module Serf

  ##
  # A module to represent a message that we're transporting over
  # the wire. This is mainly for commands and events in ED-SOA.
  # Optional, but useful for validations, etc.
  #
  module Message
    extend ActiveSupport::Concern
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations

    included do
      class_attribute :kind
      send 'kind=', self.to_s.tableize.singularize
      self.include_root_in_json = false
    end

    module InstanceMethods

      def attributes
        {
          :kind => kind
        }
      end

      def kind
        self.class.kind
      end

      def to_msgpack
        attributes.to_msgpack
      end

    end

    module ClassMethods

      def parse(*args)
        self.new *args
      end

    end

  end

end
