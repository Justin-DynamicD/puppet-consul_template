# == Class consul_template::params
#
# This class is meant to be called from consul_template.
# It sets variables according to platform.
#
class consul_template::params {

  $install_method     = 'url'
  $log_level          = 'info'
  $package_name       = 'consul-template'
  $package_ensure     = 'latest'
  $version            = '0.19.3'
  $download_url_base  = 'https://releases.hashicorp.com/consul-template'
  $download_checksum  = '47b3f134144b3f2c6c1d4c498124af3c4f1a4767986d71edfda694f822eb7680'
  $download_type      = 'sha256'
  $download_extension = 'zip'
  $user               = 'root'
  $group              = 'root'
  $manage_user        = false
  $manage_group       = false
  $config_mode        = '0660'
  $kill_signal        = 'SIGTERM'
  $reload_signal      = 'SIGHUP'

  case $::architecture {
    'x86_64', 'amd64': { $arch = 'amd64' }
    'i386':            { $arch = '386'   }
    default:           { fail("Unsupported kernel architecture: ${::architecture}") }
  }

  $os = downcase($::kernel)

  $init_style = $::operatingsystem ? {
    'Ubuntu'        => $::lsbdistrelease ? {
      '8.04'  => 'debian',
      '15.04' => 'systemd',
      '16.04' => 'systemd',
      default => 'upstart'
    },
    /CentOS|RedHat/ => $::operatingsystemmajrelease ? {
      /(4|5|6)/ => 'sysv',
      default   => 'systemd',
    },
    'Fedora'        => $::operatingsystemmajrelease ? {
      /(12|13|14)/ => 'sysv',
      default      => 'systemd',
    },
    'Debian'        =>  $::operatingsystemmajrelease ? {
      /(4|5|6|7)/ => 'debian',
      default     => 'systemd'
    },
    default => 'sysv'
  }
}
