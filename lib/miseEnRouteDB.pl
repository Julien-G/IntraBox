package IntraBox;
use Dancer ':syntax';
use strict;
use warnings;

use lib '.';
use DB::intrabox;
use DBI;

our $VERSION = '0.1';

# Connexion à la base de données
my $dsn    = "dbi:mysql:intrabox";
my $schema = DB::intrabox->connect( $dsn, "", "" ) or die "problem";

#my $new_status =
#  $schema->resultset('Usergroup')->create( { 
#  	rule_type => "LDAP",
#  	name => "Default",
#  	rule => "default",
#  	quota => "100000",
#  	size_max => "150000",
#  	expiration_max=>"2", 	 
#  } );

#my $user = $schema->resultset('User')->create( {
#	login => "exterior",
#	admin => "0",
#} );
  
  


