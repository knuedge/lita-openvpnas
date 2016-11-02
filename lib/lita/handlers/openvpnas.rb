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
          "openvpn otp unlock <user>" => "Unlock the OTP Authenticator for an OpenVPN AS user."
        }
      )

      def openvpn_as_otp_unlock(response)
        user = response.matches[0][3]
        ssh_user = config.ssh_user || 'lita'
        ssh_host = config.hostname
        path_to_sacli = config.sacli_dir || '/usr/local/openvpn_as/scripts'
        username = response.user.name.split(/\s/).first

        response.reply("#{username}, let me unlock that user's OpenVPN authenticator for you.")

        exception = nil

        remote = Rye::Box.new(
          ssh_host,
          user: ssh_user,
          auth_methods: ['publickey'],
          password_prompt: false
        )

        result = begin
          Timeout::timeout(60) do
            remote.cd 'path_to_sacli'
            # Need to use sudo
            remote.enable_sudo
            # scary...
            remote.disable_safe_mode

            remote.execute "./sacli -u #{user} --lock 0 GoogleAuthLock 2>&1"
          end
        rescue Rye::Err => e
          exception = e
        rescue StandardError => e
          exception = e
        ensure
          remote.disconnect
        end

        if exception
          response.reply_with_mention "That OpenVPN authenticator didn't seem to unlock... ;-("
          response.reply "/code " + exception.message
        end

        # build a reply
        response.reply_with_mention("That OpenVPN authenticator is now available for #{user}!")
      end

      Lita.register_handler(self)
    end
  end
end
