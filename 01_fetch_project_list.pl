#!/usr/bin/perl

use v5.12;
use utf8;
use warnings;
use autodie;
use FindBin;

use WWW::Mechanize::Cached::GZip;
use Cache::FileCache;
use lib "$FindBin::Bin/.";
use Shared qw ( ptime load_project_file save_project_file
    create_logfile );

sub get_scm_type {
    my $log  = shift;
    my $name = shift;
    my $mech = WWW::Mechanize::Cached::GZip->new();
    my $url  = 'http://developer.berlios.de/projects/' . $name;

    $mech->get($url);

    $log->info( ptime() . ' - ' . $mech->status() . " - $url\n" );

    foreach my $link ( $mech->links() ) {
        if ( $link->url() =~ m{^/(cvs |svn |hg |git )/}xms ) {
            return $1;
        }
    }
    $log->info("no_repo_found : $url\n");
    return 'no_repo';
}

sub build_project_list {
    my $mech         = shift;
    my $log          = shift;
    my $cat_num      = shift;
    my $project_list = shift;

    my $url_base
        = 'http://developer.berlios.de/softwaremap/trove_list.php?form_cat=';

    foreach my $page ( 1 .. 15 ) {
        my $url = "$url_base$cat_num&page=$page";
        $mech->get($url);

        if ( $mech->status() == 200 ) {

            $log->info(
                "\n" . ptime() . ' - ' . $mech->status() . " - $url\n" );

            foreach my $link ( $mech->links() ) {

                if ( $link->url() =~ m{(^/projects/)([a-z0-9]+)(/)}ixms ) {
                    my $key = $2;
                    if ( exists $project_list->{$key} ) {
                        say "$key already exists";
                        next;
                    }

                    $project_list->{$key}
                        = [ get_scm_type( $log, $key ), $link->text(), ];
                }
            }
        }
    }
    return;
}

# berlios limits results to 300 max
my %cat_dev_status = (
    'planning'   => 29,
    'prealpa'    => 30,
    'alpha'      => 31,
    'beta'       => 32,
    'production' => 33,
    'mature'     => 34,
    'inactive'   => 436,
);

my %cat_int_audience = (
    'cservice' => 273,
    'devel'    => 8,
    'edu'      => 274,
    'end'      => 9,
    'fii'      => 275,
    'health'   => 276,
    'it'       => 277,
    'legal'    => 278,
    'man'      => 279,
    'other'    => 10,
    'rel'      => 280,
    'sci'      => 281,
    'sys'      => 11,
    'tele'     => 282,
);

my @all_types = ( \%cat_dev_status, \%cat_int_audience, );

my $cache_params = {
    'default_expires_in' => '5d',
    'namespace'          => 'berlios',
    'cache_root'         => '/tmp/perl-cache/',
};
my $cache = Cache::FileCache->new($cache_params);
my $mech = WWW::Mechanize::Cached::GZip->new( 'cache' => $cache );

my $log = create_logfile('finding_projects_');

$log->info( ptime() . " - Getting project names\n" );

my $project_list = load_project_file();

foreach my $type (@all_types) {
    foreach my $cat ( keys %{$type} ) {
        build_project_list( $mech, $log, $type->{$cat}, $project_list );
    }
}

save_project_file($project_list);
$log->info( ptime() . " - Finished processing\n" );
