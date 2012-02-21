package IntraBox::adminGroupController;
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
use DBIx::Class::FromValidators;


## end THIS CODE MUST BE INCLUDED IN ALL CONTROLLERS

my $ldap = Net::LDAP->new( config->{ldapserver} ) or die "Can't bind to ldap: $!\n";

my $OneMo = 1048576;
my $OneGo = 1073741824;

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
prefix '/admin/group';
my $user_group = "eleves";

# returns the usergroup list
get '/' => sub {
	my @usergroups = schema->resultset('Usergroup')->search( {} )->all;
	template 'admin/group',
	  {
		user_group  => $user_group,
		user_groups => \@usergroups
	  };
};

# add a group
post '/new' => sub {

	my $name_group         = param("name_group");
	my $type_group         = param("type_group");
	my $rule               = param("rule");
	my $description        = param("description");
	my $duration_max       = param("duration_max");	
	my $file_size_max      = ( param("unit_file_size_max") eq "Mo" ) ? param("file_size_max") * $OneMo : param("file_size_max") * $OneGo;
	my $space_size_max      = ( param("unit_space_size_max") eq "Mo" ) ? param("space_size_max") * $OneMo : param("space_size_max") * $OneGo;
	
	# Test parameters
	my $control_valid = 1;
	
	# No specials chars in parameters
	if (IntraBox::has_specials_char($rule,"règle")) {$control_valid = 0;}
	if (IntraBox::has_specials_char($duration_max,"Durée d\'expiration")) {$control_valid = 0;}
	if (IntraBox::has_specials_char($file_size_max,"Taille maximum de fichier")) {$control_valid = 0;}
	if (IntraBox::has_specials_char($space_size_max,"Taille maximum de dépôt")) {$control_valid = 0;}
	if (IntraBox::has_specials_char($name_group,"Nom du groupe")) {$control_valid = 0;}
	if (IntraBox::has_specials_char($type_group,"Type de groupe")) {$control_valid = 0;}
	if (IntraBox::has_specials_char($description,"Description")) {$control_valid = 0;}

	# Parameters must not be empty 
	if (IntraBox::is_empty($rule,"règle")) {$control_valid = 0;}
	if (IntraBox::is_empty($duration_max,"Durée d\'expiration")) {$control_valid = 0;}
	if (IntraBox::is_empty($file_size_max,"Taille maximum de fichier")) {$control_valid = 0;}
	if (IntraBox::is_empty($space_size_max,"Taille maximum de dépôt")) {$control_valid = 0;}
	
	# Parameters must number
	if (IntraBox::is_number($duration_max,"Durée d\'expiration")) {} else {$control_valid = 0;}
	if (IntraBox::is_decimal($file_size_max,"Taille maximum de fichier")) {} else  {$control_valid = 0;}
	if (IntraBox::is_decimal($space_size_max,"Taille maximum de dépôt")) {} else  {$control_valid = 0;}
	
	# Parameters must be under the limit possible
	if ($duration_max > config->{maxExpirationDays}) {
		$control_valid = 0;
		my $limit_expiration = config->{maxExpirationDays};
		IntraBox::push_error("Durée de validité pour un fichier trop importante. Limite : $limit_expiration jours");
	}
	if ($space_size_max > config->{maxQuota}) {
		$control_valid = 0;
		my $limit_quota = config->{maxQuota} / $OneGo;
		IntraBox::push_error("Taille de l'espace de stockage trop importante. Limite : $limit_quota Go");
	}	
	if ($space_size_max < $file_size_max) {
		$control_valid = 0;
		my $limit_file = $space_size_max / $OneGo;
		IntraBox::push_error("Taille de fichier trop importante. Limite : Taille de l'espace de stockage");
	}	
	
	if ($control_valid == 1) {
	my $current_date = DateTime->now;

	# try to find the group
	my $usergroups_search = schema->resultset('Usergroup')->find(
		{
			rule           => $rule,
		}
	);

	# return error if the group already exists
	if ( defined $usergroups_search ) {
		IntraBox::push_error("Ce groupe existe déjà : <strong>$rule</strong>.");
	}
	# else, add it
	else {
		my $stopProcess = 0;
		if ($type_group eq 'LDAP') {  # check LDAP
			my $info = '';
			# search all users in a group
			my $mesg = $ldap->search(
				base   => "ou=Groups,dc=enstimac,dc=fr",
				filter => "(cn=$rule )", #Group
			);
			# return error if the group already exists
			if ($mesg->entries == 0) {
				IntraBox::push_error("Ce groupe LDAP n'existe pas.");
				$stopProcess = 1;
			}
		}
		# if no error has happened
		if ($stopProcess eq 0) {
			IntraBox::push_info(" Vous venez d'ajouter le groupe <strong>$rule</strong>.");
			my $usergroups = schema->resultset('Usergroup')->create(
				{
					rule_type      => $type_group,
					rule           => $rule,
					name           => $name_group,
					quota          => $space_size_max,
					size_max       => $file_size_max,
					expiration_max => $duration_max,
					description    => $description,
					creation_date  => $current_date,
				}
			);
		}
	}
	
	}
	
	my @usergroups = schema->resultset('Usergroup')->search( {} )->all;

	
	template 'admin/group',
	  {
		user_group  => $user_group,
		user_groups => \@usergroups
	  };
};

