#!/usr/bin/env raku

use Text::CSV;

my @coin-groups = csv(in => 'data-raw/flame-database-last-version-coin-groups.csv', headers => 'auto', sep=>";");

my @mints = csv(in => 'data-raw/flame-database-last-version-mints-iberian-peninsula.csv', headers => 'auto', sep=>";");
my $iberian-mints = Set.new( @mints.map( { $_<ID> } ) );

my @all-mints = csv(in => 'data-raw/flame-database-last-version-mints.csv', headers => 'auto', sep=>";");
my %mint-locations = @all-mints.map( { $_<ID> => $_<location_title> } ).flat;

my @findings = csv(in => 'data-raw/flame-database-last-version-coin-findings-iberian-peninsula.csv', headers => 'auto', sep=>";");
my $iberian-findings = Set.new( @findings.map( { $_<ID> } ) );

my @all-findings = csv(in => 'data-raw/flame-database-last-version-coin-findings.csv', headers => 'auto', sep=>";");
my %finding-locations = @all-findings.map( { $_<ID> => $_<cf_custom_place_name> ?? $_<cf_custom_place_name> !! $_<cf_name> } ).flat;

my @links-out;
for @coin-groups -> %coin-group {
    next unless %coin-group<CoinFinding_ID> ne "";
    next if %coin-group<cg_start_year> eq "" || %coin-group<cg_end_year> eq "";
    next unless %coin-group<Mint_ID> ∈ $iberian-mints || %coin-group<CoinFinding_ID> ∈ $iberian-findings;

    my %link = ( hoard => %finding-locations{ %coin-group<CoinFinding_ID> // "Unknown hoard" },
                 mint => %mint-locations{ %coin-group<Mint_ID> } // "Unknown mintner");
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
    @links-out.push(%link);

}

csv( in => @links-out, out => "data/all-iberian-links.csv", sep => ";", headers => 'auto' );
