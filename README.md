# lita-openvpnas

A [Lita](https://www.lita.io/) handler plugin for some basic [OpenVPN Access Server](https://openvpn.net/index.php/access-server/overview.html) operations.

## Installation

Add lita-openvpnas to your Lita instance's Gemfile:

``` ruby
gem "lita-openvpnas"
```

## Configuration

* `config.handlers.openvpnas.hostname` - OpenVPN Access Server hostname
* `config.handlers.openvpnas.sacli_dir` - Path to the directory containing the `sacli` utility on the OpenVPN Access Server
  * Defaults to `/usr/local/openvpn_as/scripts`
* `config.handlers.openvpnas.ssh_user` - SSH user to connect to OpenVPN Access Server
  * Defaults to `lita`

## Usage

#### Unlock the Google Authenticator for a User
    openvpn otp unlock <user>

#### List Currently Connected VPN users
    openvpn active users
