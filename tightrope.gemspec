lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tightrope/version"

Gem::Specification.new do |spec|
  spec.name          = "tightrope"
  spec.version       = Tightrope::VERSION
  spec.authors       = ["Andreas Leipelt"]
  spec.email         = ["andreas@leipelt-hamburg.de"]

  spec.summary       = %q{Rails ActionCable client library for use in non browser clients. Based on Eventmachine.}
  spec.description   = %q{tigthrope}
  spec.homepage      = "https://github.com/briareos62/tightrope"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #if spec.respond_to?(:metadata)
  #  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against " \
  #    "public gem pushes."
  #end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.files         = ['lib/tightrope.rb',
                        'lib/tightrope/version.rb',
                        'lib/tightrope/errors.rb',
                        'lib/tightrope/websocket/action_cable_client.rb',
                        'lib/tightrope/websocket/action_cable_auth_client.rb',
                        'lib/tightrope/websocket/filter_client.rb']

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "websocket-eventmachine-client", "~> 1.2"
  spec.add_runtime_dependency "http", "~> 3.0"
  spec.add_runtime_dependency "json"
end
