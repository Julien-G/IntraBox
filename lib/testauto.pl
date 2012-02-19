use WWW::Mechanize;
use Test::More tests => 6;

my $mech = WWW::Mechanize->new();
my $url  = "http://localhost/cgi-bin/gestcli/public/dispatch.cgi";

$mech->get($url);


like(
	$mech->content,
	qr/Liste des clients/,
	"test: Appel $url, le résultat contient liste des clients"
);

like(
	$mech->content,
	qr/Nouveau client/,
	"test: la page contient le texte Nouveau Client"
);


$mech->follow_link(
	text_regex => qr/Nouveau client);

like(
	$mech->content,
	qr/form name = "formulaire_client"/,
	"Affichage du formulaire créer client"
);

$mech->submit_form(
	fields => {
		cli_nom     => 'ZORGLUB91',
		cli_prenom  => 'DjoDjo',
		cli_adresse => '3, rue truc',
		cli_cp      => '99123',
		cli_ville   => 'TAMETZEGVESV'
	}
);

like($mech->content, qr/client cree/, "");
like($mech->content, qr/ZORGLUB91/, "");
