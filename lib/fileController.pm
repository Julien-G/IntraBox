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
use Class::Date qw(:errors date localdate gmdate now -DateParse);
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
prefix '/file';

# DEPRECATED
my $user ="jgirault";
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



get '/download/:file_name' => sub {
	my $param_file = param("file_name");
	download_file($param_file);
};

post '/downloadFile' => sub {

	my $name_on_disk = param("name_on_disk");
	my $name = param("name");
	donwload_file_user($name_on_disk,$name);
	
};

get '/gestionFichiers' => sub {
	gestion_all_fichiers();
};

get '/voirDepot/:deposit' => sub {
	my $param_file = param("deposit");
	afficher_depot($param_file);
};



#--------- /ROUTEES -------


true;