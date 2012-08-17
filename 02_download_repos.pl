#!/usr/bin/perl

use v5.12;
use utf8;
use warnings;
use autodie;
use FindBin;

use LWP::UserAgent;
use lib "$FindBin::Bin/.";
use Shared qw( ptime load_project_file save_project_file create_logfile );

my %filenames = (
    'cvs' => [ 'http://cvs.berlios.de/cvstarballs/',   '-cvsroot.tar.gz' ],
    'git' => [ 'http://download.berlios.de/gitdumps/', '-git.tar.gz' ],
    'hg'  => [ 'http://download.berlios.de/hgdumps/',  '-hg.tar.gz' ],
    'svn' => [ 'http://download.berlios.de/svndumps/', '-svnroot.tar.gz' ],
);

my $project_list = load_project_file();

my $adir = 'archive';
mkdir $adir if !( -e -d $adir );
chdir $adir;

my $log = create_logfile('downloading_projects_');
$log->info( ptime() . " - Downloading projects:\n" );

# 0 - source code management system
# 1 - description
# 2 - file size from head request

my $ua = LWP::UserAgent->new;
$ua->agent(
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.910.0 Safari/535.7 SUSE/16.0.910.0'
);

foreach my $key ( keys %{$project_list} ) {
    next if ( $project_list->{$key}->[0] eq 'no_repo' );
    next if ( $project_list->{$key}->[2] );

    my $archive = $key . $filenames{ $project_list->{$key}[0] }[1];

    if ( -f -W -s $archive ) {
        $project_list->{$key}[2] = -s $archive;

        say $archive, -s $archive;
        next;
    }

    my $url = $filenames{ $project_list->{$key}[0] }[0] . $archive;

    my $file = $ua->get( $url, ':content_file' => $archive );
    $project_list->{$key}->[2]
        = $ua->head($url)->{'_headers'}->{'content-length'};

    $log->info( ptime() . " - $archive $project_list->{$key}->[2]\n" );
}

save_project_file($project_list);
$log->info( ptime() . " - Finished processing\n" );
