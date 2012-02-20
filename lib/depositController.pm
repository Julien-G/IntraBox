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
#use DBIx::Class::FromValidators;

use Dancer::Plugin::Email;
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
	my $deposit =
	  schema->resultset('Deposit')
	  ->find( { download_code => param("deposit") } );
	 # Test : Utilisator must be Author
	if ($deposit->id_user->id_user eq $sess->{id_user}) {
		template 'seeDeposit', { liste_deposit => $deposit };
	} else {
		IntraBox::push_error("Vous n\'êtes pas propriétaire de ce fichier !");
		template 'avert',{};
	}
	
};

get '/deleteDeposit/:deposit' => sub {
	deleteDeposit( param("deposit") );
	redirect '/deposit/';
};

get '/modifyDeposit/:deposit' => sub {
	my $deposit =
	  schema->resultset('Deposit')
	  ->find( { download_code => param("deposit") } );
	  # Test : Utilisator must be Author
	if ($deposit->id_user->id_user eq $sess->{id_user}) {
		template 'modifyDeposit', { liste_deposit => $deposit };
	} else {
		IntraBox::push_error("Vous n\'êtes pas propriétaire de ce fichier !");
		template 'avert',{};
	}
};

post '/modifyDeposit/:deposit' => sub {
	editDeposit( param("deposit") );
	
};

#--------- /ROUTEES -------

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
	my $id_user = $liste_deposit->id_user->id_user;
	# Test : Utilisator must be Author
	if  ($id_user eq $sess->{id_user}){
		$liste_deposit->id_status('2');
		$liste_deposit->update;
		warn_user($deposit);
		showAllDeposits();
	} else {
		IntraBox::push_error("Vous n\'êtes pas propriétaire de ce fichier !");
		template 'avert',{};
	}
		
}

#Programme d'avertissement de l'utilisateur de son dépôt terminé
sub warn_user {
	my $deposit = $_[0];

	my $depositJustExpired =
	  schema->resultset('Deposit')->find( { download_code => $deposit } );
	my $id_user      = $depositJustExpired->id_user;
	my $author_login = $id_user->login;

	if ( $depositJustExpired->opt_downloads_report == 1 ) {
		my $id_deposit = $depositJustExpired->id_deposit;

		#Recuperation des téléchargements effectués
		my @downloads =
		  schema->resultset('Download')
		  ->search( { id_deposit => $id_deposit, } );

		email {
			to      => $author_login . "\@mines-albi.fr",
			from    => config->{mailApp},
			subject => "IntraBox : Rapport de téléchargement",
			type => 'html',
			message => template 'mail/reportDeposit', {
				mail => true,
				pathApp => config->{pathApp},
				downloads => \@downloads,},
			 };
	}
}

# This sub is the edit route
sub editDeposit {
	my $deposit = $_[0];
	
	my $control_valid = 1;

	# Get parameters
	my $downloads_report = ( param("downloads_report") eq "1" ) ? true: false;
	my $acknowlegdement  = ( param("acknowlegdement")  eq "1" ) ? true: false;
	my $comment_option   = param("comment_option");
	my $comment = ( $comment_option eq 1 ) ? param("comment") : undef;
	if (IntraBox::has_specials_char($comment,"Commentaire") ) {$control_valid = 0;}
	
	if ($control_valid == 1) {
		my $exist_deposit =
		  schema->resultset('Deposit')->find( { download_code => $deposit } );
		if ($exist_deposit->id_user->id_user eq $sess->{id_user}) {
			# Test : Utilisator must be Author
			$exist_deposit->opt_acknowledgement("$acknowlegdement");
			$exist_deposit->opt_downloads_report("$downloads_report");
			$exist_deposit->opt_comment("$comment");
			$exist_deposit->update;
			redirect '/deposit/';
		
		} else {
			IntraBox::push_error("Vous n\'êtes pas propriétaire de ce fichier !");
			template 'avert',{};
		}
	} else { 
		redirect "deposit/modifyDeposit/$deposit" ;
	}
	

}

