require 'uuidtools'

module Serf
module Util

  ##
  # Helper module to include UUIDs as message fields.
  #
  module Uuidable

    def uuid
      @uuid ||= UUIDTools::UUID.random_create.to_s
    end

  end

end
end
