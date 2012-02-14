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

prefix '/admin/search';

get '/' => sub {

	template 'admin/search', { sess => $sess, };
};

post '/new' => sub {
	my $name_user       = param("name_user");
	my $type_search1    = param("type_search1");
	my $option1			= param("option1");
	my $group           = param("group");
	my $type_search2    = param("type_search2");
	my $date_deposit    = param("date_deposit");
	my $type_search3    = param("type_search3");
	my $date_expiration = param("date_expiration");
	my $type_search4    = param("type_search4");
	my $name_file       = param("name_file");
	my $type_search5    = param("type_search5");
	my $size            = param("size");
	my $type_search6    = param("type_search6");
#	my $params          = params;

#	if ( $option1.checked == 'checked'){
#		my $string =~ s/\s+//g;
#		$name_user = $string;
#		if($type_search1 eq "AND"){}
#		elsif($type_search1 eq "OR"){}
#		else{}
#	}



	  # recherche du groupe à ajouter
	  #	my @searches =
	  #	  $schema->resultset('User join Usergroup join Deposit join File')
	  #	  ->search(
	  #		{
	  #			login => $name_user,
	  #			rule  => $group,
	  #			id_deposit	=> true,
	  #			created_date    => $date_deposit,
	  #			expiration_date => $date_expiration,
	  #			name	=> true,
	  #			expiration_max => $size,
	  #		}
	  #	  );

#	  my $usr =schema->resultset('User')->search( { login => $name_user } )->first;
#
#	if ( $usr->id_user ) {
#
#		my $deposits = $usr->deposits;
#
#		while ( my $deposit = $deposits->next() ) {
#			$deposit->id_user->login;
#			my @files = $deposit->files;
#			for my $file (@files) {
#
#			}
#		}
#		
#	}
	my @deposits = schema->resultset('Deposit')->search({ })->all;
	template 'admin/search',
	  {
		sess     => $sess,
		deposits => \@deposits
	  };
};

return 1;
