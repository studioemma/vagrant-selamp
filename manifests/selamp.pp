group { 'puppet': ensure => present }
Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }
File { owner => 0, group => 0, mode => 0644 }

# apt-get update so we can install the latest packages
class {'apt':
	always_apt_update => true,
}

if $::phpv == "php54" {
	apt::key { '4F4EA0AAE5267A6C': }

	apt::ppa { 'ppa:ondrej/php5-oldstable':
		require => Apt::Key['4F4EA0AAE5267A6C']
	}
} elsif $::phpv == "php55" {
	apt::key { '4F4EA0AAE5267A6C': }

	apt::ppa { 'ppa:ondrej/php5':
		require => Apt::Key['4F4EA0AAE5267A6C']
	}
}

# install packages
package { [
		'build-essential',
		'vim',
		'curl',
		'htop',
		'git-core',
		'graphviz'
	]:
	ensure	=> 'installed',
}

# apache configuration
class { 'apache': }

apache::dotconf { 'custom':
	content => 'EnableSendfile Off',
}

apache::module { 'rewrite': }
apache::module { 'ssl': }

apache::vhost { "${::website}":
	template => "${::vhost}",
	priority => '01',
}

# run apache under vagrant user
file { "/var/lock/apache2":
	ensure  => present,
	mode    => 755,
	owner   => 'vagrant',
	group   => 'vagrant',
	recurse => true,
	require => Package["apache"],
	notify  => Service['apache']
}

exec { "apacherunasvagrant" :
	command => "sed -e 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/' -e 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/' -i /etc/apache2/envvars",
	onlyif  => "grep -c 'APACHE_RUN_USER=www-data' /etc/apache2/envvars",
	require => Package["apache"],
	notify  => Service['apache'],
}

# php config
class { 'php':
	service             => 'apache',
	service_autorestart => false,
	module_prefix       => '',
}

php::module { 'php5-mysql': }
php::module { 'php5-sqlite': }
php::module { 'php5-cli': }
php::module { 'php5-curl': }
php::module { 'php5-gd': }
php::module { 'php5-intl': }
php::module { 'php5-mcrypt': }
php::module { 'php5-memcache': }
php::module { 'php5-memcached': }

class { 'php::devel':
	require => Class['php'],
}

class { 'php::pear':
	require => Class['php'],
}

# xhprof
php::pecl::module { 'xhprof':
	use_package     => false,
	preferred_state => 'beta',
	notify  => Service['apache'],
}

file { "/var/xhprof":
	ensure => "directory",
	owner  => "vagrant",
	group  => "vagrant",
	mode   => 775,
}

file { "/var/xhprof/xhprof_html":
	ensure  => link,
	target  => "/usr/share/php/xhprof_html",
	require => File['/var/xhprof']
}

file { "/var/xhprof/xhprof_lib":
	ensure  => link,
	target  => "/usr/share/php/xhprof_lib",
	require => File['/var/xhprof']
}

file { "/var/www/xhprof":
	ensure => "directory",
	owner  => "vagrant",
	group  => "vagrant",
	mode   => 775,
	require => Package["apache"],
}

file { "/var/www/xhprof/header.php":
	ensure  => present,
	owner   => "vagrant",
	group   => "vagrant",
	source  => "/vagrant/manifests/xhprof/header.php",
	require => File['/var/www/xhprof']
}

file { "/var/www/xhprof/footer.php":
	ensure  => present,
	owner   => "vagrant",
	group   => "vagrant",
	source  => "/vagrant/manifests/xhprof/footer.php",
	require => File['/var/www/xhprof']
}

apache::vhost { 'xhprof':
	server_name => 'xhprof.dev',
	docroot     => '/var/xhprof/',
	port        => 80,
	priority    => '25',
	require     => Php::Pecl::Module['xhprof']
}

class { 'composer':
	require => Package['php5', 'curl'],
}

# xdebug
class { 'xdebug':
	service => 'apache',
}

puphpet::ini { 'xdebug':
	value   => [
		'xdebug.default_enable = 1',
		'xdebug.remote_autostart = 0',
		'xdebug.remote_connect_back = 1',
		'xdebug.remote_enable = 1',
		'xdebug.remote_handler = "dbgp"',
		'xdebug.remote_port = 9000'
	],
	ini     => '/etc/php5/conf.d/zzz_xdebug.ini',
	notify  => Service['apache'],
	require => Class['php'],
}

puphpet::ini { 'xhprof':
	value	=> [
		'extension = xhprof.so',
		'xhprof.output_dir = /var/xhprof'
	],
	ini     => '/etc/php5/conf.d/zzz_xhprof.ini',
	notify  => Service['apache'],
	require => [Class['php'],
		File['/var/www/xhprof/header.php'],
		File['/var/www/xhprof/footer.php']]
}

puphpet::ini { 'php':
	value	=> [
		'date.timezone = "Europe/Brussels"',
		'session.name = PHPSESSID'
	],
	ini		=> '/etc/php5/conf.d/zzz_php.ini',
	notify	=> Service['apache'],
	require => Class['php'],
}

puphpet::ini { 'custom':
	value	=> [
		'display_errors = On',
		'error_reporting = -1'
	],
	ini		=> '/etc/php5/conf.d/zzz_custom.ini',
	notify	=> Service['apache'],
	require => Class['php'],
}

# mysql
class { 'mysql::server':
	config_hash	 => {
		'root_password' => 'EmmaGee',
		'bind_address'  => '0.0.0.0'
	}
}

# databases
mysql::db { 'website':
	user     => 'root',
	password => 'EmmaGee',
	host     => '%',
	grant    => ['all'],
}
