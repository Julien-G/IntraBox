package IntraBox::depositController;
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

# Load subroutines
use subroutine;
use subroutine2;
use subroutine3;
## end THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS

#------------------------------------------------------------
# Session
#------------------------------------------------------------
my $sess = IntraBox::getSession();

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
prefix '/deposit';

# DEPRECATED
my $user ="abourgan";
#Vérification si il est admin
#Récupération du groupe dans lequel il est
#Récupération de la taille maximale de son espace personnel et fichier
my $id_user;
my $isAdmin;
my $user_group;
my $user_size_file_limit;
my $user_size_space_limit;
( $isAdmin, $user_group, $user_size_file_limit, $user_size_space_limit ) =
  recuperation_donnees_session_user($user);

# DEPRECATED
#Récupération de la taille actuelle utilisée de son espace personnel
my $user_space_used;
$user_space_used = calcul_used_space($user);
#Calcul de l'espace libre de user
my $user_space_free = $user_size_space_limit - $user_space_used;

#--------- ROUTEES -------
get '/new' => sub {
	my $info_color = "info-vert";
	my $message    = "Vous pouvez uploader vos fichiers en renseignant tous les champs nécessaires";
	template 'index',
	  {
	  	sess				  => $sess,
		info_color            => $info_color,
		message               => $message
	  };
};

post '/upload' => sub {
	processUploadFiles();
};

get '/' => sub {
	gestion_all_fichiers();
};

post '/' => sub {
	my $choix_tri = param("choix_tri");
	my $choix_show_expir = param("choix_show_expir");
	gestion_all_fichiers("$choix_tri", "$choix_show_expir");
};

get '/:deposit' => sub {
	my $param_file = param("deposit");
	afficher_depot($param_file);
};

get '/supprimerDepot/:deposit' => sub {
	my $param_file = param("deposit");
	supprimer_depot($param_file);
	redirect '/deposit/';
};

get '/modifierDepot/:deposit' => sub {
	my $param_file = param("deposit");
	afficher_modifier_depot($param_file);
};

post '/modifierDepot/:deposit' => sub {
	my $param_file = param("deposit");
	modifier_depot($param_file);
	redirect '/';
};


#--------- /ROUTEES -------

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

sub gestion_all_fichiers {
	my $methode_tri      = $_[0];
	my $choix_show_expir = $_[1]; 
	
	if (not defined $methode_tri) {$methode_tri = "created_date"}
	if (not defined $choix_show_expir) {$choix_show_expir = "false"}

	my $login_user = "abourgan";
	my $id_user;

	my @liste_user =
	  schema->resultset('User')->search( { login => "$login_user", } );

	for my $user_liste (@liste_user) {
		$id_user = $user_liste->id_user;
	}
	my $current_date = DateTime->now;
	my @liste_deposit;

	if ( $choix_show_expir eq "true" ) {
		@liste_deposit = schema->resultset('Deposit')->search(
			-and => [
					id_user         => "$id_user",
					area_access_code       => ,
				],
			{ order_by => "$methode_tri" },
		);

	}
	else {
		@liste_deposit = schema->resultset('Deposit')->search(
			{
				-and => [
					id_user         => "$id_user",
					id_status       => "1",
					expiration_date => { '>', $current_date },
					area_access_code       => ,
				],
			},
			{ order_by => "$methode_tri" },
		);
	}

	for my $deposit_liste (@liste_deposit) {
		$id_deposit = $deposit_liste->id_deposit;
	}
	template 'gestionFichiers', {
		liste_deposit    => \@liste_deposit,
		choix_show_expir => $choix_show_expir,
	};
}

sub afficher_depot {
	my $deposit = $_[0];

	my @liste_deposit =
	  schema->resultset('Deposit')->search( { download_code => $deposit, } );
	template 'voirDepot', { liste_deposit => \@liste_deposit, };
}

sub supprimer_depot {
	my $deposit       = $_[0];
	my $liste_deposit =
	  schema->resultset('Deposit')->find( { download_code => $deposit } );
	$liste_deposit->id_status('2');
	$liste_deposit->update;
	gestion_all_fichiers();
}

sub afficher_modifier_depot {

	my $deposit = $_[0];

	my $liste_deposit =
	  schema->resultset('Deposit')->find( { download_code => $deposit } );
	template 'modifierDepot', { liste_deposit => $liste_deposit, };

}

