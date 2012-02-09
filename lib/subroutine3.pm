package subroutine3;

use Dancer ':syntax';
use warnings;
#use strict;
use Exporter;
use base 'Exporter';


#--- /Infos User ---

sub calcul_used_space {
	my $user            = $_[0];
	my $user_space_used = 10 * 1024 * 1024;
	return $user_space_used;
}

sub recuperation_donnees_session_user {
	my $user = $_[0];
	my $isAdmin;
	$user = "abourgan";
	if ( $user eq "abourgan" ) {
		$isAdmin = true;

	}
	else { $isAdmin = false; }

	my $user_group            = "eleves";
	our $user_size_file_limit  = 100 * 1024 * 1024;
	my $user_size_space_limit = 900 * 1024 * 1024;
	return ( $isAdmin, $user_group, $user_size_file_limit,
		$user_size_space_limit );
}

our @EXPORT = qw(recuperation_donnees_session_user calcul_used_space);

1;