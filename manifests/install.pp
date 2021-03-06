# == Class consul_template::intall
#
class consul_template::install {

  #Create folder structure
  if ! empty($::consul_template::data_dir) {
    file { $::consul_template::data_dir:
      ensure => 'directory',
      owner  => $::consul_template::user,
      group  => $::consul_template::group,
      mode   => '0755',
    }
  }
  file {
    "${::consul_template::bin_dir}":
      ensure => 'directory',
      owner  => $::consul_template::user,
      group  => $::consul_template::group,
      mode   => '0755';
    "${::consul_template::template_dir}":
      ensure => 'directory',
      owner  => $::consul_template::user,
      group  => $::consul_template::group,
      mode   => '0755';
  }

  #Install binary
  if $::consul_template::install_method == 'url' {

    $ctzipname = "consul-template_${::consul_template::version}_${::consul_template::os}_${::consul_template::arch}.${::consul_template::download_extension}"
    $ctcompleteurl = "${::consul_template::download_url_base}/${::consul_template::version}/$ctzipname"

    archive { $ctzipname :
      path          => "/tmp/${ctzipname}",
      source        => $ctcompleteurl,
      checksum      => $::consul_template::download_checksum,
      checksum_type => $::consul_template::download_type,
      extract       => true,
      extract_path  => $::consul_template::bin_dir,
      creates       => "${::consul_template::bin_dir}/consul-template",
      cleanup       => true,
      user          => $::consul_template::user,
      group         => $::consul_template::group,
      require       => File['/etc/consul-template'],
    }
    if $::consul_template::link_dir != $::consul_template::bin_dir {
      file { "${::consul_template::link_dir}/consul-template" :
        ensure  => link,
        target  => "${::consul_template::bin_dir}/consul-template",
        require => Archive["${ctzipname}"],
      }
    }

  } elsif $::consul_template::install_method == 'package' {

    package { $::consul_template::package_name:
      ensure => $::consul_template::package_ensure,
    }

  } else {
    fail("The provided install method ${::consul_template::install_method} is invalid")
  }

  if $::consul_template::init_style {

    case $::consul_template::init_style {
      'upstart' : {
        file { '/etc/init/consul-template.conf':
          mode    => '0444',
          owner   => 'root',
          group   => 'root',
          content => template('consul_template/consul-template.upstart.erb'),
        }
        file { '/etc/init.d/consul-template':
          ensure => link,
          target => '/lib/init/upstart-job',
          owner  => root,
          group  => root,
          mode   => '0755',
        }
      }
      'systemd' : {
        file { '/lib/systemd/system/consul-template.service':
          mode    => '0644',
          owner   => 'root',
          group   => 'root',
          content => template('consul_template/consul-template.systemd.erb'),
          notify  => Exec['reloadconsultemplate']
        }
        #deamon-reload if options get updated
        exec { 'reloadconsultemplate' :
          command     => 'systemctl daemon-reload',
          path        => '/usr/bin:/usr/sbin:/bin',
          refreshonly => true,
        }

      }
      'sysv' : {
        file { '/etc/init.d/consul-template':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul_template/consul-template.sysv.erb')
        }
      }
      'debian' : {
        file { '/etc/init.d/consul-template':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul_template/consul-template.debian.erb')
        }
      }
      'sles' : {
        file { '/etc/init.d/consul-template':
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template('consul_template/consul-template.sles.erb')
        }
      }
      default : {
        fail("I don't know how to create an init script for style ${::consul_template::init_style}")
      }
    }
  }

  if $::consul_template::manage_user {
    user { $::consul_template::user:
      ensure => 'present',
      system => true,
    }
  }
  if $::consul_template::manage_group {
    group { $::consul_template::group:
      ensure => 'present',
      system => true,
    }
  }
}
