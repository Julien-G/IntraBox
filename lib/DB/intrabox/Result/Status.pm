package DB::intrabox::Result::Status;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("FromValidators", "InflateColumn::DateTime", "Core");

=head1 NAME

DB::intrabox::Result::Status

=cut

__PACKAGE__->table("status");

=head1 ACCESSORS

=head2 id_status

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
  "id_status",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);
__PACKAGE__->set_primary_key("id_status");

=head1 RELATIONS

=head2 deposits

Type: has_many

Related object: L<DB::intrabox::Result::Deposit>

=cut

__PACKAGE__->has_many(
  "deposits",
  "DB::intrabox::Result::Deposit",
  { "foreign.id_status" => "self.id_status" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-30 17:27:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DK01Ik9Hy5SwAe/u/Mn4eQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
