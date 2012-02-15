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

use Data::Dumper;
use Net::LDAP;
#use Unicode::String qw(utf8 latin1 utf16);
my $ldap = Net::LDAP->new( config->{ldapserver} ) or die "Can't bind to ldap: $!\n";

#------------------------------------------------------------
# Routes
#------------------------------------------------------------

prefix '/help';

get '/' => sub {
	template 'help';
};