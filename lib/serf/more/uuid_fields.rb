require 'serf/util/uuidable'

module Serf
module More

  ##
  # Assumes that Virtus has already been included in the class that
  # also includes UuidFields.
  #
  module UuidFields
    extend Serf::Util::Uuidable

    def self.included(base)
      base.attribute :uuid, String, default: lambda { |o,a| create_coded_uuid }
      base.attribute :parent_uuid, String
      base.attribute :origin_uuid, String
    end

    def create_child_uuids
      {
        uuid: UuidFields.create_coded_uuid,
        parent_uuid: uuid,
        origin_uuid: (origin_uuid || parent_uuid || uuid)
      }
    end
  end

end
end
