package IntraBox::adminDownloadController;
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

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
prefix '/admin/download';

get '/' => sub {
	my @downloadsInProgress = schema->resultset('Download')->search( { end_date => undef } )->all;
	my @downloads;
	
	for my $dl (@downloadsInProgress) {
		my $file = $dl->file;
		my $deposit = $file->id_deposit;
		my $user = $deposit->id_user;
		my @dls = $file->downloads;
		my $dls_count = 0;
		for my $each_dl (@dls) {
			$dls_count++;
		}
		push (@downloads, { 
			file => $file,
			deposit => $deposit,
			start_date => Class::Date->new( $dl->start_date ),
			user => $user,
			dl => $dl,
			dls_count => $dls_count
		});
	}
	IntraBox::push_info("Voici la liste des téléchargements en cours.");
	template 'admin/download', { downloads => \@downloads };
};

return 1;