use WWW::Mechanize;
use Test::More tests => 11;
use utf8;

my $mech = WWW::Mechanize->new();
my $url  = "http://localhost/cgi-bin/Intrabox/public/dispatch.cgi";

$mech->get($url);

#On part de la page d'accueil/de dépôt et on vérifie que le lien pour aller aux fichiers non expirés existe
like( $mech->content, qr/IntraBox/,
	"test: Appel $url, le résultat contient IntraBox" );

#On vérifie que le lien vers la gestion des groupes existe
like(
	$mech->content,
	qr/Gestion des groupes/,
	"test: La page contient le texte Gestion des groupes"
);

#On y va
$mech->follow_link( text_regex => qr/Gestion des groupes/ );

#On crée un groupe fictif qui n'existe pas dans LDAP
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

#On vérifie le retour du message
like(
	$mech->content,
	qr/Ce groupe LDAP n'existe pas/,
	"test : Impossible de créer ce groupe d'utilisateur"
);

#On crée un groupe LDAP
$mech->submit_form(
	fields => {
		type_group          => 'LDAP',
		rule                => 'ifi2005',
		name_group          => 'ifi2005',
		description         => 'ifi2005',
		duration_max        => '10',
		file_size_max       => '10',
		unit_file_size_max  => 'Mo',
		space_size_max      => '1',
		unit_space_size_max => 'Go'
	}
);

#On vérifie l'ajout du message de création
like(
	$mech->content,
	qr/Vous venez d'ajouter le groupe/,
	"test : Ajout du groupe"
);

#On vérifie la présence du nom du groupe
like(
	$mech->content,
	qr/ifi2005/,
	"test : Ajout du groupe ifi2005"
);

#On clique sur le lien modifier
$mech->follow_link( n => 18 );

#On vérifie l'arrivée sur la page de modification
like(
	$mech->content,
	qr/Vous allez modifier le groupe/,
	"test : La page contient Vous allez modifier le groupe"
);

#On vérifie que c'est bien le groupe ifi2005 qu'on va modifier
like(
	$mech->content,
	qr/ifi2005/,
	"test : Modification du groupe ifi2005"
);

#On change le groupe pour ifi2001
$mech->submit_form(
	fields => {
		type_group          => 'LDAP',
		rule                => 'ifi2001',
		name_group          => 'ifi2001',
		description         => 'ifi2001',
		duration_max        => '10',
		file_size_max       => '10',
		unit_file_size_max  => 'Mo',
		space_size_max      => '1',
		unit_space_size_max => 'Go'
	}
);

#On valide notre formulaire
$mech->click_button( number => 1 );

#On vérifie que la modification a bien été prise en compte
like(
	$mech->content,
	qr/ifi2001/,
	"test : Modification du groupe ifi2005 en ifi2001"
);

#On suit le lien de suppression du groupe
$mech->follow_link( n => 19 );

#On vérifie le message de suppression
like(
	$mech->content,
	qr/Vous venez de retirer le groupe/,
	"test : La page contient Vous venez de retirer le groupe"
);

#du groupe ifi2001
like(
	$mech->content,
	qr/ifi2001/,
	"test : Suppression du groupe ifi2001"
);