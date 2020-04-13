# frozen_string_literal: true

require 'fog-packet'
require 'log4r'
require 'pp'

module VagrantPlugins
  module Packet
    module Action
      # This action connects to Packet, verifies credentials work, and
      # puts the Packet connection object into the `:packet_compute` key
      # in the environment.
      class ConnectPacket
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_packet::action::connect_packet')
        end

        def call(env)
          @logger.info('Connecting to Packet...')

          # TODO: [fog][DEPRECATION] Unable to load Fog::Packet::Compute. This must be changed at Fog and updated here accordingly
          env[:packet_compute] = Fog::Compute::Packet.new(packet_token: env[:machine].provider_config.packet_token)

          @app.call(env)
        end
      end
    end
  end
end
