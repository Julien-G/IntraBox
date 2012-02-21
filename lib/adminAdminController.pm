package IntraBox::adminAdminController;
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
# Routes
#------------------------------------------------------------
prefix '/admin/admin';

get '/' => sub {
	my @admins = schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin', { admins => \@admins };
};

post '/new' => sub {

	# validation des paramètres
	my $params = request->params;
	my $msgs;
	my $control_valid = 1;
	
	if (IntraBox::has_specials_char(param('login'),"Login") ) {$control_valid = 0;}
	
	if ($control_valid == 1){
	# recherche de l'admin à ajouter
	my $admin =
	  schema->resultset('User')->search( { login => param('login') } )
	  ->first();
	if ( not defined $admin ) {
		my $login = param('login');
		IntraBox::push_error "Il n'y a pas d'utilisateur correspondant au login <strong>$login</strong>";
	}
	else {
		my $login = $admin->login;
		IntraBox::push_info "Vous venez d'ajouter l'administrateur <strong>$login</strong>";
		$admin->update( { admin => true } );
	}
	}
	my @admins = schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin',
	  {
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
		IntraBox::push_alert "Il n'y a pas d'utilisateur à l'ID <strong>$id</strong>";
	}
	else {
		my $login = $admin->login;
		IntraBox::push_alert "Vous venez de retirer l'administrateur <strong>$login</strong>";
		$admin->update( { admin => false } );
	}

	my @admins = schema->resultset('User')->search( { admin => true } )->all;
	template 'admin/admin',
	  {
		admins  => \@admins
	  };
};

return 1;