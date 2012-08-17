package Shared;

use v5.12;
use utf8;
use warnings;
use autodie;
use Exporter;
use POSIX qw( strftime );
use Data::Dumper;

use Log::Dispatch::File::Stamped;
use Log::Dispatch::Screen;

use base qw( Exporter );
our @EXPORT_OK
    = qw( ptime load_project_file save_project_file create_logfile);

my $pfile = 'list_of_projects';

sub _fname {
    return scalar strftime '%Y-%m-%d_%H_%M_%S', localtime;
}

sub ptime {
    return scalar strftime '%Y-%m-%d %H:%M:%S', localtime;
}

sub load_project_file {
    if ( -r $pfile ) {
        say "Loading $pfile";
        my $hashref = do $pfile;
        return $hashref;
    }
    return ();
}

sub save_project_file {
    my $project_list = shift;

    open my $project_file, '>', $pfile;
    print {$project_file} Data::Dumper->Dump( [$project_list], ['$hashref'] );
    close $project_file;

    my $b = $pfile . '_' . _fname();
    open my $backup, '>', $b;
    print {$backup} Data::Dumper->Dump( [$project_list], ['$hashref'] );
    close $backup;

    return;
}

sub create_logfile {
    my $name = shift;
    my $log  = Log::Dispatch->new();

    $log->add(
        Log::Dispatch::File::Stamped->new(
            'name'      => 'file1',
            'min_level' => 'debug',
            'filename'  => "$name.log",
            'stamp_fmt' => '%Y-%m-%d',
            'newline'   => 1,
        )
    );
    $log->add(
        Log::Dispatch::Screen->new(
            'name'      => 'screen1',
            'min_level' => 'info',
            'newline'   => 1,
        )
    );

    return $log;
}

1;
