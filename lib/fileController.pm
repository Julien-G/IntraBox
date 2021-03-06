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
		# Security test : no specials char in param(download_code)
	if (IntraBox::has_specials_char(param("download_code"),"URL") ) {
		IntraBox::push_error("Vérifiez l\'adresse URL, celle ci est corrompue");
		template 'download',{};
	} else {
	my $param_file = param("download_code");
	download_file("$param_file");
	}
};

post '/download/:download_code' => sub {
	my $param_file;
	# Security test : no specials char in param(download_code)
	if (IntraBox::has_specials_char(param("download_code"),"URL") ) {
		IntraBox::push_error("Vérifiez l\'adresse URL, celle ci est corrompue");
		template 'download',{};
	# Security test : no specials char in param(password)
	} elsif (IntraBox::has_specials_char(param("password"),"Password") ) {
		$param_file = param("download_code");
		redirect "file/download/$param_file";		
	} else {
	$param_file = param("download_code");
	download_file("$param_file");
	}
};

post '/downloadFile' => sub {
	# Security test : no specials char in param(name_on_disk)
	if (IntraBox::has_specials_char(param("name_on_disk"),"name_on_disk") ) {
		IntraBox::push_error("Erreur dans la requête POST");
		template 'download',{};
	# Security test : no specials char in param(name)
	} elsif (IntraBox::has_specials_char(param("name"),"name")) {
		IntraBox::push_error("Erreur dans la requête POST");
		template 'download',{};
	} else {
		my $file = schema->resultset('File')->find( { 
			name_on_disk => param("name_on_disk"), 
			name => param("name"),
		} );
		# Security test : name_on_disk must match with name in DB and on server
		if ($file && $file->on_server == 1) { 
			#Success
			donwload_file_user( param("name_on_disk"), param("name"));
			#/Success			
		# Security test : if file not on server
		} elsif ($file && $file->on_server == 0) {
			IntraBox::push_error("Fichier expiré");
			template 'download',{};
		# Security test : if file not match
		} else {
			IntraBox::push_error("Erreur dans la requête POST");
			template 'download',{};
		}
		
	}
	
	
};

sub download_file {
	my $download_code = $_[0];

	#Initatilisation variables
	my $path = config->{pathDownload};
	
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
		$id_status  = $deposit_liste->id_status->id_status;
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
				#Récupération du salage de password
				my $sel_pass = substr($password,0,1);
				$password_template = $sel_pass.$password_template;
				
				#Cryptage
				my $sha = Digest::SHA1->new;
				$sha->add($password_template);
				my $password_template = $sha->hexdigest;
				$password_template = $sel_pass.$password_template;

				if ( $password eq $password_template ) {
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

my $path = config->{pathDownload};
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
	my $acknowledgement = $id_deposit->opt_acknowledgement;
	my $id_user       = $id_deposit->id_user;
	my $author_mail  = $id_user->email;
	my $download_code = $id_deposit->download_code;

		my $new_download = schema->resultset('Download')->create(
			{
				id_file    => $id_file,
				id_deposit => $id_deposit->id_deposit,
				ip         => $IP_user,
				useragent  => $user_agent,
				date => $current_date,
			}
		);

		if ($acknowledgement == 1) {
		email {
			to      => $author_mail,
			from    => config->{mailApp},
			subject => "IntraBox : Avis de 	téléchargement pour le fichier $file_name",
			type => 'html',
			message => template 'mail/reportDownload', {
				mail => true,
				file_name => $file_name,
				pathApp => config->{pathApp},
				IP_user => $IP_user },
			 };
		}
		

		#Server send file to client
		send_file("$path/$file_name_disk", filename => "$file_name" );
}

#--------- /ROUTEES -------

true;
