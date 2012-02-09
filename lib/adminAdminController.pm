package IntraBox::adminAdminController;
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

prefix '/admin/admin';

my $sess = IntraBox::getSessionVars();

get '/' => sub {
	IntraBox::push_info "Salut";
	my @admins = schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin', { sess => $sess, admins => \@admins };
};

post '/new' => sub {

	# validation des paramètres
	my $params = request->params;
	my $msgs;

	# recherche de l'admin à ajouter
	my $admin =
	  schema->resultset('User')->search( { login => param('login') } )
	  ->first();
	if ( not defined $admin ) {
		my $login = param('login');
		IntraBox::push_alert "Il n'y a pas d'utilisateur correspondant au login <strong>$login</strong>";
		$msgs =
		  { alert =>
"Il n'y a pas d'utilisateur correspondant au login <strong>$login</strong>"
		  };
	}
	else {
		my $login = $admin->login;
		IntraBox::push_info "Vous venez d'ajouter l'administrateur <strong>$login</strong>";
		$msgs =
		  { info =>
			  "Vous venez d'ajouter l'administrateur <strong>$login</strong>" };
		$admin->update( { admin => true } );
	}

	my @admins = schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin',
	  {
		sess => $sess,
		msgs    => $msgs,
		admins  => \@admins
	  };
};

get qr{/delete/(?<id>\d+)} => sub {

	my $msgs;
	my $id = captures->{'id'};    # le paramètre id est dans l'URL
	delete params->{captures};

	# recherche de l'admin à supprimer
	my $admin = schema->resultset('User')->find($id);
	if ( not defined $admin ) {
		$msgs =
		  { alert =>
			  "Il n'y a pas d'utilisateur à l'ID <strong>$id</strong>" };
	}
	else {
		my $login = $admin->login;
		$msgs =
		  { warning =>
			  "Vous venez de retirer l'administrateur <strong>$login</strong>"
		  };
		$admin->update( { admin => false } );
	}

	my @admins = schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin',
	  {
		sess => $sess,
		msgs    => $msgs,
		admins  => \@admins
	  };
};

return 1;