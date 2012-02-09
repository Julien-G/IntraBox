#!/usr/bin/perl
use strict;
use warnings;
use lib "lib";
use DBIx::Class::Schema::Loader qw/make_schema_at/;

warn "INC: @INC\n";

my $classe_base     = 'DB::intrabox';
my $repertoire_base = '../lib';
my $dsn = 'dbi:mysql:intrabox:localhost';
my $user = 'root';
my $password = 'tnwadt22';

make_schema_at(
	       $classe_base,
	       {
		relationships  => 1,
		components     => [qw/ FromValidators InflateColumn::DateTime Core/],
		debug          => 1,
		dump_directory => $repertoire_base,
		skip_load_external => 0,
	       },
	       [ $dsn, $user, $password],
	      );

__END__
