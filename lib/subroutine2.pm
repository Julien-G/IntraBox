use Dancer ':syntax';
use warnings;

use lib '.';
use DB::intrabox;
use DBI;

#use strict;
use Exporter;
use base 'Exporter';

# Connexion à la base de données
my $dsn = "dbi:mysql:intrabox";
my $schema = DB::intrabox->connect( $dsn, "root", "cabernet" )
  or die "problem";

my $downloads_report;
my $acknowlegdement;
my $password;
my $comment;
my $created_date;
my $expiration_date;
my $id_deposit;

my $deposit_liste;
my $files_liste;

my $id_status;
my $status;
my $id_status2;
my $download_code;



our @EXPORT = qw(gestion_all_fichiers gestion_fichier);
1;
