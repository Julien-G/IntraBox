# Programme de suppression automatique des fichiers et d'expiration automatique des dépôts anciens
## THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS
package IntraBox::PurgeAuto;
use strict;
use warnings;

# Configuration
use lib '.';
our $VERSION = '0.1';

# Load plugins for Dancer
use Dancer ':syntax';
use Dancer::Plugin::DBIC;

# Load fonctional plugins
use DB::intrabox;
use Digest::SHA1;
use DateTime;
use Data::FormValidator;
use DBIx::Class::FromValidators;
## end THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS

#Chemin des fichiers enregistrés
my $path =
"/Program Files (x86)/Apache Software Foundation/Apache2.2/cgi-bin/IntraBox/public/Upload";

# Connexion à la base de données
my $dsn    = "dbi:mysql:intrabox";
my $schema = DB::intrabox->connect( $dsn, "", "" ) or die "problem";

#Date courante
my $current_date = DateTime->now;

#Initialisation variables
my $name_file;
my $id_deposit;
my $size_file;
my $total_size;
my $cpt;

#Ecriture dans les logs - Header
open my $LOG_DEL, '>>', './log_del.txt'
  or die "Impossible d'écrire dans le fichier";
print {$LOG_DEL} "\n---------------------------";
print {$LOG_DEL} "\nSuppression Anciens Depots\n";
close $LOG_DEL or die "Impossible de lire";

#Recuperation de tous les fichiers expirés ou non disponible
my @depositsExpired = $schema->resultset('Deposit')->search(
	{
		-or => [
			expiration_date => { '<', $current_date },
			id_status       => '2',
		],
	}
);

#Expiration dans la base de données
foreach my $deposit (@depositsExpired) {
	if ($deposit->id_status == 1) {warn_user($id_deposit)}	
	$deposit->id_status("2");
	$deposit->update;
	$id_deposit = $deposit->id_deposit;

	#On averti l'utlisateur du dépôt expiré
	

	#Recherche des fichiers associés aux dépôts expirés
	my @fileExpired = $schema->resultset('File')->search(
		{
			id_deposit => $id_deposit,
			on_server  => '1',
		}
	);

	#Suppression des fichiers associés
	if (@fileExpired) {
		foreach my $file (@fileExpired) {
			$file->on_server("0");
			$file->update;
			$name_file = $file->name_on_disk;

			$size_file  = $file->size;
			$total_size = $total_size + $size_file;
			$cpt++;

			unlink "$path/$name_file";

			#Ecriture dans les logs
			open $LOG_DEL, '>>', './log_del.txt'
			  or die "Impossible d'écrire dans le fichier";
			print {$LOG_DEL} "[$current_date] - Delete File - $name_file\n";
			close $LOG_DEL or die "Impossible de lire";
		}
	}
}

#Ecriture dans les logs - Footer
open $LOG_DEL, '>>', './log_del.txt'
  or die "Impossible d'écrire dans le fichier";
print {$LOG_DEL} "\nTotal files deleted : $cpt";
print {$LOG_DEL} "\nTotal size free : $total_size bytes";
print {$LOG_DEL} "\n---------------------------\n\n";
close $LOG_DEL or die "Impossible de lire";

#Programme d'avertissement de l'utilisateur de son dépôt terminé
sub warn_user {
	my $id_deposit = $_[0];

	my $depositJustExpired =
	  $schema->resultset('Deposit')->find( { id_deposit => $id_deposit, } );
	
	if ($depositJustExpired->opt_acknowledgement == 1) {
		print "ouhhhh !";
		#Envoi d'un email
	}
}
