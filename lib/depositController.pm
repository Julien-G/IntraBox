package IntraBox::depositController;
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

# Get user free space
my $userFreeSpace = $sess->{quota} - $sess->{usedSpace};

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
prefix '/deposit';

#--------- ROUTEES -------
get '/new' => sub {
	IntraBox::push_info(
"Vous pouvez uploader vos fichiers en renseignant tous les champs nécessaires"
	);
	template 'index';
};

post '/new' => sub {
	processUploadFiles();
};

get '/' => sub {
	showAllDeposits();
};

get '/:deposit' => sub {
	my @liste_deposit =
	  schema->resultset('Deposit')
	  ->search( { download_code => param("deposit") } );

	template 'seeDeposit', { liste_deposit => \@liste_deposit };
};

get '/deleteDeposit/:deposit' => sub {
	deleteDeposit( param("deposit") );
	redirect '/deposit/';
};

get '/modifyDeposit/:deposit' => sub {
	my $liste_deposit =
	  schema->resultset('Deposit')
	  ->find( { download_code => param("deposit") } );
	template 'modifyDeposit', { liste_deposit => $liste_deposit };
};

post '/modifyDeposit/:deposit' => sub {
	editDeposit( param("deposit") );
	redirect '/deposit/';
};

#--------- /ROUTEES -------

#my $downloads_report;
#my $acknowlegdement;
#my $password;
#my $comment;
#my $created_date;
#my $expiration_date;
#
#my $deposit_liste;
#my $files_liste;
#
#my $status;
#my $download_code;

# This sub is the default route
sub showAllDeposits {
	my @liste_deposit = schema->resultset('Deposit')->search(
		-and => [ id_user => $sess->{id_user} ],
		{ order_by => "created_date" },
	);

	template 'gestionFichiers', { liste_deposit => \@liste_deposit };
}

# This sub is the delete route
sub deleteDeposit {
	my $deposit       = $_[0];
	my $liste_deposit =
	  schema->resultset('Deposit')->find( { download_code => $deposit } );
	$liste_deposit->id_status('2');
	$liste_deposit->update;
	showAllDeposits();
}

# This sub is the edit route
sub editDeposit {
	my $deposit = $_[0];

	# Get parameters
	my $expiration_days  = param("ext_expiration_days");
	my $downloads_report = ( param("downloads_report") eq "1" ) ? true: false;
	my $acknowlegdement  = ( param("acknowlegdement") eq "1" ) ? true: false;
	my $comment_option   = param("comment_option");
	my $comment          = ( $comment_option eq 1 ) ? param("comment") : undef;

	my $exist_deposit =
	  schema->resultset('Deposit')->find( { download_code => $deposit } );
	my $expiration_date = $exist_deposit->expiration_date;
	$expiration_date->add( days => $expiration_days );
	$exist_deposit->expiration_date("$expiration_date");
	$exist_deposit->opt_acknowledgement("$acknowlegdement");
	$exist_deposit->opt_downloads_report("$downloads_report");
	$exist_deposit->opt_comment("$comment");
	$exist_deposit->update;
}

