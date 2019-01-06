<?php


// configure timezone
{{#if cfg.sites.default.timezone ~}}
    date_default_timezone_set({{toJson cfg.sites.default.timezone}});
{{/if}}


// determine root paths
$coreRoot = '{{#if cfg.core.root}}{{ cfg.core.root }}{{else}}{{pkgPathFor "emergence/php-core" }}{{/if}}';
{{#if cfg.sites.default.root ~}}
    $siteRoot = '{{cfg.sites.default.root }}';
{{else ~}}
    {{#if cfg.sites.default.holo.gitDir ~}}
        $siteRoot = '{{pkg.svc_var_path }}/site';
    {{else ~}}
        error_log('initialize.php needs sites.default.root or cfg.sites.default.holo.gitDir configured');
        exit(1);
    {{/if ~}}
{{/if}}


// determine hostname
$hostname = empty($_SERVER['HTTP_HOST']) ? 'localhost' : $_SERVER['HTTP_HOST'];


// load bootstrap PHP code
require("${coreRoot}/vendor/autoload.php");


// load core
Site::initialize($siteRoot, $hostname, [
    {{~#eachAlive bind.database.members as |member|~}}
        {{~#if @first}}
    'database' => [
        'host' => '{{#if member.cfg.host}}{{ member.cfg.host }}{{else}}{{ member.sys.ip }}{{/if}}',
        'port' => '{{ member.cfg.port }}',
        'username' => '{{ member.cfg.username }}',
        'password' => '{{ member.cfg.password }}',
        'database' => '{{#if ../cfg.sites.default.database}}{{ ../cfg.sites.default.database }}{{else}}default{{/if}}'
    ],
        {{~/if~}}
    {{~/eachAlive}}

    'handle' => 'default',
    'primary_hostname' => {{#if cfg.sites.default.primary_hostname}}{{toJson cfg.sites.default.primary_hostname}}{{else}}'localhost'{{/if}},
    'hostnames' => {{#if cfg.sites.default.hostnames}}{{toJson cfg.sites.default.hostnames}}{{else}}[]{{/if}},

    'logger' => [
        'dump' => {{toJson cfg.logger.dump}},
        'root' => '{{ pkg.svc_var_path }}/logs'
    ]
]);
