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
my %annual-all-iberian-link-probability;
my %annual-iberian-link-probability;

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
        $end_year = %coin-group<cg_end_year>;
    }
    if $start_year == 0 or $end_year == 0 {
        say %coin-group;
    }

    say "Years $start_year - $end_year";
    my $probability;
    if ( $start_year == $end_year ) {
        $probability = 1;
    } else {
        $probability = 1/( $end_year - $start_year);
    }
    my @edge = ( $hoard-region, $mint-region ).sort;
    loop ( my $year = $start_year; $year <= $end_year; $year+= 1 ) {
        %annual-link-probability{$year} += $probability;
        %regional-links-out{$year}{@edge[0]}{@edge[1]} += $probability;
        if %coin-group<Mint_ID> ∈ $iberian-mints || %coin-group<CoinFinding_ID> ∈ $iberian-findings {
            %annual-all-iberian-link-probability{$year} += $probability;
        }
        if %coin-group<Mint_ID> ∈ $iberian-mints && %coin-group<CoinFinding_ID> ∈ $iberian-findings {
            %annual-iberian-link-probability{$year} += $probability;
            %iberian-links-out{$year}{@edge[0]}{@edge[1]} += $probability ;
        }
    }

}

say %iberian-links-out;
say %regional-links-out;

csv( in => convert_hash_to_sorted_array_of_hashes(%annual-link-probability), out => "data/annual-link-probability.csv", sep => ";", headers => 'auto' );
csv( in => convert_hash_to_sorted_array_of_hashes(%annual-all-iberian-link-probability), out => "data/annual-all-iberian-link-probability.csv", sep => ";", headers => 'auto' );
csv( in => convert_hash_to_sorted_array_of_hashes(%annual-iberian-link-probability), out => "data/annual-iberian-link-probability.csv", sep => ";", headers => 'auto' );
csv( in => convert_to_array_of_hashes(%iberian-links-out), out => "data/annual-iberian-links.csv", sep => ";", headers => 'auto' );
csv( in => convert_to_array_of_hashes(%regional-links-out), out => "data/annual-regional-links.csv", sep => ";", headers => 'auto' );

sub convert_to_array_of_hashes( %hash ) {
    my @array;
    for %hash.kv.sort: { $^a[0] <=> $^b[0] } -> $key, %value {
        for %value.kv -> $key2, %value2 {
            for %value2.kv -> $key3, $value3 {
                @array.push({ year => $key, region1 => $key2, region2 => $key3, value => $value3 });
            }
        }
    }
    return @array;
}

sub convert_hash_to_sorted_array_of_hashes( %hash ) {
    my @array;
    for %hash.keys.sort: { $^a <=> $^b } -> $key {
        @array.push({ year => $key, link_density => %hash{$key} });
    }
    return @array;
}