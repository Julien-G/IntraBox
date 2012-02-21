package IntraBox::purgeController;

# Programme de suppression automatique des fichiers et d'expiration automatique des dépôts anciens
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
use DB::intrabox;
use Digest::SHA1;
use DateTime;
use Data::FormValidator;
use DBIx::Class::FromValidators;

## end THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS

my $ldap = Net::LDAP->new( config->{ldapserver} )
  or die "Can't bind to ldap: $!\n";

#------------------------------------------------------------
# Session
#------------------------------------------------------------
my $sess = IntraBox::getSession();

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
prefix '/admin/purge';

get '/' => sub {
	if ( $sess->{isAdmin} == 0 ) {
		IntraBox::push_error(
"Cette section est réservée aux administrateurs. <a href=\"config->{pathApp}\">Cliquez-ici</a> pour retourner à l'application."
		);
		template 'avert', {};
	}
	else {
		IntraBox::push_info(
" Appuyez sur le bouton <strong>Purger</strong> pour purger les fichiers expirés."
		);
		template 'admin/purge';
	}
};

post '/new' => sub {
	if ( $sess->{isAdmin} == 0 ) {
		IntraBox::push_error(
"Cette section est réservée aux administrateurs. <a href=\"config->{pathApp}\">Cliquez-ici</a> pour retourner à l'application."
		);
		template 'avert', {};
	}
	else {

		#Chemin des fichiers enregistrés
		my $path =
"/Program Files (x86)/Apache Software Foundation/Apache2.2/cgi-bin/IntraBox/public/Upload";

		# Connexion à la base de données
		#	my $dsn    = "dbi:mysql:intrabox";
		#	my $schema = DB::intrabox->connect( $dsn, "", "" ) or die "problem";

		#Date courante
		my $current_date = DateTime->now;

		#Initialisation variables
		my $name_file;
		my $id_deposit;
		my $size_file;
		my $total_size;
		my $cpt;

		#Ecriture dans les logs - Header
		open my $LOG_DEL, '>>', '../logs/log_del.txt'
		  or die "Impossible d'écrire dans le fichier";
		print {$LOG_DEL} "\n---------------------------";
		print {$LOG_DEL} "\nSuppression Anciens Depots\n";

		#Recuperation de tous les fichiers expirés ou non disponible
		my @depositsExpired = schema->resultset('Deposit')->search(
			{
				-or => [
					expiration_date => { '<', $current_date },
					id_status       => '2',
				],
			}
		);

		#Expiration dans la base de données
		foreach my $deposit (@depositsExpired) {
			if ( $deposit->id_status == 1 ) {
				IntraBox::depositController->warn_user(
					$deposit->download_code );
			}
			$deposit->id_status("2");
			$deposit->update;
			$id_deposit = $deposit->id_deposit;

			#Recherche des fichiers associés aux dépôts expirés
			my @fileExpired = schema->resultset('File')->search(
				{
					id_deposit => $id_deposit,
					on_server  => '1',
				}
			);

			#Suppression des fichiers associés
			if (@fileExpired) {
				foreach my $file (@fileExpired) {
					$file->on_server("0");
					$file->update;
					$name_file = $file->name_on_disk;

					$size_file  = $file->size;
					$total_size = $total_size + $size_file;
					$cpt++;

					unlink "$path/$name_file";

					#Ecriture dans les logs
					print {$LOG_DEL}
					  "[$current_date] - Delete File - $name_file\n";

				}
			}
		}

		#Ecriture dans les logs - Footer
		print {$LOG_DEL} "\nTotal files deleted : $cpt";
		print {$LOG_DEL} "\nTotal size free : $total_size bytes";
		print {$LOG_DEL} "\n---------------------------\n\n";
		close $LOG_DEL or die "Impossible de lire";

		IntraBox::push_info(
			" Vous pouvez consulter les fichiers purgés dans le dossier Log.");

		template 'admin/purge';
	}
};

