require 'factory_girl'
require 'hashie'
require 'securerandom'

FactoryGirl.define do
  sequence(:random_string) { SecureRandom.hex }

  factory :empty_parcel, class: Hashie::Mash do
    message {{
    }}
  end

  factory :random_hash, class: Hashie::Mash do
    option_a { generate(:random_string) }
  end

  factory :random_parcel, class: Hashie::Mash do
    kind            { generate(:random_string) }
    uuid            { generate(:random_string) }
    origin_uuid     { generate(:random_string) }
    parent_uuid     { generate(:random_string) }
    random_header_a { generate(:random_string) }
    message {{
      some_data: generate(:random_string)
    }}
  end

  factory :random_headers, class: Hashie::Mash do
    kind            { generate(:random_string) }
    uuid            { generate(:random_string) }
    origin_uuid     { generate(:random_string) }
    parent_uuid     { generate(:random_string) }
    random_header_a { generate(:random_string) }
  end
end
