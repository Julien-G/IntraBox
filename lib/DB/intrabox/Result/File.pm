package DB::intrabox::Result::File;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("FromValidators", "InflateColumn::DateTime", "Core");

=head1 NAME

DB::intrabox::Result::File

=cut

__PACKAGE__->table("file");

=head1 ACCESSORS

=head2 id_file

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 id_deposit

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 60

=head2 size

  data_type: 'float'
  is_nullable: 0

=head2 on_server

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=head2 name_on_disk

  data_type: 'varchar'
  is_nullable: 0
  size: 60

=cut

__PACKAGE__->add_columns(
  "id_file",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "id_deposit",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 60 },
  "size",
  { data_type => "float", is_nullable => 0 },
  "on_server",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "name_on_disk",
  { data_type => "varchar", is_nullable => 0, size => 60 },
);
__PACKAGE__->set_primary_key("id_file", "id_deposit");

=head1 RELATIONS

=head2 downloads

Type: has_many

Related object: L<DB::intrabox::Result::Download>

=cut

__PACKAGE__->has_many(
  "downloads",
  "DB::intrabox::Result::Download",
  {
    "foreign.id_deposit" => "self.id_deposit",
    "foreign.id_file"    => "self.id_file",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 id_deposit

Type: belongs_to

Related object: L<DB::intrabox::Result::Deposit>

=cut

__PACKAGE__->belongs_to(
  "id_deposit",
  "DB::intrabox::Result::Deposit",
  { id_deposit => "id_deposit" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-30 17:27:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g+/FnA+M9WjRrEKpXJOXRA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
