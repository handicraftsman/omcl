# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omcl/version'

Gem::Specification.new do |spec|
  spec.name          = "omcl"
  spec.version       = OMCL::VERSION
  spec.authors       = ["Nickolay"]
  spec.email         = ["nickolay02@inbox.ru"]

  spec.summary       = %q{Open-Source Minecraft Launcher}
  spec.description   = %q{Open-Source Minecraft Launcher for *nixes}
  spec.homepage      = "https://github.com/handicraftsman/omcl"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "rubygoods", "~> 0.0.0.12"
end
