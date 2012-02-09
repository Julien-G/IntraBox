package subroutine;

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

#----------Sub Routines --------

#--- DOWNLOAD ----

sub download_file {
	my $download_code = $_[0];

	#Initatilisation variables

	my $download_exist;
	my $download_available;
	my $message;

	my $downloads_report;
	my $acknowlegdement;
	my $password;
	my $comment;
	my $created_date;
	my $expiration_date;
	my $id_deposit;
	my $id_user;
	my $id_user2;

	my $id_status;
	my $id_status2;
	my $status;

	my @id_file;
	my @name;
	my @size;
	my @on_server;
	my @name_on_disk;

	my $login_user;

	my $access = false;

	my @liste_deposit =
	  $schema->resultset('Deposit')
	  ->search( { download_code => "$download_code", } );

	for my $deposit_liste (@liste_deposit) {
		$id_deposit       = $deposit_liste->id_deposit;
		$id_user          = $deposit_liste->id_user;
		$id_user2         = $id_user->login;
		$id_status        = $deposit_liste->id_status;
		$status           = $id_status->name;
		$id_status2       = $id_status->id_status;
		$expiration_date  = $deposit_liste->expiration_date;
		$acknowlegdement  = $deposit_liste->opt_acknowledgement;
		$downloads_report = $deposit_liste->opt_downloads_report;
		$created_date     = $deposit_liste->created_date;
		$comment          = $deposit_liste->opt_comment;
		$password         = $deposit_liste->opt_password;
	}

	#- Initialisations des messages d'erreurs -
	my $message_inexistant =
"La page que vous avez demandé n\'existe pas. Vérifier que l'URL que vous avez indiqué est bonne";

	my $message_indispo =
	  "Le fichier que vous avez demandé n'est plus disponible.
 Après un temps déterminé, le fichier est automatiquement supprimé de nos serveurs.
 Vous pouvez contacter l'utilisateur afin qu'il redépose le fichier qui est en statut : $status";

	#Vérification de la présence dans la base de données
	#Vérification de la présence dans les fichiers encore existants
	if ( not defined $id_deposit ) { $download_exist = false; }
	elsif ( $id_status2 == "2" ) {
		$download_available = false;
		$download_exist     = true;
	}
	else { $download_available = true; $download_exist = true; }

	#Envoi d'un message d'erreur si fichier inexistant
	if ( !$download_exist ) {
		$message = $message_inexistant;
		template 'download', { message => $message };

	}

	#Envoi d'un message d'erreur si fichier non disponible
	elsif ( !$download_available ) {
		$message = $message_indispo;
		template 'download', { message => $message };
	}

	#Si les fichiers sont bien présents et disponible
	else {

#On récupère toutes les informations du fichiers présent dans la base de données

		my $cpt_file;
		my $file_liste;

		my @liste_file =
		  $schema->resultset('File')
		  ->search( { id_deposit => "$id_deposit", } );
		for my $file_liste (@liste_file) {
			$cpt_file++;
			$id_file[$cpt_file]      = $file_liste->id_file;
			$name[$cpt_file]         = $file_liste->name;
			$size[$cpt_file]         = $file_liste->size;
			$name_on_disk[$cpt_file] = $file_liste->name_on_disk;
			$on_server[$cpt_file]    = $file_liste->on_server;
		}

		$access = true;

		$message =
"Les fichiers sont bien présents dans la base de données. Vous pouvez appuyer sur les boutons correspondant";
		template 'download',
		  {
			message    => $message,
			access     => $access,
			nbr_fic    => $cpt_file,
			file_liste => $file_liste,
			liste_file => \@liste_file
		  };
	}
}

sub donwload_file_user {
	my $file_name_disk = $_[0];
	my $file_name      = $_[1];
	send_file( "/Upload/$file_name_disk", filename => "$file_name" );
}

our @EXPORT = qw(download_file donwload_file_user);

#our @EXPORT = qw(recuperation_donnees_session_user calcul_used_space download_file randomposition generate_aleatoire_key count_files upload_file);
1;
