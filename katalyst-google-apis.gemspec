# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "katalyst-google-apis"
  spec.version = "1.2.0"
  spec.authors = ["Katalyst Interactive"]
  spec.email   = ["developers@katalyst.com.au"]

  spec.summary = "Google REST APIs for use in Rails projects"
  spec.homepage = "https://github.com/katalyst/google-apis"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.files = Dir["{app,config,lib}/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "activesupport"
  spec.add_dependency "aws-sdk-core"
  spec.add_dependency "curb"
  spec.add_dependency "googleauth"
end
