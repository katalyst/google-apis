# frozen_string_literal: true

module Katalyst
  module GoogleApis
    class Error < StandardError
      attr_reader :code, :status

      def initialize(code:, status:, message:)
        super(message)

        @code = code
        @status = status
      end

      def inspect
        "#<#{self.class.name} code=#{code.inspect} status=#{status.inspect} message=#{message.inspect}>"
      end
    end
  end
end