# This sub is the upload route
sub processUploadFiles {

	my $path = config->{pathUpload};

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
		my $control_valid = 1;
		
		my $current_date;
		my $expiration_date;

		my $userIP;
		my $userAgent;
		my $content_length;

		#------- Get all parameters -------
		my $expiration_days = param("expiration_days");
		if ( $expiration_days > $sess->{expiration_max} ) {
			$control_valid = 0;
			IntraBox::push_error(
				"La valeur entrée pour la date d'expiration est trop grande");
		}
		
		# Option to have a downloads report
		my $downloads_report = ( param("downloads_report") eq "1" ) ? true: false;

		# Option to have an acknowlegdement
		my $acknowlegdement = ( param("acknowlegdement") eq "1" ) ? true: false;

		# Option to have a password protection
		my $password_protection = ( param("password_protection") ) ? param("password_protection") : undef;
		my $password;

		# Option to set a comment
		my $comment_option = param("comment_option");
		my $comment = ( $comment_option eq "1" ) ? param("comment") : undef;
		
		# Test parameters		
		if (IntraBox::has_specials_char($expiration_days,"Date d\'expiration") ) {$control_valid = 0;}
		if (IntraBox::is_empty($expiration_days,"Date d\'expiration")) {$control_valid = 0;}
		if (IntraBox::is_number($expiration_days,"Date d\'expiration")) {} else { $control_valid = 0;}	
		if (IntraBox::has_specials_char(param("comment"),"Commentaire")) {$control_valid = 0;}
		if (IntraBox::has_specials_char(param("password"),"Password")) {$control_valid = 0;}
		for ( my $i = 1 ; $i <= $number_files ; $i++ ) {
			if (IntraBox::has_specials_char(param("file$i"),"Fichier$i")) {$control_valid = 0;}
		}
		
		if ($control_valid == 1) {
			# Get dates
			$current_date    = DateTime->now;
			$expiration_date = DateTime->now;
			$expiration_date->add( days => $expiration_days );
	
			# Get user info
			$userIP    = request->remote_address;
			$userAgent = request->user_agent;
			$content_length = request->content_length;
			
			
			if ( $content_length > $userFreeSpace ) {
				IntraBox::push_error("Vous n'avez pas assez d'espace libre. Il vous reste " . sprintf("%02.2f", $userFreeSpace/1048576) ." Mo. Veuillez supprimer des fichiers.");
				$control_valid = 0;
			}
		}
		if ($control_valid == 1) {
			
		if ( $password_protection eq "1" ) {
			$password = param("password");

			# Password cryptage
			# Génération d'un salage
			my $sel_pass = generateHash(2);
			# Concaténation avec le sel
			$password = $sel_pass.$password;
			# Cryptage du password + sel
			my $sha = Digest::SHA1->new;
			$sha->add($password);
			$password = $sha->hexdigest;
			$password = $sel_pass.$password;
		}
			
			#------- Browse and validate each file -------
			for ( my $i = 1 ; $i <= $number_files ; $i++ ) {
	
				$filesToUpload[$i] = upload("file$i");
	
				# Verify each file validity
				if ( not defined $filesToUpload[$i] ) {
					my $fileName = param("file$i");
					IntraBox::push_alert("Le fichier $fileName n'est pas valide ou n'existe pas");
					$control_valid = 0;
	
					# End of loop is a file is invalid ($control_valid=0)
					last;
				}
	
				# Valid files
				else {
	
					# Verify the file size
					if ( $filesToUpload[$i]->size >= $sess->{size_max} ) {
						my $fileName = param("file$i");
						IntraBox::push_error("Le fichier $fileName est trop volumineux");
						$control_valid = 0;
	
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
		}
		#------- Process the upload -------
		if ( $control_valid == 1 ) {

			# if the user does not have enough free space
			if ( $depositSize > $userFreeSpace ) {
				IntraBox::push_error(
"Vous n'avez pas assez d'espace libre. Veuillez supprimer des fichiers"
				);

				#Contrôle compte perso
			}
			else {

				
				# Upload each file
				my $infoMsg;
				for ( my $i = 1 ; $i <= $number_files ; $i++ ) {

					# Upload the file
					$filesToUpload[$i]->copy_to("$path/$hash_names[$i]");

					# Generate the info message
					$infoMsg = $infoMsg . $filesToUpload[$i]->basename.", ";
				}

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
				redirect "deposit/$depositHash";
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
