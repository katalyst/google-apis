# Katalyst::GoogleApis

Katalyst Google APIs provides a simple interface for integrating Google REST
APIs into Rails projects, with built-in support for AWS ECS OIDC authentication
and Recaptcha validation.

This project is an alternative approach to using the gRPC libraries provided by
Google, which require specific fork behaviour that (as of 2025) are
[not compatible with puma](https://github.com/puma/puma/issues/3503).

## Installation

Install the gem as usual

```ruby
gem "katalyst-google-apis"
```

## Usage

Configure your google service account and project in an initializer:

```ruby
Katalyst::GoogleApis.configure do |config|
  config.project_id            = "prj-..."
  config.project_number        = "..."
  config.service_account_email = ENV.fetch("GOOGLE_SERVICE_ACCOUNT_EMAIL", "sa-...@....iam.gserviceaccount.com")
  config.identity_pool         = "...-pool"
  config.identity_provider     = "...-provider"

  # Recaptcha configuration
  # site_keys appear in the frontend, they white-list domains so do not need to be kept secret
  config.recaptcha.site_key = ENV.fetch("RECAPTCHA_SITE_KEY", "...")
end
```

These can also be configured using ENV variables, see Katalyst::GoogleApis::Config for details.

### Enterprise Recaptcha

Add a token field and validation to your model:

```ruby
attr_accessor :recaptcha_token
validates :recaptcha_token, recaptcha: true, on: :create
```

Add to permitted params in your controller, and add the field to your views:

```erb
<%= form.govuk_recaptcha_field :recaptcha_token %>
```

Test by adding `require "katalyst/google_apis/matchers"` to your `spec/rails_helpers.rb`.

You can test any or all of the following in your model:

```ruby
  it { is_expected.to validate_recaptcha_for(:recaptcha_token, expected: :recaptcha_blank).on(:create) }
  it { is_expected.to validate_recaptcha_for(:recaptcha_token, expected: :recaptcha_invalid).on(:create) }
  it { is_expected.to validate_recaptcha_for(:recaptcha_token, expected: :recaptcha_action_mismatch).on(:create) }
  it { is_expected.to validate_recaptcha_for(:recaptcha_token, expected: :recaptcha_suspicious).on(:create) }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. We do not
currently have a dummy app and specs, so test against an existing project.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/katalyst/google-apis.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