# This sub is the upload route
sub processUploadFiles {
	my $path =
"/Program Files (x86)/Apache Software Foundation/Apache2.2/cgi-bin/IntraBox/public/Upload";

	my $number_files = count_files();

	if ( $number_files == 0 ) {
		IntraBox::push_alert(
			"Aucun fichier renseigné. Veuillez indiquer un fichier");
	}
	else {

		#------- Init vars ---------
		my @filesToUpload;
		my @hash_names;
		my $depositSize;
		my $controle_valid = 1;

		#------- Get all parameters -------
		my $expiration_days = param("expiration_days");

		# Option to have a downloads report
		my $downloads_report =
		  ( param("downloads_report") eq "1" ) ? true: false;

		# Option to have an acknowlegdement
		my $acknowlegdement = ( param("acknowlegdement") eq "1" ) ? true: false;

		# Option to have a password protection
		my $password_protection = param("password_protection");
		my $password;
		if ( $password_protection eq "1" ) {
			$password = param("password");
			# Password cryptage
			my $sha = Digest::SHA1->new;
			$sha->add($password);
			$password = $sha->hexdigest;
		}
		

		# Option to set a comment
		my $comment_option = param("comment_option");
		my $comment = ( $comment_option eq "1" ) ? param("comment") : undef;

		# Get dates
		my $current_date    = DateTime->now;
		my $expiration_date = DateTime->now;
		$expiration_date->add( days => $expiration_days );

		# Get user info
		my $userIP    = request->remote_address;
		my $userAgent = request->user_agent;

		#------- Browse and validate each file -------
		for ( my $i = 1 ; $i <= $number_files ; $i++ ) {

			$filesToUpload[$i] = upload("file$i");

			# Verify each file validity
			if ( not defined $filesToUpload[$i] ) {
				my $fileName = param("file$i");
				IntraBox::push_alert(
					"Le fichier $fileName n'est pas valide ou n'existe pas");
				$controle_valid = 0;

				# End of loop is a file is invalid ($controle_valid=0)
				last;
			}

			# Valid files
			else {

				# Verify the file size
				if ( $filesToUpload[$i]->size >= $sess->{size_max} ) {
					my $fileName = param("file$i");
					IntraBox::push_error(
						"Le fichier $fileName est trop volumineux");
					$controle_valid = 0;

					# End of loop is a file is too big
					last;
				}

				# Generates a hash for each file
				$hash_names[$i] = generateHash(15);

				# Verify that the hash is unique
				my @filesWithSameHash =
				  schema->resultset('File')
				  ->search( { name_on_disk => $hash_names[$i] } );
				while (@filesWithSameHash) {
					$hash_names[$i] = generateHash(15);
					@filesWithSameHash =
					  schema->resultset('File')
					  ->search( { name_on_disk => $hash_names[$i] } );
				}

				# Increase the deposit size
				$depositSize += $filesToUpload[$i]->size;
			}
		}

		#------- Process the upload -------
		if ( $controle_valid == 1 ) {

			# if the user does not have enough free space
			if ( $depositSize > $userFreeSpace ) {
				IntraBox::push_error(
"Vous n'avez pas assez d'espace libre. Veuillez supprimer des fichiers"
				);

				#Contrôle compte perso
			}
			else {

				# Upload each file
				my $infoMsg =
				    $filesToUpload[1]->basename . " ("
				  . $filesToUpload[1]->size . ")";
				for ( my $i = 1 ; $i <= $number_files ; $i++ ) {

					# Upload the file
					$filesToUpload[$i]->copy_to("$path/$hash_names[$i]");

					# Generate the info message
					$infoMsg =
					    $infoMsg . ", "
					  . $filesToUpload[$i]->basename . " ("
					  . $filesToUpload[$i]->size . ")";
				}
				IntraBox::push_info("Upload terminé des fichiers : $infoMsg");

				# Generate a hash for the deposit
				my $depositHash = generateHash(19);

				# Verify that the hash is unique
				my @depositsWithSameHash =
				  schema->resultset('Deposit')
				  ->search( { download_code => $depositHash } );
				while (@depositsWithSameHash) {
					$depositHash          = generateHash(19);
					@depositsWithSameHash =
					  schema->resultset('Deposit')
					  ->search( { download_code => $depositHash } );
				}

				# Insert deposit in the DB
				my $new_deposit = schema->resultset('Deposit')->create(
					{
						id_user              => $sess->{id_user},
						download_code        => $depositHash,
						id_status            => 1,
						expiration_date      => $expiration_date,
						expiration_days      => $expiration_days,
						opt_acknowledgement  => $acknowlegdement,
						opt_downloads_report => $downloads_report,
						created_date         => $current_date,
						created_ip           => $userIP,
						created_useragent    => $userAgent,
						opt_comment          => $comment,
						opt_password         => $password,
					}
				);

				# Find the id_deposit
				my $deposit =
				  schema->resultset('Deposit')
				  ->find( { download_code => $depositHash } );

				# Insert files in the DB
				for ( my $k = 1 ; $k <= $number_files ; $k++ ) {
					my $newFile = schema->resultset('File')->create(
						{
							id_deposit   => $deposit->id_deposit,
							name         => $filesToUpload[$k]->basename,
							size         => $filesToUpload[$k]->size,
							name_on_disk => $hash_names[$k],
							on_server    => "1",
						}
					);
				}

			}
		}
	}

	template 'index';
}

# This sub counts how many files we need to upload
sub count_files {
	my $cpt = 1;

	# First iteration
	my $file = param("file$cpt");

	# While param exists
	while ( defined $file ) {
		$cpt++;
		$file = param("file$cpt");
	}
	return $cpt - 1;
}

# This sub gets a random position into a string
sub randomPosition {
	my $chaine = $_[0];
	return int rand length $chaine;
}

# This sub generates a random hash
sub generateHash {
	my $lenght = $_[0];
	my $key;
	my $charList =
	  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
	for ( my $i = 1 ; $i < $lenght ; ++$i ) {
		my $tempKey = substr( $charList, randomPosition($charList), 1 );
		$key = "$key$tempKey";
	}
	return $key;
}

true;
