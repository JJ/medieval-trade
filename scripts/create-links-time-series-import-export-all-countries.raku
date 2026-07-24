#!/usr/bin/env raku

use Text::CSV;

sub normalize_territories( $country ) {
    my $normalized_territory = $country;
    given $country {
        when $_ eq "Spain" || $_ eq "Portugal" { $normalized_territory = "Iberian Peninsula"; }
        when $_ eq "Palestinian Territory" || $_ eq "Israel" { $normalized_territory = "Palestina";}
        when $_ eq "Sweden" || $_ eq "Denmark" || $_ eq "Norway" { $normalized_territory = "Scandinavia";}
        when "United Kingdom" { $normalized_territory = "Britannia";}
        when "Turkey" { $normalized_territory = "Anatolia";}
        when "France" { $normalized_territory = "Gallia";}
        when "Italy" { $normalized_territory = "Italia";}
    }
    return $normalized_territory;
}

sub MAIN(Str $coin-group-file, Str $mint-country-file, Str $coin-findings-file, Str $out-file) {

    my @coin-groups = csv(in => $coin-group-file, headers => 'auto');

    die "No se puede leer $coin-group-file" unless @coin-groups.elems;

    my @mints = csv(in => $mint-country-file, headers => 'auto', sep=>";");
    my $mints-set = Set.new( @mints.map( { $_<ID> } ) );
    my %mint-locations = @mints.map( { $_<ID> => $_<Country> } ).flat;

    my @findings = csv(in => $coin-findings-file, headers => 'auto');
    my $findings = Set.new( @findings.map( { $_<ID> } ) );
    my %finding-locations = @findings.map( { $_<ID> => $_<Region>  } ).flat;

    my @links-out;
    my $unknown-hoard-id = 0;
    my $unknown-mint-id = 0;
    for @coin-groups -> %coin-group {
        next if %coin-group<CoinFinding_ID> eq "NA";
        next if %coin-group<cg_start_year> eq "" || %coin-group<cg_end_year> eq "";
        next unless %coin-group<Mint_ID> ∈ $mints-set || %coin-group<CoinFinding_ID> ∈ $findings;

        my $mint;
        if (%coin-group<Mint_ID> eq "") || (%coin-group<Mint_ID> eq "NA") || ( %mint-locations{ %coin-group<Mint_ID> } eq "" ) || ( ~%mint-locations{ %coin-group<Mint_ID> } eq "(Any)" ) {
            $mint = "Unknown mintner-" ~ $unknown-mint-id++;
        } else  {
            $mint = %mint-locations{ %coin-group<Mint_ID> };
        }

        if %finding-locations{ %coin-group<CoinFinding_ID> } eq "" {
            say "Coin group", %coin-group;
            exit(1);
        }
        my $finding-location = %finding-locations{ %coin-group<CoinFinding_ID> } ne "NA" ?? %finding-locations{ %coin-group<CoinFinding_ID> } !! "Unknown location-" ~ $unknown-hoard-id++ ;

        my %link = ( hoard     => normalize_territories( $finding-location ),
                     mint      => normalize_territories( $mint ),
                     num_coins => %coin-group<cg_num_coins>);

        if %coin-group<cg_start_year> == 0 || %coin-group<cg_start_year> eq "NA" || %coin-group<cg_end_year> eq "NA" {
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

        die "Wrong mint %link " ~ %finding-locations unless %link<mint> ~~ Str;
        @links-out.push(%link);

    }

    csv( in => @links-out, out => $out-file, sep => ";", headers => 'auto' );
}
