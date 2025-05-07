# frozen_string_literal: true

require "aws-sdk-core"
require "googleauth"

module Katalyst
  module GoogleApis
    class Credentials < ::Google::Auth::ExternalAccount::AwsCredentials
      def initialize(**)
        super(Config.new(**).to_h)

        @aws_provider = ::Aws::CredentialProviderChain.new.resolve
      end

      # Override the default implementation that only supports EC2 credentials.
      def fetch_security_credentials
        # Note: Aws::CredentialProviderChain is a private API, but because it is
        # consumed directly by AWS utilities we assume it's stable.
        # This approach would not be required if Google's base class supported
        # resolving credentials from ECS environments.
        credentials = @aws_provider.credentials

        # Short-lived credentials for the AWS ECS instance role
        # These are used to authenticate the call to Google Cloud to authenticate
        # to the GC service account using OIDC based on the AWS ECS identity.
        {
          access_key_id:     credentials.access_key_id,
          secret_access_key: credentials.secret_access_key,
          session_token:     credentials.session_token,
        }
      end

      def region
        @region ||= case @aws_provider
                    when ::Aws::SSOCredentials
                      @aws_provider.client.config.region
                    else
                      ENV.fetch("AWS_REGION", nil)
                    end
      end

      class Config
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :scope, :string, default: "https://www.googleapis.com/auth/cloud-platform"
        attribute :service_account_email, :string
        attribute :project_number, :integer
        attribute :identity_pool, :string
        attribute :identity_provider, :string
        attribute :token_lifetime_seconds, :integer, default: 3600

        def audience
          ["//iam.googleapis.com", *{
            projects:              project_number,
            locations:             "global",
            workloadIdentityPools: identity_pool,
            providers:             identity_provider,
          }].join("/")
        end

        def service_account_impersonation_url
          ["https://iamcredentials.googleapis.com/v1", *{
            projects:        "-",
            serviceAccounts: "#{service_account_email}:generateAccessToken",
          }].join("/")
        end

        def regional_cred_verification_url
          "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15"
        end

        def subject_token_type
          "urn:ietf:params:aws:token-type:aws4_request"
        end

        def token_url
          "https://sts.googleapis.com/v1/token"
        end

        def universe_domain
          "googleapis.com"
        end

        def type
          "external_account"
        end

        def to_h
          {
            scope:,
            universe_domain:,
            type:,
            audience:,
            subject_token_type:,
            token_url:,
            service_account_impersonation_url:,
            service_account_impersonation:     { token_lifetime_seconds: },
            credential_source:                 { regional_cred_verification_url: },
          }
        end
      end
    end
  end
end
