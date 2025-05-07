# frozen_string_literal: true

require "rails/engine"

module Katalyst
  module GoogleApis
    class Engine < ::Rails::Engine
      initializer "katalyst-google-apis.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap)
          app.config.importmap.paths << root.join("config/importmap.rb")
          app.config.importmap.cache_sweepers << root.join("app/javascript/controllers")
        end
      end

      initializer "katalyst-google-apis.forms" do |app|
        app.config.after_initialize do
          ActionView::Helpers::FormBuilder.include(Katalyst::GoogleApis::FormBuilder)
          if defined?(GOVUKDesignSystemFormBuilder)
            GOVUKDesignSystemFormBuilder::Builder.include(Katalyst::GoogleApis::GOVUKFormBuilder)
          end
        end
      end
    end
  end
end
