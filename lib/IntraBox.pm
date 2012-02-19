package IntraBox;
## THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS
use strict;
use warnings;
use utf8;

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

#Load LDAP plugins
use Data::Dumper;
use Net::LDAP;

## end THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS

#------------------------------------------------------------
# Some useful tools
#------------------------------------------------------------
# The code below allows to put some 'info' or 'alert' or 'error'
# (we only need to call 'IntraBox::push_info' or 'IntraBox::push_alert'
# or 'IntraBox::push_error' to automatically transmit the message
# to the template toolkit
{

	# arrays of messages
	my @infoMsgs;
	my @alertMsgs;
	my @errorMsgs;

	# push the message into the array
	sub push_info  { push @infoMsgs,  @_; }
	sub push_alert { push @alertMsgs, @_; }
	sub push_error { push @errorMsgs, @_; }

	# get the message from the array
	sub all_info  { return @infoMsgs }
	sub all_alert { return @alertMsgs }
	sub all_error { return @errorMsgs }

	# empty the array
	sub reset_info  { @infoMsgs  = (); }
	sub reset_alert { @alertMsgs = (); }
	sub reset_error { @errorMsgs = (); }

	hook before_template => sub {
		my $tokens = shift;

		# transmit messages to views
		$tokens->{infoMsgs}  = [all_info];
		$tokens->{alertMsgs} = [all_alert];
		$tokens->{errorMsgs} = [all_error];
		$tokens->{session}   = getSession();
	};

	hook after => sub {

		# empty arrays
		reset_info;
		reset_alert;
		reset_error;
	};
}

#------------------------------------------------------------
# Session
#------------------------------------------------------------=
# The subroutine getSession sets all sessions vars
# and returns them;
sub getSession {

	#get the remote user login - must be $ENV{'REMOTE_USER'}
	# request->env->{REMOTE_USER}
	my $login = "abourgan";
	my $usr;

	if ( not defined $login ) { }
	else {
		      #if there is no session, log the user
		if ( not session 'id_user' ) {

			#try to find user in DB, else create it
			$usr = schema->resultset('User')->find_or_create(
				{
					login => $login,
					admin => false,
				},
				{ key => 'login_UNIQUE' }
			);

			#Determination du groupe de l'utilisateur
			my $userGroup;
			my $quotaMax = 0;
			my @userGroups;

			my $ldap = Net::LDAP->new( config->{ldapserver} )
			  or die "Can't bind to ldap: $!\n";
			my $mesg = $ldap->bind();
			if ( $mesg->code ) {
				print $mesg->error;
			}

			#Find all groups for a user
			$mesg = $ldap->search(
				base   => "ou=Groups,dc=enstimac,dc=fr",
				filter => "(rfc822MailMember=$login)",
			);

			foreach my $entry ( $mesg->entries ) {
				my $cn = $entry->get_value('cn');
				push( @userGroups, $cn );
			}

			foreach my $grp (@userGroups) {
				my $search =
				  schema->resultset('Usergroup')->find( { rule => $grp } );
				if ($search) {
					my $quota_temp = $search->quota;
					if ( $search->quota > $quotaMax ) {
						$userGroup = $grp;
						$quotaMax  = $search->quota;
					}
				}
			}

			if ( not defined $userGroup ) {
				$userGroup = "default";
			}

			my $group =
			  schema->resultset('Usergroup')->find( { rule => $userGroup } );

			#store the session
			session id_user        => $usr->id_user;
			session login          => $usr->login;
			session isAdmin        => $usr->admin;
			session group          => $group->name;
			session size_max       => $group->size_max;
			session quota          => $group->quota;
			session expiration_max => $group->expiration_max;
		}

		#calculate the space used by the user
		my $usedSpace = 0;
		my $deposits  =
		  schema->resultset('Deposit')
		  ->search( { id_user => session->{id_user}, id_status => 1 } );
		while ( my $deposit = $deposits->next ) {
			my @files = $deposit->files;
			for my $file (@files) {
				$usedSpace += $file->size;
			}
		}
		session usedSpace => $usedSpace;
		return session;
	}
}

#------------------------------------------------------------
# Controllers
#------------------------------------------------------------
# Load controllers
use depositController;
use fileController;
use helpController;
use adminDownloadController;
use adminAdminController;
use adminGroupController;
use adminSearchController;
use adminFileController;
use purgeController;

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
prefix undef;

get '/' => sub {
	redirect '/deposit/new';
};

get '/admin' => sub {
	redirect '/admin/download';
};
get '/admin/' => sub {
	redirect '/admin/download';
};

true;
