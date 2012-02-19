package IntraBox::fileController;
## THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS
use strict;
use warnings;
use utf8;

# Configuration
use lib '.';
our $VERSION = '0.1';

# Load plugins for Dancer
use Dancer ':syntax';
use Dancer::Plugin::DBIC;

# Load fonctional plugins
use Digest::SHA1;
use DateTime;
use Data::FormValidator;
use DBIx::Class::FromValidators;

use Dancer::Plugin::Email;

## end THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS

#------------------------------------------------------------
# Session
#------------------------------------------------------------
my $sess = IntraBox::getSession();

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
prefix '/file';

#Récupération Variable de session
my $user = $sess->{login};

get '/download/:download_code' => sub {
	my $param_file = param("download_code");
	download_file($param_file);
};

post '/downloadFile' => sub {
	my $name_on_disk = param("name_on_disk");
	my $name         = param("name");
	my $password     = param("password");
	donwload_file_user( $name_on_disk, $name, $password );

};

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

	my $display_password;

	my $id_status;
	my $id_status2;
	my $status;

	my $access = false;

	my $deposit_liste =
	  schema->resultset('Deposit')
	  ->find( { download_code => "$download_code", } );

	if ($deposit_liste) {
		$id_deposit = $deposit_liste->id_deposit;
		$id_user    = $deposit_liste->id_user;
		$id_user2   = $id_user->login;
		$id_status  = $deposit_liste->id_status;

		$status     = $id_status->name;
		$id_status2 = $id_status->id_status;

		$expiration_date  = $deposit_liste->expiration_date;
		$acknowlegdement  = $deposit_liste->opt_acknowledgement;
		$downloads_report = $deposit_liste->opt_downloads_report;

		$password = $deposit_liste->opt_password;
	}

	#Vérification de la présence dans la base de données
	#Vérification de la présence dans les fichiers encore existants
	if ( not defined $id_deposit ) {    #Depot inexistant
		IntraBox::push_error(
"La page que vous avez demandé n\'existe pas. Vérifier que l'URL que vous avez indiqué est bonne"
		);
		template 'download', {};
	}
	elsif ( $id_status2 == 2 ) {        #Depot expiré
		IntraBox::push_error(
			"Le fichier que vous avez demandé n'est plus disponible. 
		Après un temps déterminé, le fichier est automatiquement supprimé de nos serveurs.
 Vous pouvez contacter l'utilisateur afin qu'il redépose le fichier qui est en statut : $status"
		);
		template 'download', {};
	}
	else {

#On récupère toutes les informations du fichiers présent dans la base de données

		my @liste_file =
		  schema->resultset('File')->search( { id_deposit => "$id_deposit", } );

		$access = true;
		if ($password) { $display_password = true }
		else { $display_password = false }

		IntraBox::push_info(
"Les fichiers sont bien présents dans la base de données. Vous pouvez appuyer sur les boutons correspondant"
		);
		template 'download',
		  {
			access           => $access,
			display_password => $display_password,
			liste_file       => \@liste_file,
		  };
	}
}

sub donwload_file_user {
	my $file_name_disk = $_[0];
	my $file_name      = $_[1];
	my $password       = $_[2];

	my $access;
	my $IP_user;
	my $user_agent;

	$IP_user    = request->remote_address;
	$user_agent = request->user_agent;

	my $current_date = DateTime->now;

	my $search =
	  schema->resultset('File')->find( { name_on_disk => $file_name_disk } );
	my $id_file         = $search->id_file;
	my $id_deposit_temp = $search->id_deposit;
	my $id_deposit      = $id_deposit_temp->id_deposit;
	my $id_user         = $id_deposit_temp->id_user;
	my $author_login    = $id_user->login;
	my $download_code   = $id_deposit_temp->download_code;

	if ( defined $password ) {

		my $search_pass =
		  schema->resultset('Deposit')->find( { id_deposit => $id_deposit } );
		my $password_deposit = $search_pass->opt_password;

		my $sha = Digest::SHA1->new;
		$sha->add($password);
		my $digest = $sha->hexdigest;

		if ( $password_deposit eq $digest ) { $access = true }
		else { $access = false }

	}
	else { $access = true }

	if ($access) {
		my $new_download = schema->resultset('Download')->create(
			{
				id_file    => $id_file,
				id_deposit => $id_deposit,
				ip         => $IP_user,
				useragent  => $user_agent,
				start_date => $current_date,
			}
		);

		email {
			to      => $author_login . "\@mines-albi.fr",
			from    => 'no_reply@Intrabox.com',
			subject => "IntraBox : Avis de téléchargement pour le fichier $file_name",
			message => "Le fichier $file_name vient d\'être téléchargé par l'utilisateur : $IP_user.\n
Ceci est email automatique. Merci de ne pas y répondre.\n
Ce mail vous est envoyé car vous avez choisi l'option \"Vous avertir lors d'un téléchargement\".\n
Merci d'utiliser IntraBox.",
		};
		
		

		send_file( "/Upload/$file_name_disk", filename => "$file_name" );

	}
	else {
		IntraBox::push_error("Mauvais mot de passe ! Veuillez réessayer :");
		download_file($download_code);
	}

}

#--------- /ROUTEES -------

true;
