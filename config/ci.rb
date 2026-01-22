# frozen_string_literal: true

# Run using bin/ci

CI.run do
  step "Setup", "bin/setup"

  step "Style: Ruby", "bundle exec rubocop --no-server"

  step "Style: JS/CSS", "bundle exec rake prettier:lint"

  step "Security: Brakeman vulnerability audit", "bundle exec brakeman -q -w2"

  step "Tests: rspec", "bundle exec rspec"
end