sub modifier_depot {
	my $deposit = $_[0];

	my $expiration_days;
	my $downloads_report;

	my $comment_option;
	my $comment;

	my $expiration_date;
	my $expiration_days_date;
	my $id_status;

	#------- Phase de récupération de tous les paramètres -------
	$expiration_days  = param("ext_expiration_days");
	$downloads_report = param("downloads_report");
	if ( $downloads_report eq "1" ) { $downloads_report = true }
	else { $downloads_report = false }
	$acknowlegdement = param("acknowlegdement");
	if ( $acknowlegdement eq "1" ) { $acknowlegdement = true }
	else { $acknowlegdement = false }

	$comment_option = param("comment_option");
	if ( $comment_option eq "1" ) { $comment_option = true }
	else { $comment_option = false }
	if ($comment_option) { $comment = param("comment"); }
	my $exist_deposit =
	  schema->resultset('Deposit')->find( { download_code => $deposit } );
	$expiration_date = $exist_deposit->expiration_date;
	$expiration_date->add( days => $expiration_days );
	$exist_deposit->expiration_date("$expiration_date");
	$exist_deposit->opt_acknowledgement("$acknowlegdement");
	$exist_deposit->opt_downloads_report("$downloads_report");
	$exist_deposit->opt_comment("$comment");
	$exist_deposit->update;
}


