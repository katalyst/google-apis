# frozen_string_literal: true

module Katalyst
  module GoogleApis
    class Error < StandardError
      attr_reader :code, :status

      def initialize(code:, status:, message:, details: nil)
        super(message)

        @code = code
        @status = status
        @details = details
      end

      def inspect
        %W[#<#{self.class.name}
           code=#{code.inspect}
           status=#{status.inspect}
           message=#{message.inspect}
           details=#{details.inspect}>].join(" ")
      end
    end
  end
end
