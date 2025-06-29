#!/usr/bin/env raku

use Text::CSV;

my @coin-groups = csv(in => 'data-raw/flame-database-last-version-coin-groups.csv', headers => 'auto', sep=>";");

my @mints = csv(in => 'data-raw/flame-database-last-version-mints-country.csv', headers => 'auto', sep=>";");
my $mints-set = Set.new( @mints.map( { $_<ID> } ) );
my %mint-locations = @mints.map( { $_<ID> => $_<Country> } ).flat;

my @findings = csv(in => 'data-raw/flame-database-last-version-coin-findings.csv', headers => 'auto', sep=>";");
my $findings = Set.new( @findings.map( { $_<ID> } ) );
my %finding-locations = @findings.map( { $_<ID> => $_<Region>  } ).flat;

my @links-out;
my $unknown-hoard-id = 0;
my $unknown-mint-id = 0;
for @coin-groups -> %coin-group {
    next if %coin-group<cg_start_year> eq "" || %coin-group<cg_end_year> eq "";
    next unless %coin-group<Mint_ID> ∈ $mints-set || %coin-group<CoinFinding_ID> ∈ $findings;

    my %link = ( hoard => %finding-locations{ %coin-group<CoinFinding_ID> } // "Unknown hoard-" ~ $unknown-hoard-id++,
                 mint => %mint-locations{ %coin-group<Mint_ID> } // "Unknown mintner-" ~ $unknown-mint-id++,);

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

    die "Wrong mint %link " ~ %finding-locations unless %link<mint> ~~ Str;
    @links-out.push(%link);

}

csv( in => @links-out, out => "data/all-links.csv", sep => ";", headers => 'auto' );