# edit 	a group
get qr{/modify/(?<id>\d+)} => sub {

	my $id = captures->{'id'};    # le paramètre id est dans l'URL
	delete params->{captures};

	# lecture des paramètres de la vue
	#my $usergroups = vars->{user_groups};

	# recherche du groupe à supprimer
	my $group = schema->resultset('Usergroup')->find($id);
	if ( not defined $group ) {
		IntraBox::push_error("Il n'y a pas de groupe à l'ID <strong>$id</strong>.");
	}
	else {

 	my $rule = $group->rule;
 	IntraBox::push_info(" Vous allez modifier le groupe <strong>$rule</strong>.");

		template 'admin/group', {
			isEditGroup => 1,
			group => $group
		};
	}
};

# update the group in DB
post '/update' => sub {

	my $name_group         = param("name_group");
	my $type_group         = param("type_group");
	my $rule               = param("rule");
	my $description        = param("description");
	my $duration_max       = param("duration_max");

	my $file_size_max      = ( param("unit_file_size_max") eq "Mo" ) ? param("file_size_max") * $OneMo : param("file_size_max") * $OneGo;

	my $space_size_max      = ( param("unit_space_size_max") eq "Mo" ) ? param("space_size_max") * $OneMo : param("space_size_max") * $OneGo;

	my $current_date = DateTime->now;

	# find the group to edit
	my $usergroup = schema->resultset('Usergroup')->find( { id_usergroup => param("id_usergroup") } );

	# if the group does not exist
	if ( not defined $usergroup ) {
		IntraBox::push_error( "Ce groupe n'existe pas : <strong>$rule</strong>." );
	}

	# else, we edit it
	else {
		IntraBox::push_info( "Vous venez de modifier le groupe <strong>$rule</strong>." );
		$usergroup->update(
			{
				rule_type      => $type_group,
				rule           => $rule,
				name           => $name_group,
				quota          => $space_size_max,
				size_max       => $file_size_max,
				expiration_max => $duration_max,
				description    => $description,
				creation_date  => $current_date,
			}
		);
	}
	my @usergroups = schema->resultset('Usergroup')->search( {} )->all;

#	redirect "admin/group/modify/" . $usergroups->id_usergroup;
	template 'admin/group',
	  {
		user_group  => $user_group,
		user_groups => \@usergroups
	  };

};

# delete a group
get qr{/delete/(?<id>\d+)} => sub {

	my $id = captures->{'id'};    # le paramètre id est dans l'URL
	delete params->{captures};

	# recherche du groupe à supprimer
	my $usergroups = schema->resultset('Usergroup')->find($id);
	if ( not defined $usergroups ) {
		IntraBox::push_error( "Il n'y a pas de groupe à l'ID <strong>$id</strong>." );
	}
	else {
		my $rule = $usergroups->rule;
		IntraBox::push_info( "Vous venez de retirer le groupe <strong>$rule</strong>." );
		$usergroups->delete();
	}

	my @usergroups = schema->resultset('Usergroup')->search( {} )->all;

	template 'admin/group',
	  {
		user_group  => $user_group,
		user_groups => \@usergroups
	  };
};

return 1;
