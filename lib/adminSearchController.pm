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

# Load subroutines
use subroutine;
use subroutine2;
use subroutine3;
## end THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS

use Data::Dumper;
use Net::LDAP;
#use Unicode::String qw(utf8 latin1 utf16);
my $ldap = Net::LDAP->new("ldap.enstimac.fr") or die "Can't bind to ldap: $!\n";

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
	my %queryParams;
	my @queryUsrs;
	my @deposits;
	
	# If we do a search on the user login
	if ( params->{opt_login} eq "on" ) {
		
		my @logins = split(/ /, params->{login});
		# try to find a user matching the login
		foreach my $login (@logins) {
			my $usr = schema->resultset('User')->search( { login => $login } )->first;
			if ( defined $usr ) {
				push(@queryUsrs, $usr->id_user);
			}
		}
	}
	# If we do a search on the deposit date
	if ( params->{opt_deposit_date} eq "on" ) {
		
		# get the date in the input
		my @datetime = split(/\//, params->{deposit_date});
		my $month = $datetime[0];
		my $day = $datetime[1];
		my $year = $datetime[2];
		if ( params->{type_deposit_date} eq 'AFTER' ) {
			$queryParams{created_date} = { '>=' => $year.'-'.$month.'-'.$day.' 00:00:00' };
		}
		else {
			$queryParams{created_date} = { '<=' => $year.'-'.$month.'-'.$day.' 00:00:00' };
		}
	}
	# If we do a search on the expiration date
	if ( params->{opt_expiration_date} eq "on" ) {
		
		# get the date in the input
		my @datetime = split(/\//, params->{expiration_date});
		my $month = $datetime[0];
		my $day = $datetime[1];
		my $year = $datetime[2];
		if ( params->{type_expiration_date} eq 'AFTER' ) {
			$queryParams{expiration_date} = { '>=' => $year.'-'.$month.'-'.$day.' 00:00:00' };
		}
		else {
			$queryParams{expiration_date} = { '<=' => $year.'-'.$month.'-'.$day.' 00:00:00' };
		}
	}
	# If we do a search on the user LDAP group
	if ( params->{opt_group} eq "on" ) {
		my @ldapGroups = split(/ /, params->{group});
		for my $ldapGroup (@ldapGroups) {
			#Search all users in a group
			my $mesg = $ldap->search(
				base   => "ou=Groups,dc=enstimac,dc=fr",
				filter => "(cn=$ldapGroup )", #Group
			);
			foreach my $entry ( $mesg->entries ) {
				my @logins = $entry->get_value('rfc822MailMember');
	
				foreach my $login (@logins) {
					my $usr = schema->resultset('User')->search( { login => $login } )->first;
					if ( defined $usr ) {
						push(@queryUsrs, $usr->id_user);
					}
				}
			}
		}			
	}

	# Process the query
	# Distinguish if a list of user is searched
	# this code eliminates doublons
	my (%doublons,@usrIds)=();
	undef %doublons;
	@usrIds = sort(grep(!$doublons{$_}++, @queryUsrs));
	 
	# First case: A list of user
	if (@usrIds > 0) {
		for my $usrId (@usrIds) {
			$queryParams{id_user} = $usrId;
			push(@deposits, schema->resultset('Deposit')->search( { %queryParams } )->all);
		}
	}
	# No user param
	else {
		if ( keys(%queryParams) > 0 ) {
			@deposits = schema->resultset('Deposit')->search( { %queryParams } )->all;
		}
	}
	# If the query returns 0 deposits, display a message
	if (@deposits eq 0) {
		IntraBox::push_alert("La recherche n'a donné aucun résultat.");
	}
	
	template 'admin/search',
	  {
		sess     => $sess,
		deposits => \@deposits,
		params	 => params
	  };
};

return 1;
