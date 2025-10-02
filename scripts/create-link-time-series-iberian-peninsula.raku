#!/usr/bin/env raku

use Text::CSV;

my @coin-groups = csv(in => 'data-raw/flame-database-last-version-coin-groups.csv', headers => 'auto', sep=>";");

my @mints = csv(in => 'data-raw/flame-database-last-version-mints-iberian-peninsula.csv', headers => 'auto', sep=>";");
my $iberian-mints = Set.new( @mints.map( { $_<ID> } ) );

my @all-mints = csv(in => 'data-raw/flame-database-last-version-mints-country.csv', headers => 'auto', sep=>";");
my %mint-locations = @all-mints.map( { $_<ID> => $_<location_title> } ).flat;
my %mint-regions = @all-mints.map( { $_<ID> => $_<Country> } ).flat;

my @findings = csv(in => 'data-raw/flame-database-last-version-coin-findings-iberian-peninsula.csv', headers => 'auto', sep=>";");
my $iberian-findings = Set.new( @findings.map( { $_<ID> } ) );

my @all-findings = csv(in => 'data-raw/flame-database-last-version-coin-findings.csv', headers => 'auto', sep=>";");
my %finding-locations = @all-findings.map( { $_<ID> => $_<cf_custom_place_name> ?? $_<cf_custom_place_name> !! $_<cf_name> } ).flat;
my %finding-regions = @all-findings.map( { $_<ID> => $_<Region> } ).flat;

my %iberian-links-out;
my %regional-links-out;
my %annual-link-probability;

for @coin-groups -> %coin-group {
    next if %coin-group<cg_start_year> eq "" || %coin-group<cg_end_year> eq "";
    next unless %coin-group<Mint_ID> ∈ $iberian-mints || %coin-group<CoinFinding_ID> ∈ $iberian-findings;

    my $hoard-region =  %finding-regions{ %coin-group<CoinFinding_ID> } // "Unknown hoard region",
    my $mint-region = %mint-regions{ %coin-group<Mint_ID> } // "Unknown mintner region";

    my $start_year;
    my $end_year;
    if %coin-group<cg_start_year> == 0 {
        if %coin-group<cg_custom_start_century> > 0 {
            $start_year = %coin-group<cg_custom_start_century>*100;
            $end_year = $start_year + 100;
        } elsif %coin-group<cg_custom_end_century> > 0 {
            $start_year = %coin-group<cg_custom_end_century>*100;
            $end_year = $start_year + 100;
        } else {
            next;
        }
    } else {
        $start_year = %coin-group<cg_start_year>;
        $end_year = %coin-group<cg_start_year>;
    }
    if %link<year> == 0 {
        say %coin-group;
    }

    my $probability = 1/( $end_year - $start_year );
    my @edge = ( $hoard-region, $mint-region ).sort;
    for $start_year .. $end_year -> $year {
        %annual-link-probability{$year} += $probability;
        %regional-links-out{$year}{@edge[0]}{@edge[1]} += $probability;
        %iberian-links-out{$year}{@edge[0]}{@edge[1]} += $probability if %coin-group<Mint_ID> ∈ $iberian-mints && %coin-group<CoinFinding_ID> ∈ $iberian-findings;
    }

    die %coin-group unless %link<hoard>;

}

csv( in => %annual-link-probability, out => "data/annual-link-probability.csv", sep => ";", headers => 'auto' );
csv( in => %iberian-links-out, out => "data/annual-iberian-links.csv", sep => ";", headers => 'auto' );
csv( in => %regional-links-out, out => "data/annual-regional-links.csv", sep => ";", headers => 'auto' );