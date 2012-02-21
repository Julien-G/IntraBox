package IntraBox::adminStatsController;
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
prefix '/admin/stats';

# returns the stats
get '/' => sub {
	if ( $sess->{isAdmin} == 0 ) {
		IntraBox::push_error(
"Cette section est réservée aux administrateurs. <a href=\"config->{pathApp}\">Cliquez-ici</a> pour retourner à l'application."
		);
		template 'avert', {};
	}
	else {
		my $lastYear = DateTime->now;
		$lastYear->subtract( years => 1 );
		my @depositsLastYear =
		  schema->resultset('Deposit')
		  ->search( { created_date => { '>=', $lastYear } } )->all;
		my @downloadsLastYear =
		  schema->resultset('Download')
		  ->search( { date => { '>=', $lastYear } } )->all;
		template 'admin/stats',
		  {
			depositsLastYear  => \@depositsLastYear,
			downloadsLastYear => \@downloadsLastYear
		  };
	}
};

return 1;
