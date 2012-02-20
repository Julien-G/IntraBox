use WWW::Mechanize;
use Test::More tests => 10;
use utf8;

# Test de la vue des fichiers non expirés

my $mech = WWW::Mechanize->new();
my $url  = "http://localhost/cgi-bin/Intrabox/public/dispatch.cgi";

$mech->get($url);

#On dépose un fichier pour le test
$mech->submit_form(
	fields => {
		file1            => 'C:\Users\lfoucher\Documents\Java\chapitre02 - Definition des classes.pdf',
		expiration_days  => '10',
		downloads_report => '0',
		acknowlegdement  => '0'
	}
);

#On part de la page d'accueil/de dépôt et on vérifie que le lien pour aller aux fichiers non expirés existe
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

#On suit le premier lien du contenu de la page qui ne peut être que un lien "voir le dépôt"
$mech->follow_link( n => 20 );

#On vérifie qu'on est sur un page de visualisation d'un dépôt
like(
	$mech->content,
	qr/Le lien de téléchargement/,
	"test: La page contient Le lien de téléchargement"
);

#On retourne en arrière
$mech->follow_link( text_regex => qr/Gestion des fichiers non expirés/ );

#On vérifie qu'on arrive bien où on le voulait
like(
	$mech->content,
	qr/Voici la liste des dépôts non expirés/,
	"test: La page contient Voici la liste des dépôts non expirés"
);

#On suit le deuxième lien qui ne peut être qu'un lien de modification de dépôt
$mech->follow_link( n => 21 );

#On vérifie qu'on arrive bien où on le voulait
like(
	$mech->content,
	qr/Vous pouvez ici changer les informations du dépôt/,
	"test: La page contient Vous pouvez ici changer les informations du dépôt"
);

#On retourne en arrière
$mech->follow_link( text_regex => qr/Gestion des fichiers non expirés/ );

#On vérifie qu'on arrive bien où on le voulait
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
