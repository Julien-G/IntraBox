package DB::intrabox::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("FromValidators", "InflateColumn::DateTime", "Core");

=head1 NAME

DB::intrabox::Result::User

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id_user

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 login

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 70

=head2 admin

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_user",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "login",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 70 },
  "admin",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id_user");
__PACKAGE__->add_unique_constraint("login_UNIQUE", ["login"]);

=head1 RELATIONS

=head2 deposits

Type: has_many

Related object: L<DB::intrabox::Result::Deposit>

=cut

__PACKAGE__->has_many(
  "deposits",
  "DB::intrabox::Result::Deposit",
  { "foreign.id_user" => "self.id_user" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-21 00:54:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OmWgdQ6jOwNXvgvj9mU2/w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
