use WWW::Mechanize;
use Test::More tests => 6;
use utf8;

my $mech = WWW::Mechanize->new();
my $url  = "http://localhost/cgi-bin/Intrabox/public/dispatch.cgi";

$mech->get($url);

like( $mech->content, qr/IntraBox/,
	"test: Appel $url, le résultat contient IntraBox" );

$mech->submit_form(
	fields => {
		file1 =>
'C:\Users\lfoucher\Documents\Java\chapitre02 - Definition des classes.pdf',
		expiration_days  => '10',
		downloads_report => '0',
		acknowlegdement  => '0'
	}
);

like(
	$mech->content,
	qr/Upload terminé des fichiers/,
	"test : Ajout d'un dépôt"
);

#On vérifie que le lien pour aller aux fichiers non expirés existe
like(
	$mech->content,
	qr/Gestion des fichiers non expirés/,
	"test: La page contient Gestion des fichiers non expirés"
);

#On va à la page des fichiers non expirés
$mech->follow_link( text_regex => qr/Gestion des fichiers non expirés/ );

#On vérifie qu'on est bien arrivé sur la bonne page
like(
	$mech->content,
	qr/Voici la liste des dépôts non expirés/,
	"test: La page contient Voici la liste des dépôts non expirés"
);

#On suit le troisième lien qui ne peut être qu'un lien de suppression de dépôt
$mech->follow_link( n => 22 );

#On vérifie qu'on retourne bien à la page principale des dépôts non expirés
like(
	$mech->content,
	qr/Voici la liste des dépôts non expirés/,
	"test: La page contient Voici la liste des dépôts non expirés"
);

#On va à la page des fichiers non expirés
$mech->follow_link( text_regex => qr/IntraBox/ );

$mech->submit_form(
	fields => {
		file1            => 'C:\Users\lfoucher\Documents\Web service\VB.z01',
		expiration_days  => '10',
		downloads_report => '0',
		acknowlegdement  => '0'
	}
);

like(
	$mech->content,
	qr/Le fichier $VB.z01 est trop volumineux/,
	"test : La taille du fichier est trop grande"
);
