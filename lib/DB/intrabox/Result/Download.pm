package DB::intrabox::Result::Download;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("FromValidators", "InflateColumn::DateTime", "Core");

=head1 NAME

DB::intrabox::Result::Download

=cut

__PACKAGE__->table("download");

=head1 ACCESSORS

=head2 id_download

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 id_deposit

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 id_file

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 ip

  data_type: 'varchar'
  is_nullable: 0
  size: 19

=head2 useragent

  data_type: 'varchar'
  is_nullable: 0
  size: 150

=head2 start_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 end_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 finished

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_download",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "id_deposit",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "id_file",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ip",
  { data_type => "varchar", is_nullable => 0, size => 19 },
  "useragent",
  { data_type => "varchar", is_nullable => 0, size => 150 },
  "start_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "end_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "finished",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id_download", "id_deposit", "id_file");

=head1 RELATIONS

=head2 file

Type: belongs_to

Related object: L<DB::intrabox::Result::File>

=cut

__PACKAGE__->belongs_to(
  "file",
  "DB::intrabox::Result::File",
  { id_deposit => "id_deposit", id_file => "id_file" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-30 17:27:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9akp+3tBWaO1v21At62nkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
