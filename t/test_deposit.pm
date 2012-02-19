use WWW::Mechanize;
use Test::More tests => 3;
use utf8;

my $mech = WWW::Mechanize->new();
my $url  = "http://localhost/cgi-bin/Intrabox/public/dispatch.cgi";

$mech->get($url);

like( $mech->content, qr/IntraBox/,
	"test: Appel $url, le résultat contient IntraBox" );

like(
	$mech->content,
	qr/form name="deposit"/,
	"test: Affichage du formulaire de dépôt"
);

$mech->submit_form(
	fields => {
		file1            => 'C:\Users\lfoucher\Documents\Java\chapitre02 - Definition des classes.pdf',
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

#like( $mech->content, qr/ifi2013/, "test : Ajout du groupe ifi2013" );
