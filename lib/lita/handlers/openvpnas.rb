module Lita
  module Handlers
    class Openvpnas < Handler
      namespace 'Openvpnas'
      config :hostname, required: true, type: String
      config :ssh_user, required: false, type: String
      config :sacli_dir, required: false, type: String

      route(
        /(openvpn)\s+(otp)\s+(unlock)\s+(\S+)/i,
        :openvpn_as_otp_unlock,
        command: true,
        help: {
          'openvpn otp unlock <user>' => 'Unlock the OTP Authenticator for an OpenVPN AS user.'
        }
      )

      route(
        /(openvpn)\s+(active)\s+(users)/i,
        :openvpn_as_active_users,
        command: true,
        help: {
          'openvpn active users' => 'List the currently connected OpenVPN users.'
        }
      )

      def openvpn_as_otp_unlock(response)
        user = response.matches[0][3]
        ssh_user = config.ssh_user || 'lita'
        ssh_host = config.hostname
        path_to_sacli = config.sacli_dir || '/usr/local/openvpn_as/scripts'

        response.reply_with_mention t('replies.otp_unlock.working')

        command = "./sacli -u #{user} --lock 0 GoogleAuthLock 2>&1"
        exception = over_ssh(ssh_user, ssh_host, command, path_to_sacli)[1]

        if exception
          response.reply_with_mention t('replies.otp_unlock.failure')
          response.reply '/code ' + exception.message
        end

        # build a reply
        response.reply_with_mention t('replies.otp_unlock.success', user: user)
      end

      def openvpn_as_active_users(response)
        ssh_user = config.ssh_user || 'lita'
        ssh_host = config.hostname
        path_to_sacli = config.sacli_dir || '/usr/local/openvpn_as/scripts'

        response.reply_with_mention t('replies.active_users.working')

        command = './sacli VPNStatus 2>&1'
        result, exception = over_ssh(ssh_user, ssh_host, command, path_to_sacli)

        if exception
          response.reply_with_mention t('replies.active_users.failure')
          response.reply '/code ' + exception.message
        end

        # Figure out who is connected and what their client IP is
        clients = extract_clients(result.stdout)

        # build a reply
        response.reply_with_mention t('replies.active_users.failure', number: clients.size.to_s)
        response.reply '/code ' + clients.each { |client, ip| "#{client} @ #{ip}" }.join("\n")
      end

      private

      def extract_clients(json_data)
        clients = []
        JSON.parse(json_data).values.each do |data|
          data['client_list'].each do |client|
            clients << { user: client[0], ip: client[2] }
          end
        end
        clients
      end

      def over_ssh(user, host, command, cwd = '/tmp')
        exception = nil

        remote = Rye::Box.new(
          host,
          user: user,
          auth_methods: ['publickey'],
          password_prompt: false
        )

        result = begin
          Timeout.timeout(60) do
            remote.cd cwd
            # Need to use sudo
            remote.enable_sudo
            # scary...
            remote.disable_safe_mode

            remote.execute command
          end
        rescue Rye::Err => e
          exception = e
        rescue StandardError => e
          exception = e
        ensure
          remote.disconnect
        end
        [result, exception]
      end

      Lita.register_handler(self)
    end
  end
end
