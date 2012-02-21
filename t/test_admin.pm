use WWW::Mechanize;
use Test::More tests => 6;
use utf8;

my $mech = WWW::Mechanize->new();
my $url  = "http://localhost/cgi-bin/Intrabox/public/dispatch.cgi";

$mech->get($url);

#On teste la présence d'IntraBox sur la page
like( $mech->content, qr/IntraBox/,
	"test: Appel $url, le résultat contient IntraBox" );
	
#On vérifie que le lien pour aller à la gestion des administrateurs existe
like(
	$mech->content,
	qr/Gestion des administrateurs/,
	"test: La page contient Gestion des administrateurs"
);

#On va à la page de gestion des administrateurs
$mech->follow_link( text_regex => qr/Gestion des administrateurs/ );	

#On vérifie qu'on arrive bien sur la bonne page
like(
	$mech->content,
	qr/Ajouter un administrateur/,
	"test: La page contient Ajouter un administrateur"
);

#On ajoute un administrateur
$mech->submit_form(
	fields => {
		login => 'abourgan'
	}
);

#On vérifie le message d'ajout
like(
	$mech->content,
	qr/Vous venez d'ajouter l'administrateur/,
	"test : Vous venez d'ajouter l'administrateur"
);

#On vérifie le login de l'administrateur
like(
	$mech->content,
	qr/abourgan/,
	"test : Vous venez d'ajouter l'administrateur abourgan"
);

#On supprime le deuxième adminstrateur qui dans ce cas est celui qu'on vient de rajouter
$mech->follow_link( text => 'Supprimer', n => 2 );

#On vérifie le message de suppression
like(
	$mech->content,
	qr/Vous venez de retirer l'administrateur/,
	"test : Vous venez de retirer l'administrateur"
);

like(
	$mech->content,
	qr/abourgan/,
	"test : Vous venez de supprimer l'administrateur abourgan"
);