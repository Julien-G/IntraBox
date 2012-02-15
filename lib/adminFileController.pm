package IntraBox::adminFileController;
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

prefix '/admin/file';

get '/' => sub {
	
	my $current_date = DateTime->now;
	my $methode_tri      = "created_date";

	my @liste_deposit = schema->resultset('Deposit')->search(
			{
					id_status        => "1",
					expiration_date  => { '>', $current_date }
			},
			{ order_by => "$methode_tri" },
		);
	my $id_deposit;
	for my $deposit_liste (@liste_deposit) {
		$id_deposit = $deposit_liste->id_deposit;
	}


	template 'admin/file', { 
		liste_deposit => \@liste_deposit
		 };
};

return 1;