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
	download_file("$param_file");
};

post '/download/:download_code' => sub {
	my $param_file = param("download_code");
	download_file("$param_file");
};

post '/downloadFile' => sub {
	my $name_on_disk = param("name_on_disk");
	my $name         = param("name");
	donwload_file_user( $name_on_disk, $name);
};

sub download_file {
	my $download_code = $_[0];

	#Initatilisation variables
	my $password;
	my $id_deposit;
	my $id_user;
	
	my @liste_file;

	my $id_status;

	my $display_password = false;
	my $access           = false;

	my $deposit_liste =
	  schema->resultset('Deposit')
	  ->find( { download_code => "$download_code", } );

	if ($deposit_liste) {
		$id_deposit = $deposit_liste->id_deposit;
		$id_user    = $deposit_liste->id_user;
		$id_status  = $deposit_liste->id_status;
		$password   = $deposit_liste->opt_password;
	}

	#Vérification de la présence dans la base de données
	if ( not defined $id_deposit ) {    #Depot inexistant
		IntraBox::push_error(
"La page que vous avez demandé n\'existe pas. Vérifier que l'URL que vous avez indiqué est bon"
		);
		template 'download', {};
	}
	elsif ( $id_status == 2 ) {         #Depot expiré
		IntraBox::push_error(
			"Le fichier que vous avez demandé n'est plus disponible. 
		Après un temps déterminé, le fichier est automatiquement supprimé de nos serveurs.
 Vous pouvez contacter l'utilisateur afin qu'il redépose le fichier"
		);
		template 'download', {};
	}
	else {

#On récupère toutes les informations du fichiers présent dans la base de données

		#un champ de saisie de mot de passe sera présent dans le template
		if ($password) {
			my $password_template = param("password");
			if ( defined $password_template ) {
				#Cas 2 - password envoyé
				my $sha = Digest::SHA1->new;
				$sha->add($password_template);
				my $digest = $sha->hexdigest;

				if ( $password eq $digest ) {
					$access           = true;
					$display_password = false;
				}
				else { 
					$access = false; 
					$display_password = true; 
					IntraBox::push_error("Mauvais mot de passe, veuillez ré-essayer.");
				}
			}
			else {
				#Cas 3 - password pas envoyé
				$display_password = true;
				$access           = false;
				IntraBox::push_alert("Veuillez indiquer le mot de passe pour 
				pouvoir télécharger les fichiers");
			}
		}
		else {
			#Cas1 : Pas de password renseigné dans la DB
			$access = true;
			@liste_file =
			IntraBox::push_info("Les fichiers sont disponibles. 
			Vous pouvez les télécharger en cliquant sur le bouton \"Download\".");
		}
		if ($access){
		@liste_file = schema->resultset('File')->search( { id_deposit => "$id_deposit", } );
		}
		template 'download',
		  {
			access           => $access,
			display_password => $display_password,
			liste_file       => \@liste_file,
			deposit_code => $download_code,
		  };
	}
}

sub donwload_file_user {
	my $file_name_disk = $_[0];
	my $file_name      = $_[1];

	#Initialization variables
	my $IP_user;
	my $user_agent;

	#Récupération de l'IP et du useragent de l'utilisateur
	$IP_user    = request->remote_address;
	$user_agent = request->user_agent;

	#Récupération de la date actuelle
	my $current_date = DateTime->now;

	#Récupération du fichier à télécharger
	my $search =
	  schema->resultset('File')->find( { name_on_disk => $file_name_disk } );
	my $id_file = $search->id_file;
	my $id_deposit    = $search->id_deposit;
	my $id_user       = $id_deposit->id_user;
	my $author_login  = $id_user->login;
	my $download_code = $id_deposit->download_code;

		my $new_download = schema->resultset('Download')->create(
			{
				id_file    => $id_file,
				id_deposit => $id_deposit->id_deposit,
				ip         => $IP_user,
				useragent  => $user_agent,
				start_date => $current_date,
			}
		);

		email {
			to      => $author_login . "\@mines-albi.fr",
			from    => 'no_reply@Intrabox.com',
			subject =>
			  "IntraBox : Avis de téléchargement pour le fichier $file_name",
			message =>
"Le fichier $file_name vient d\'être téléchargé par l'utilisateur : $IP_user.\n
Ceci est email automatique. Merci de ne pas y répondre.\n
Ce mail vous est envoyé car vous avez choisi l'option \"Vous avertir lors d'un téléchargement\".\n
Vous pouvez à tout moment enlever cette option, en allant dans l'onglet \"gestion de vos fichier\" puis
\"modifier le dépôt\".",
		};

		#Server send file to client
		send_file("/Upload/$file_name_disk", filename => "$file_name" );
}

#--------- /ROUTEES -------

true;
