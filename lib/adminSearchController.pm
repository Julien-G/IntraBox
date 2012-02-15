package IntraBox::adminSearchController;
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

prefix '/admin/search';

get '/' => sub {
	template 'admin/search', { sess => $sess, };
};

post '/' => sub {
	my @deposits;

	# If we do a search on the user login
	if ( params->{opt_login} == "on" ) {
		IntraBox::push_info("Recherche sur le login");

		# try to find a user matching the login
		my $usr =
		  schema->resultset('User')->search( { login => params->{login} } )
		  ->first;
		if ( defined $usr ) {

			# if type is OR, we add all the user deposits to the deposit list
			if ( params->{type_login} == 'OR' ) {
				push( @deposits, $usr->deposits );
			}
		}
	}

# If we do a search on the deposit date
#	if (params->{opt_deposit_date} == "on") {
#		IntraBox::push_info("Recherche sur le groupe d'utilisateur");
#
#		# try to find a user matching the login
#		my $usr = schema->resultset('User')->search({ login => params->{login} })->first;
#		if (defined $usr) {
#			# if type is OR, we add all the user deposits to the deposit list
#			if (params{type_login}=='OR') {
#				push (@deposits, $usr->deposits);
#			}
#		}
#	}
#my @deposits = schema->resultset('Deposit')->search({ })->all;
	template 'admin/search',
	  {
		sess     => $sess,
		deposits => \@deposits
	  };
};

return 1;