#--- UPLOAD ----
sub processUploadFiles {

	my $message;
	my $info_color;

	my $number_files = count_files();

	if ( $number_files == 0 ) {
		$info_color = "info-rouge";
		$message    = "Aucun fichier renseigné. Veuillez indiquer un fichier";
	}
	else {

		#------- Initialisation variables ---------
		my $i;
		my @upload_files;
		my @size_files;
		my @name_files;
		my @hash_names;
		my $total_size;
		my $id_deposit;

		my $controle_valid = 1;

		my $expiration_days;
		my $downloads_report;
		my $acknowlegdement;
		my $password_protection;
		my $password;
		my $comment_option;
		my $comment;
		my $current_date;
		my $expiration_date;
		my $expiration_days_date;
		my $id_status;

		#------- Phase de récupération de tous les paramètres -------
		my $IP_user;
		my $user_agent;

		#------- Phase de récupération de tous les paramètres -------
		$expiration_days  = param("expiration_days");
		$downloads_report = param("downloads_report");
		if ( $downloads_report eq "1" ) { $downloads_report = true }
		else { $downloads_report = false }
		$acknowlegdement = param("acknowlegdement");
		if ( $acknowlegdement eq "1" ) { $acknowlegdement = true }
		else { $acknowlegdement = false }
		$password_protection = param("password_protection");
		if ( $password_protection eq "1" ) { $password_protection = true }
		else { $password_protection = false }
		if ($password_protection) { $password = param("password"); }
		$comment_option = param("comment_option");
		if ( $comment_option eq "1" ) { $comment_option = true }
		else { $comment_option = false }
		if ($comment_option) { $comment = param("comment"); }

		$current_date    = DateTime->now;
		$expiration_date = DateTime->now;
		$expiration_date->add( days => $expiration_days );
		
		$IP_user = request -> remote_address;
		$user_agent = request -> user_agent;
		
		#------- Phase d'upload de tous les fichiers -------
		for ( $i = 1 ; $i <= $number_files ; $i++ ) {

			$upload_files[$i] = upload("file$i");

			#Verification validité de chaque fichier
			if ( not defined $upload_files[$i] ) {

				#Si un fichier invalide, sorti de boucle et
				#passage du paramètre de contrôle à 0
				$info_color = "info-rouge";
				my $temp_name_fic_prob = param("file$i");
				$message = "Le fichier $temp_name_fic_prob n'est 
								pas valide ou n'existe pas";
				$controle_valid = 0;
				last;
			}
			else {

				$size_files[$i] = $upload_files[$i]->size;
				$name_files[$i] = $upload_files[$i]->basename;

				$hash_names[$i] = generate_aleatoire_key(15);

				#Vérification de l'unicité de la clé du fichier
				my @liste_file =
				  schema->resultset('File')
				  ->search( { name_on_disk => "$hash_names[$i]", } );
				while (@liste_file) {
					$hash_names[$i] = generate_aleatoire_key(15);
					@liste_file =
					  schema->resultset('File')
					  ->search( { name_on_disk => "$hash_names[$i]", } );
				}

				$total_size = $total_size + $size_files[$i];

				if ( $size_files[$i] >= $user_size_file_limit ) {
					$info_color = "info-rouge";
					my $temp_name_fic_prob = param("file$i");
					$message = "Le fichier $temp_name_fic_prob 
									est trop volumineux";
					$controle_valid = 0;
					last;
				}
			}
		}

		#------- Phase de contrôle -------
		if ( $controle_valid == 1 ) {
			if ( $total_size > 100 * 1024 * 1024 ) {
				$info_color = "info-rouge";
				$message    = "Les fichiers sont trop volumineux";

				#Contrôle compte perso
			}
			else {

				#Vérification présence base données
				#--
				#Insertion dans base de données
				#--

				for ( $i = 1 ; $i <= $number_files ; $i++ ) {
					$upload_files[$i]->copy_to(
"/Program Files (x86)/Apache Software Foundation/Apache2.2/cgi-bin/IntraBox/public/Upload/$hash_names[$i]"
					);
				}
				my $j;
				my $temp_message = "$name_files[1] ($size_files[1])";
				for ( $j = 2 ; $j <= $number_files ; $j++ ) {
					$temp_message =
					  "$temp_message, $name_files[$j] ($size_files[$j])";
				}
				$info_color = "info-vert";

				$message = "Upload terminé des fichiers : $temp_message";

				#Création d'une clé de dépôt
				my $deposit_key = generate_aleatoire_key(19);

				#Vérification de l'unicité de la clé
				my @liste_deposit =
				  schema->resultset('Deposit')
				  ->search( { download_code => "$deposit_key", } );
				while (@liste_deposit) {
					$deposit_key   = generate_aleatoire_key(19);
					@liste_deposit =
					  schema->resultset('Deposit')
					  ->search( { download_code => "$deposit_key", } );
				}

				#Ecriture dans la base de données
				my @liste_user =
				  schema->resultset('User')->search( { login => "$user", } );
				for my $user_liste (@liste_user) {
					$id_user = $user_liste->id_user;
				}

				my @liste_status =
				  schema->resultset('Status')
				  ->search( { id_status => '1', } );
				for my $status_liste (@liste_status) {
					$id_status = $status_liste->id_status;
				}

				my $new_deposit = schema->resultset('Deposit')->create(
					{
						id_user              => $id_user,
						download_code        => $deposit_key,
						id_status            => $id_status,
						expiration_date      => $expiration_date,
						expiration_days      => $expiration_days,
						opt_acknowledgement  => $acknowlegdement,
						opt_downloads_report => $downloads_report,
						created_date         => $current_date,
						created_ip           => $IP_user,
						created_useragent    => $user_agent,
						opt_comment          => $comment,
						opt_password         => $password,
					}
				);

				#Recherche de l'id_deposit
				my @liste_deposit2 =
				  schema->resultset('Deposit')
				  ->search( { download_code => "$deposit_key", } );
				for my $deposit_liste (@liste_deposit2) {
					$id_deposit = $deposit_liste->id_deposit;
				}

				#Ecriture dans la base de données des fichiers
				my $k;
				for ( $k = 1 ; $k <= $number_files ; $k++ ) {
					my $new_file = schema->resultset('File')->create(
						{
							id_deposit   => $id_deposit,
							name         => $name_files[$k],
							size         => $size_files[$k],
							name_on_disk => $hash_names[$k],
							on_server    => "1",
						}
					);
				}

			}
		}
	}

	template 'index', {
		sess	   => $sess,
		message    => $message,
		info_color => $info_color,

	};
}

sub count_files {
	my $cpt = 1;

	#Première itération
	my $temp_fic = param("file$cpt");
	if ( not defined $temp_fic ) {
		return 0;
	}
	else {

		#Tant qu'il existe un paramètre on continue la boucle
		while ( defined $temp_fic ) {
			$cpt++;
			$temp_fic = param("file$cpt");
		}
		my $number_files = $cpt - 1;
		return $number_files;
	}
}

sub randomposition {
	my $chaine = $_[0];
	return int rand length $chaine;
}

sub generate_aleatoire_key {
	my $lenght = $_[0];
	my $key;
	my $i;
	my $list_char =
	  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
	for ( $i = 1 ; $i < $lenght ; ++$i ) {
		my $temp_key = substr( $list_char, randomposition($list_char), 1 );
		$key = "$key$temp_key";
	}
	return $key;
}

true;