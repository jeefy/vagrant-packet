# frozen_string_literal: true

require 'log4r'
require 'vagrant/util/retryable'
require 'vagrant-packet/util/timer'

module VagrantPlugins
  module Packet
    module Action
      # This starts a stopped instance.
      class StartInstance
        include Vagrant::Util::Retryable

        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_packet::action::start_instance')
        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          server = env[:packet_compute].devices.get(env[:machine].id)

          env[:ui].info(I18n.t('vagrant_packet.starting'))

          begin
            server.start

            # Wait for the instance to be ready first
            env[:metrics]['instance_ready_time'] = Util::Timer.time do
              tries = env[:machine].provider_config.instance_ready_timeout / 2

              env[:ui].info(I18n.t('vagrant_packet.waiting_for_ready'))
              begin
                retryable(on: Fog::Errors::TimeoutError, tries: tries) do
                  # If we're interrupted don't worry about waiting
                  next if env[:interrupted]

                  # Wait for the server to be ready
                  server.wait_for(2) { ready? }
                end
              rescue Fog::Errors::TimeoutError
                raise Errors::InstanceReadyTimeout, timeout: env[:machine].provider_config.instance_ready_timeout
              end
            end
          rescue Fog::Compute::Packet::Error => e
            raise Errors::FogError, message: e.message
          end

          @logger.info("Time to instance ready: #{env[:metrics]['instance_ready_time']}")

          unless env[:interrupted]
            env[:metrics]['instance_ssh_time'] = Util::Timer.time do
              # Wait for SSH to be ready.
              env[:ui].info(I18n.t('vagrant_packet.waiting_for_ssh'))
              loop do
                # If we're interrupted then just back out
                break if env[:interrupted]
                break if env[:machine].communicate.ready?
                sleep 2
              end
            end

            @logger.info("Time for SSH ready: #{env[:metrics]['instance_ssh_time']}")

            # Ready and booted!
            env[:ui].info(I18n.t('vagrant_packet.ready'))
          end

          @app.call(env)
        end
      end
    end
  end
end
