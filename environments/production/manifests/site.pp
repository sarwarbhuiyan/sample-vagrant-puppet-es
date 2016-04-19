include apt

exec { "apt-get update":
    command => "/usr/bin/apt-get update",
}

apt::key { "elasticsearch":
       id => "0xd27d666cd88e42b4",
       ensure => present,
       source => "https://packages.elastic.co/GPG-KEY-elasticsearch",
  
}

apt::source { "elasticsearch_repo":
        location        => "http://packages.elastic.co/elasticsearch/2.x/debian",
        release         => "stable",
        repos           => " main",
        include     => { src => false },
}

include java

class { "elasticsearch": 
  version => '2.3.1',
  require => Exec['apt-get update']
}

elasticsearch::instance { 'es-01':
  config => {
    'network.host' => '0.0.0.0'
  },
  init_defaults => {
    'ES_HEAP_SIZE' => '4g'
  },
}

elasticsearch::plugin { 'lmenezes/elasticsearch-kopf':
  instances => 'es-01',
}

elasticsearch::plugin { 'license':
  instances => 'es-01',
}

elasticsearch::plugin { 'marvel-agent':
  instances => 'es-01',
  require => Elasticsearch_plugin['license'],
}

elasticsearch::plugin { 'graph':
  instances => 'es-01',
  require => Elasticsearch_plugin['license'],
}

class { '::kibana4':
    version           => '4.5.0-linux-x64',
    install_method    => 'archive',
    archive_symlink   => true,
    manage_user       => true,
    kibana4_user      => kibana4,
    kibana4_group     => kibana4,
    kibana4_gid       => 200,
    kibana4_uid       => 200,
    config            => {
        'server.port'           => 5601,
        'server.host'           => '0.0.0.0',
        'elasticsearch.url'     => 'http://localhost:9200',
        },
    plugins => {
        'elasticsearch/marvel' => {
           plugin_dest_dir    => 'marvel',                       #mandatory - plugin will be installed in ${kibana4_plugin_dir}/${plugin_dest_dir}
           ensure             => present,                        #mandatory - either 'present' or 'absent'
        },
        'elastic/sense' => {
           ensure          => present,
           plugin_dest_dir => 'sense',
        },
	'elasticsearch/graph/latest' => {
           ensure          => present,
           plugin_dest_dir => 'graph',
        }
      }
  }


