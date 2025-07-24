#!/usr/bin/env raku

use Text::CSV;

my @coin-groups = csv(in => 'data-raw/flame-database-last-version-coin-groups.csv', headers => 'auto', sep=>";");

my @mints = csv(in => 'data-raw/flame-database-last-version-mints-iberian-peninsula.csv', headers => 'auto', sep=>";");
my $iberian-mints = Set.new( @mints.map( { $_<ID> } ) );

my @all-mints = csv(in => 'data-raw/flame-database-last-version-mints-country.csv', headers => 'auto', sep=>";");
my %mint-locations = @all-mints.map( { $_<ID> => $_<location_title> } ).flat;
my %mint-regions = @all-mints.map( { $_<ID> => $_<Country> } ).flat;
say %mint-regions;

my @findings = csv(in => 'data-raw/flame-database-last-version-coin-findings-iberian-peninsula.csv', headers => 'auto', sep=>";");
my $iberian-findings = Set.new( @findings.map( { $_<ID> } ) );

my @all-findings = csv(in => 'data-raw/flame-database-last-version-coin-findings.csv', headers => 'auto', sep=>";");
my %finding-locations = @all-findings.map( { $_<ID> => $_<cf_custom_place_name> ?? $_<cf_custom_place_name> !! $_<cf_name> } ).flat;
my %finding-regions = @all-findings.map( { $_<ID> => $_<Region> } ).flat;

my @links-out;
my @iberian-links-out;
my @regional-links-out;

for @coin-groups -> %coin-group {
    next if %coin-group<cg_start_year> eq "" || %coin-group<cg_end_year> eq "";
    next unless %coin-group<Mint_ID> ∈ $iberian-mints || %coin-group<CoinFinding_ID> ∈ $iberian-findings;

    my %link = ( hoard => %finding-locations{ %coin-group<CoinFinding_ID> } // "Unknown hoard",
                 mint => %mint-locations{ %coin-group<Mint_ID> } // "Unknown mintner");
    my %link-regions = ( hoard => %finding-regions{ %coin-group<CoinFinding_ID> } // "Unknown hoard region",
                        mint => %mint-regions{ %coin-group<Mint_ID> } // "Unknown mintner region");
    if %coin-group<cg_start_year> == 0 {
        if %coin-group<cg_custom_start_century> > 0 {
            %link<year> = %coin-group<cg_custom_start_century>*100-50;
        } elsif %coin-group<cg_custom_end_century> > 0 {
            %link<year> = %coin-group<cg_custom_end_century>*100-50;
        } else {
            next;
        }
    } else {
        %link<year> = %coin-group<cg_start_year> + floor( (%coin-group<cg_end_year> - %coin-group<cg_start_year>)/2 );
    }
    if %link<year> == 0 {
        say %coin-group;
    }

    die %coin-group unless %link<hoard>;
    %link-regions<year> = %link<year>;
    @links-out.push(%link);
    @iberian-links-out.push(%link) if %coin-group<Mint_ID> ∈ $iberian-mints && %coin-group<CoinFinding_ID> ∈ $iberian-findings;
    say %link-regions;
    @regional-links-out.push(%link-regions) if %link-regions<hoard> !~~ /Unknown/ && %link-regions<mint> !~~ /Unknown/;
}

csv( in => @links-out, out => "data/all-iberian-links.csv", sep => ";", headers => 'auto' );
csv( in => @iberian-links-out, out => "data/iberian-links.csv", sep => ";", headers => 'auto' );
csv( in => @regional-links-out, out => "data/regional-links.csv", sep => ";", headers => 'auto' );