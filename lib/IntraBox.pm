package IntraBox;
## PARTIE COMMUNE A TOUS LES CONTROLLEURS
use strict;
use warnings;

# Configuration
use lib '.';
our $VERSION = '0.1';

# Chargement des plugins utiles à Dancer
use Dancer ':syntax';
use Dancer::Plugin::DBIC;

# Chargement des plugins fonctionnels
use Digest::SHA1;
use Class::Date qw(:errors date localdate gmdate now -DateParse);
use Data::FormValidator;
use DBIx::Class::FromValidators;

# Chargement des subroutines
use subroutine;
use subroutine2;
use subroutine3;
## fin PARTIE COMMUNE A TOUS LES CONTROLLEURS

#------------------------------------------------------------
# Quelques outils utilitaires
#------------------------------------------------------------

# gestion des tas de messages 'info' et 'erreur' (il suffit de faire
# appel à 'push-info' ou à 'push_erreur' pour accumuler des messages qui
# seront automatiquement transmis au moteur de template)
{
  # stockage des deux tableaux de messages
  my @infoMsgs;
  my @alertMsgs;
  my @errorMsgs;

  # fonctions pour accumuler des messages
  sub push_info {push @infoMsgs, @_;}
  sub push_alert {push @alertMsgs, @_;}
  sub push_error {push @errorMsgs, @_;}

  # fonctions pour récupérer tous les messages accumulés
  sub all_info {return @infoMsgs};
  sub all_alert {return @alertMsgs};
  sub all_error {return @errorMsgs};

  # fonctions pour vider ces tableaux
  sub reset_info {@infoMsgs = ();}
  sub reset_alert {@alertMsgs = ();}
  sub reset_error {@errorMsgs = ();}

  hook before_template => sub {
    my $tokens = shift;
    # transmission des messages aux vues
    $tokens->{infoMsgs} = [all_info];
    $tokens->{alertMsgs} = [all_alert];
    $tokens->{errorMsgs} = [all_error];
  };

  hook after => sub {
    # vidage des messages après la route
    reset_info;
    reset_alert;
    reset_error;
  };
}

sub getSessionVars {
	#get the remote user login - must be $ENV{'REMOTE_USER'}
	my $login = "lfoucher";
	my $usr;

	#if there is no session, log the user
	if (not session 'id_user') {
		#try to find user in DB, else create it
	    $usr = schema->resultset('User')->find_or_create(
	    	{
	      		login => $login,
	      		admin  => false,
	    	},
	    	{ key => 'login_UNIQUE' }
	  	);

	  	#store the session
	  	session id_user => $usr->id_user;
	  	session	login => $usr->login;
	  	session	isAdmin => $usr->admin;
	}
	
	#calculate the space used by the user
	my $usedSpace = 0;
	my $deposits = schema->resultset('Deposit')->search({ id_user =>  session 'id_user' });
  	while (my $deposit = $deposits->next) {
  		my @files = $deposit->files;
  		for my $file (@files) {
    		if ($file->on_server) {
    			$usedSpace += $file->size;
    		}
  		}
  	}
 	session usedSpace => $usedSpace;
	return session;	
}


my $sess;
hook 'before' => sub {
	$sess = getSessionVars();
  	return 0;
};



# Chargement des controllers
use depositController;
use fileController;
use adminDownloadController;
use adminAdminController;

prefix undef;
#--------- ROUTEES -------
get '/' => sub {
	redirect '/deposit/new';
};

get '/admin' => sub {
	redirect '/admin/download';
};
get '/admin/' => sub {
	redirect '/admin/download';
};

#--- /Infos User ---


true;
