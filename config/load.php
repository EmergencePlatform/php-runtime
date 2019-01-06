<?php

{{#if cfg.sites.default.holo.gitDir ~}}
    $gitDir = '{{ cfg.sites.default.holo.gitDir }}';
    $siteRoot = '{{ pkg.svc_var_path }}/site';
{{else ~}}
    error_log('load.php can only be invoked if sites.default.holo.gitDir is configured');
    exit(1);
{{/if}}


if ($_SERVER['REQUEST_METHOD'] != 'PUT') {
    error_log('load.php method must be PUT');
    exit(1);
}


// read input tree-ish
$treeish = trim(file_get_contents('php://input'));

if (!$treeish) {
    error_log('load.php must have tree-ish provided via STDIN');
    exit(1);
}


// prepare git client
$git = '{{pkgPathFor "core/git"}}/bin/git';
putenv("GIT_DIR=${gitDir}");
putenv("GIT_WORK_TREE=${siteRoot}");
putenv("GIT_INDEX_FILE=${siteRoot}.INDEX");


// convert input to a hash
$inputHash = exec("$git rev-parse --verify ".escapeshellarg("$treeish"));

if (!$inputHash) {
    error_log('load.php could not read tree-ish "'.$treeish.'" from repository "'.$gitDir.'"');
    exit(1);
}


// ensure input is a tree hash
$treeHash = exec("$git rev-parse --verify ${inputHash}^{tree}");


// load into working tree on disk
echo "reading tree: $treeHash\n";
passthru("$git read-tree $treeHash 2>&1");

echo "checking out index\n";
passthru("$git checkout-index -af 2>&1");

echo "cleaning tree\n";
passthru("$git clean -df 2>&1");
