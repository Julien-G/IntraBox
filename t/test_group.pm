use WWW::Mechanize;
use Test::More tests => 5;
use utf8;

my $mech = WWW::Mechanize->new();
my $url  = "http://localhost/cgi-bin/Intrabox/public/dispatch.cgi";

$mech->get($url);

like( $mech->content, qr/IntraBox/,
	"test: Appel $url, le résultat contient IntraBox" );

like(
	$mech->content,
	qr/ses fichiers/,
	"test: La page contient le texte Gérer ses fichiers"
);

like(
	$mech->content,
	qr/Gestion des groupes/,
	"test: La page contient le texte Gestion des groupes"
);

#like(
#	$mech->content,
#	qr/form name="deposit"/,
#	"test : Affichage du formulaire de dépôt"
#);

#$mech->follow_link(
#	text_regex => qr/ses fichiers/);

$mech->follow_link( text_regex => qr/Gestion des groupes/ );

like(
	$mech->content,
	qr/form name="group"/,
	"test : Affichage du formulaire de création de groupe"
);

$mech->submit_form(
	fields => {
		type_group          => 'LDAP',
		rule                => 'sbrthhvbjsve',
		name_group          => 'sbrthhvbjsve',
		description         => 'jhrcxhtrex',
		duration_max        => '10',
		file_size_max       => '10',
		unit_file_size_max  => 'Mo',
		space_size_max      => '1',
		unit_space_size_max => 'Go'
	}
);

like(
	$mech->content,
	qr/Ce groupe LDAP n'existe pas/,
	"test : Ajout d'un groupe d'utilisateur"
);

#like(
#	$mech->content,
#	qr/ifi2013/,
#	"test : Ajout du groupe ifi2013"
#);
