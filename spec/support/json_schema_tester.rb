require 'json-schema'

class JsonSchemaTester
  SCHEMA_ROOT = File.join(File.dirname(__FILE__), '..', '..', 'schemas')

  def path_for(kind)
    "#{SCHEMA_ROOT}/#{kind}.json"
  end

  def validate_for!(kind, data)
    JSON::Validator.validate! path_for(kind), data
  end

end
