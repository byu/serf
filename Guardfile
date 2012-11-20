guard(
    :rspec,
    cli: '--format Fuubar --color',
    all_on_start: true,
    all_after_pass: false) do

  # Watch our specs
  watch(%r{^spec/.+_spec\.rb$})

  # Watch our lib directory, and run the matching spec
  watch(%r{^lib/(.+)\.rb$}) { |m|
    "spec/#{m[1]}_spec.rb"
  }

end
