package IntraBox::adminDownloadController;
## PARTIE COMMUNE A TOUS LES CONTROLLEURS
use strict;
use warnings;

# Configuration
use lib '.';
our $VERSION = '0.1';

# Chargement des plugins utiles à Dancer
use Dancer ':syntax';
use Dancer::Plugin::DBIC;

# Chargement des plugins fonctionnels
use Digest::SHA1;
use Class::Date qw(:errors date localdate gmdate now -DateParse);
use Data::FormValidator;
use DBIx::Class::FromValidators;

# Chargement des subroutines
use subroutine;
use subroutine2;
use subroutine3;
## fin PARTIE COMMUNE A TOUS LES CONTROLLEURS

prefix '/admin/download';

my $sess = IntraBox::getSessionVars();

get '/' => sub {
	template 'admin/download', { sess => $sess };
};

return 1;