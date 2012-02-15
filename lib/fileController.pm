package IntraBox::fileController;
## THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS
use strict;
use warnings;

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
my $user_size_file_limit =$sess->{size_max};
my $user_size_space_limit =$sess->{quota};
my $user_space_used = $sess->{usedSpace};
my $user_space_free = $user_size_space_limit - $user_space_used;


get '/download/:file_name' => sub {
	my $param_file = param("file_name");
	download_file($param_file);
};

post '/downloadFile' => sub {

	my $name_on_disk = param("name_on_disk");
	my $name         = param("name");
	donwload_file_user( $name_on_disk, $name );

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
	  schema->resultset('Deposit')
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
		template 'download',
		  { sess => $sess, message => $message };

	}

	#Envoi d'un message d'erreur si fichier non disponible
	elsif ( !$download_available ) {
		$message = $message_indispo;
		template 'download',
		  {
			sess    => $sess,
			message => $message
		  };
	}

	#Si les fichiers sont bien présents et disponible
	else {

#On récupère toutes les informations du fichiers présent dans la base de données

		my $cpt_file;
		my $file_liste;

		my @liste_file =
		  schema->resultset('File')->search( { id_deposit => "$id_deposit", } );
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
			liste_file => \@liste_file,
			sess => $sess,
		  };
	}
}

sub donwload_file_user {
	my $file_name_disk = $_[0];
	my $file_name      = $_[1];

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

	my $new_download = schema->resultset('Download')->create(
		{
			id_file    => $id_file,
			id_deposit => $id_deposit,
			ip         => $IP_user,
			useragent  => $user_agent,
			start_date => $current_date,
			sess => $sess,
		}
	);

	send_file( "/Upload/$file_name_disk", filename => "$file_name" );

	$current_date = DateTime->now;
	$new_download->end_date("$current_date");
	$new_download->finished("1");
	$new_download->update;
}

#--------- /ROUTEES -------

true;
