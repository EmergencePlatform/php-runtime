<?php

use Emergence\Console\Logger as ConsoleLogger;
use Symfony\Component\VarDumper\Cloner\VarCloner;
use Symfony\Component\VarDumper\Dumper\CliDumper;
use Symfony\Component\VarDumper\VarDumper;
use Whoops\Handler\PlainTextHandler;


// initialize site
require('{{ pkg.svc_config_path }}/initialize.php');


// override content type
header('Content-Type: text/plain');


// disable time limit
set_time_limit(0);


// initialize console-based logger
if (!class_exists(ConsoleLogger::class)) {
    echo ConsoleLogger::class." not available within currently loaded site\n";
    echo "Site must be updated to support running console commands\n";
    exit(1);
}

$logger = new ConsoleLogger;


// reconfigure VarDumper for CLI
$cloner = new VarCloner();
$dumper = new CliDumper('php://output');
$dumper->setColors(true);
VarDumper::setHandler(function ($var) use ($cloner, $dumper, $logger) {
    $dumper->dump(
        $cloner->cloneVar($var),
        function ($line, $depth) use ($logger) {
            // A negative depth means "end of dump"
            if ($depth >= 0) {
                // Adds a two spaces indentation to the line
                $logger->debug(str_repeat('  ', $depth).$line);
            }
        }
    );
});


// reconfigure Whoops for CLI
$whoops = Site::getWhoops();
$whoopsHandler = new PlainTextHandler($logger);
$whoopsHandler->loggerOnly(true);
$whoops->clearHandlers();
$whoops->pushHandler($whoopsHandler);


// parse command + args
list ($command, $args) = preg_split('/\s+/', $_SERVER['QUERY_STRING'], 2);
$command = $command ? explode(':', $command) : null;


$fs = Site::getFilesystem();
if ($command) {
    // find delegate script
    $commandPath = 'console-commands/'.implode('/', $command).'.php';
    $node = Site::resolvePath($commandPath);

    if (!$node) {
        echo "Command script not found: $commandPath\n";
        exit(1);
    }


    // build faux-superglobal
    $_COMMAND = [
        'SCRIPT_PATH' => $node->RealPath,
        'ARGS' => $args,
        'LOGGER' => $logger
    ];


    // create a closure for executing hanlder so that $_EMAIL is the only variable pre-defined in its scope
    $handler = function() use (&$_COMMAND) {
        return require($_COMMAND['SCRIPT_PATH']);
    };


    // execute closure
    $handler();
} else {
    // discover available commands
    $availableCommands = [];
    foreach ($fs->listContents('console-commands', true) as $object) {
        if ($object['type'] != 'file' || $object['extension'] != 'php') {
            continue;
        }

        $availableCommands[] = str_replace('/', ':', substr($object['path'], 17, -4));
    }


    // print usage
    echo "Usage: emergence-console-run <command> [--stdin] [args...]\n\n";

    if (count($availableCommands)) {
        sort($availableCommands);

        echo "Available commands:\n\n";

        foreach ($availableCommands as $availableCommand) {
            echo "  {$availableCommand}\n";
        }
    } else {
        echo "No commands available.\n";
    }

    echo "\nDefine new commands under /console-commands/**/*.php\n";
    exit(1);
}
