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
# Session
#------------------------------------------------------------
my $sess = IntraBox::getSession();

#------------------------------------------------------------
# Routes
#------------------------------------------------------------

prefix '/admin/file';

get '/' => sub {
	
#	my $current_date = Class::Date->new;
#	$current_date = now;
	
	my @valid_files = schema->resultset('Deposit')->search( { expiration_date => undef } )->all;
	
	

	template 'admin/file', { 
		sess => $sess,
		valid_files => \@valid_files
		 };
};

return 1;