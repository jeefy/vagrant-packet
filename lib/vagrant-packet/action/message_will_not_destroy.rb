# frozen_string_literal: true

module VagrantPlugins
  module Packet
    module Action
      class MessageWillNotDestroy
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t('vagrant_packet.will_not_destroy', name: env[:machine].name))
          @app.call(env)
        end
      end
    end
  end
end
