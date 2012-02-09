package DB::intrabox::Result::Usergroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("FromValidators", "InflateColumn::DateTime", "Core");

=head1 NAME

DB::intrabox::Result::Usergroup

=cut

__PACKAGE__->table("usergroup");

=head1 ACCESSORS

=head2 id_usergroup

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 rule_type

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 rule

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 quota

  data_type: 'tinyint'
  is_nullable: 0

=head2 size_max

  data_type: 'tinyint'
  is_nullable: 0

=head2 expiration_max

  data_type: 'tinyint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_usergroup",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "rule_type",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "rule",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "quota",
  { data_type => "tinyint", is_nullable => 0 },
  "size_max",
  { data_type => "tinyint", is_nullable => 0 },
  "expiration_max",
  { data_type => "tinyint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id_usergroup");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-30 17:27:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9N5WnEorbQ/w1NE/KlZCyg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
