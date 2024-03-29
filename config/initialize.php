<?php


// configure timezone
{{#if cfg.default_timezone ~}}
    date_default_timezone_set({{toJson cfg.default_timezone}});
{{/if}}


// determine root paths
$coreRoot = '{{#if cfg.core.root}}{{ cfg.core.root }}{{else}}{{pkgPathFor "emergence/php-core" }}{{/if}}';
{{#if cfg.sites.default.root ~}}
    $siteRoot = '{{cfg.sites.default.root}}';
{{else ~}}
    {{#if cfg.sites.default.holo.gitDir ~}}
        $siteRoot = '{{pkg.svc_var_path}}';
    {{else ~}}
        $siteRoot = '{{pkg.path}}';
    {{/if ~}}
{{/if}}


// determine hostname
$hostname = empty($_SERVER['HTTP_HOST']) ? 'localhost' : parse_url($_SERVER['HTTP_HOST'], PHP_URL_HOST);


// load bootstrap PHP code
require("${coreRoot}/vendor/autoload.php");

// configure core (before initialization)
Site::$debug = {{#if cfg.core.debug}}true{{else}}false{{/if}};
Site::$production = {{#if cfg.core.production}}true{{else}}false{{/if}};

// load core
Site::initialize($siteRoot, $hostname, [
    {{~#eachAlive bind.database.members as |member|~}}
        {{~#if @first}}
    'database' => [
        'host' => '{{#if member.cfg.host}}{{ member.cfg.host }}{{else}}{{ member.sys.ip }}{{/if}}',
        'port' => '{{ member.cfg.port }}',
        'username' => '{{ member.cfg.username }}',
        'password' => '{{ member.cfg.password }}',
        'database' => '{{ ../cfg.sites.default.database }}'
    ],
        {{~/if~}}
    {{~/eachAlive}}

    'handle' => {{toJson cfg.sites.default.handle}},
    'primary_hostname' => {{toJson cfg.sites.default.primary_hostname}},
    'hostnames' => {{#if cfg.sites.default.hostnames}}{{toJson cfg.sites.default.hostnames}}{{else}}[]{{/if}},

    {{#if cfg.sites.default.title ~}}
    'label' => {{toJson cfg.sites.default.title}},

    {{/if ~}}

    {{#if cfg.sites.default.use_https ~}}
    'ssl' => true,

    {{/if ~}}

    'logger' => [
        'dump' => {{toJson cfg.logger.dump}},
        'root' => '{{ pkg.svc_var_path }}/logs'
    ],

    'storage' => [
        'local_root' => '{{ pkg.svc_data_path }}'
    ]
]);

// configure core (overrides app tree config)
Site::$debug = {{#if cfg.core.debug}}true{{else}}false{{/if}};
Site::$production = {{#if cfg.core.production}}true{{else}}false{{/if}};
