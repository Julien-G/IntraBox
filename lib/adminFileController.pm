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
	if ( $sess->{isAdmin} == 0 ) {
		IntraBox::push_error(
"Cette section est réservée aux administrateurs. <a href=\"config->{pathApp}\">Cliquez-ici</a> pour retourner à l'application."
		);
		template 'avert', {};
	}
	else {
		my $current_date = DateTime->now;

		my @liste_deposit = schema->resultset('Deposit')->search(
			{
				id_status       => "1",
				expiration_date => { '>', $current_date }
			},
			{ order_by => "created_date" },
		);
		my $id_deposit;
		for my $deposit_liste (@liste_deposit) {
			$id_deposit = $deposit_liste->id_deposit;
		}

		template 'admin/file', { liste_deposit => \@liste_deposit };
	}
};

get '/:deposit' => sub {
	if ( $sess->{isAdmin} == 0 ) {
		IntraBox::push_error(
"Cette section est réservée aux administrateurs. <a href=\"config->{pathApp}\">Cliquez-ici</a> pour retourner à l'application."
		);
		template 'avert', {};
	}
	else {
		my @liste_deposit =
		  schema->resultset('Deposit')
		  ->search( { download_code => param("deposit") } );

		template 'seeDeposit', { liste_deposit => \@liste_deposit };
	}
};

get '/modifyAdminDeposit/:deposit' => sub {
	if ( $sess->{isAdmin} == 0 ) {
		IntraBox::push_error(
"Cette section est réservée aux administrateurs. <a href=\"config->{pathApp}\">Cliquez-ici</a> pour retourner à l'application."
		);
		template 'avert', {};
	}
	else {
		my $liste_deposit =
		  schema->resultset('Deposit')
		  ->find( { download_code => param("deposit") } );
		template 'admin/modifyAdminDeposit',
		  { liste_deposit => $liste_deposit };
	}
};

post '/modifyAdminDeposit/:deposit' => sub {
	if ( $sess->{isAdmin} == 0 ) {
		IntraBox::push_error(
"Cette section est réservée aux administrateurs. <a href=\"config->{pathApp}\">Cliquez-ici</a> pour retourner à l'application."
		);
		template 'avert', {};
	}
	else {
		editDeposit( param("deposit") );
		redirect '/admin/file/';
	}
};

get '/deleteDeposit/:deposit' => sub {
	if ( $sess->{isAdmin} == 0 ) {
		IntraBox::push_error(
"Cette section est réservée aux administrateurs. <a href=\"config->{pathApp}\">Cliquez-ici</a> pour retourner à l'application."
		);
		template 'avert', {};
	}
	else {
		my $deposit       = param("deposit");
		my $liste_deposit =
		  schema->resultset('Deposit')->find( { download_code => $deposit } );
		$liste_deposit->id_status('2');
		$liste_deposit->update;
		redirect '/admin/file/';
	}
};

# This sub is the edit route
sub editDeposit {
	my $deposit = $_[0];

	# Get parameters
	my $downloads_report = ( param("downloads_report") eq "1" ) ? true: false;
	my $acknowlegdement  = ( param("acknowlegdement")  eq "1" ) ? true: false;
	my $comment_option   = param("comment_option");
	my $comment = ( $comment_option eq 1 ) ? param("comment") : undef;

	my $exist_deposit =
	  schema->resultset('Deposit')->find( { download_code => $deposit } );
	$exist_deposit->opt_acknowledgement("$acknowlegdement");
	$exist_deposit->opt_downloads_report("$downloads_report");
	$exist_deposit->opt_comment("$comment");
	$exist_deposit->update;
}

return 1;
