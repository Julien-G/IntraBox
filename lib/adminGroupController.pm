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

#------------------------------------------------------------
# Session
#------------------------------------------------------------
my $sess = IntraBox::getSession();

#------------------------------------------------------------
# Routes
#------------------------------------------------------------
prefix '/admin/group';
my $user_group = "eleves";

get '/' => sub {
	IntraBox::push_info "";
	my @usergroups = schema->resultset('Usergroup')->search( {} )->all;
	template 'admin/group_new',
	  {
		sess        => $sess,
		user_group  => $user_group,
		user_groups => \@usergroups
	  };
};

post '/new' => sub {

	my $name_group         = param("name_group");
	my $type_group         = param("type_group");
	my $rule               = param("rule");
	my $description        = param("description");
	my $duration_max       = param("duration_max");
	my $file_size_max      = param("file_size_max");
	my $unit_file_size_max = param("unit_file_size_max");

	if ( $unit_file_size_max eq "Mo" ) {
		$file_size_max = $file_size_max * 1048576;
	}
	else { $file_size_max = $file_size_max * 1073741824 }
	my $space_size_max      = param("space_size_max");
	my $unit_space_size_max = param("unit_space_size_max");

	if ( $unit_space_size_max eq "Mo" ) {
		$space_size_max = $space_size_max * 1048576;
	}
	else { $space_size_max = $space_size_max * 1073741824 }

	my $current_date = Class::Date->new;
	$current_date = DateTime->now;

	# recherche du groupe à ajouter
	my $usergroups = schema->resultset('Usergroup')->find(
		{
			rule_type      => $type_group,
			rule           => $rule,
			name           => $name_group,
			quota          => $space_size_max,
			size_max       => $file_size_max,
			expiration_max => $duration_max,
		}
	);

	# si le groupe existe déjà
	if ( defined $usergroups ) {
		IntraBox::push_error
		  "Ce groupe existe déjà : <strong>$rule</strong>.";
	}

	#sinon on l'ajoute
	else {
		IntraBox::push_info
		  " Vous venez d'ajouter le groupe <strong>$rule</strong>.";
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
	my @usergroups = schema->resultset('Usergroup')->search( {} )->all;

	template 'admin/group_new',
	  {
		sess        => $sess,
		user_group  => $user_group,
		user_groups => \@usergroups
	  };
};

get qr{/modify/(?<id>\d+)} => sub {

	my $id = captures->{'id'};    # le paramètre id est dans l'URL
	delete params->{captures};

	# lecture des paramètres de la vue
	#my $usergroups = vars->{user_groups};

	# recherche du groupe à supprimer
	my $group = schema->resultset('Usergroup')->find($id);
	if ( not defined $group ) {
		IntraBox::push_error
		  "Il n'y a pas de groupe à l'ID <strong>$id</strong>.";
	}
	else {

 	my $rule = $group->rule;
 	IntraBox::push_info " Vous aller modifier le groupe <strong>$rule</strong>.";

		template 'admin/group_edit', {
			sess => $sess,
			group => $group
		};
	}
};

post '/update' => sub {

	my $name_group         = param("name_group");
	my $type_group         = param("type_group");
	my $rule               = param("rule");
	my $description        = param("description");
	my $duration_max       = param("duration_max");
	my $file_size_max      = param("file_size_max");
	my $unit_file_size_max = param("unit_file_size_max");

	if ( $unit_file_size_max eq "Mo" ) {
		$file_size_max = $file_size_max * 1048576;
	}
	else { $file_size_max = $file_size_max * 1073741824 }
	my $space_size_max      = param("space_size_max");
	my $unit_space_size_max = param("unit_space_size_max");

	if ( $unit_space_size_max eq "Mo" ) {
		$space_size_max = $space_size_max * 1048576;
	}
	else { $space_size_max = $space_size_max * 1073741824 }

	my $current_date = Class::Date->new;
	$current_date = DateTime->now;

	# recherche du groupe à ajouter
	my $usergroups = schema->resultset('Usergroup')->find(
		{
			id_usergroup => param("id_usergroup")
		}
	);

	# si le groupe existe déjà
	if ( not defined $usergroups ) {
		IntraBox::push_error
		  "Ce groupe n'existe pas : <strong>$rule</strong>.";
	}

	#sinon on le modifie
	else {
		IntraBox::push_info
		  " Vous venez de modifier le groupe <strong>$rule</strong>.";
		$usergroups->update(
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
	template 'admin/group_new',
	  {
		sess        => $sess,
		user_group  => $user_group,
		user_groups => \@usergroups
	  };

};

get qr{/delete/(?<id>\d+)} => sub {

	my $id = captures->{'id'};    # le paramètre id est dans l'URL
	delete params->{captures};

	# recherche du groupe à supprimer
	my $usergroups = schema->resultset('Usergroup')->find($id);
	if ( not defined $usergroups ) {
		IntraBox::push_error
		  "Il n'y a pas de groupe à l'ID <strong>$id</strong>.";
	}
	else {
		my $rule = $usergroups->rule;
		IntraBox::push_info
		  "Vous venez de retirer le groupe <strong>$rule</strong>.";
		$usergroups->delete();
	}

	my @usergroups = schema->resultset('Usergroup')->search( {} )->all;

	template 'admin/group_new',
	  {
		sess        => $sess,
		user_group  => $user_group,
		user_groups => \@usergroups
	  };
};

return 1;
