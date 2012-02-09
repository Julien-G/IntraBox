package DB::intrabox::Result::Deposit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("FromValidators", "InflateColumn::DateTime", "Core");

=head1 NAME

DB::intrabox::Result::Deposit

=cut

__PACKAGE__->table("deposit");

=head1 ACCESSORS

=head2 id_deposit

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 id_user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 download_code

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 area_access_code

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 area_to_email

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 area_size

  data_type: 'tinyint'
  is_nullable: 1

=head2 opt_acknowledgement

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 opt_downloads_report

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 opt_comment

  data_type: 'tinytext'
  is_nullable: 1

=head2 opt_password

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 id_status

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 expiration_days

  data_type: 'tinyint'
  is_nullable: 0

=head2 expiration_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 created_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 created_ip

  data_type: 'varchar'
  is_nullable: 0
  size: 19

=head2 created_useragent

  data_type: 'varchar'
  is_nullable: 0
  size: 150

=cut

__PACKAGE__->add_columns(
  "id_deposit",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "id_user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "download_code",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "area_access_code",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "area_to_email",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "area_size",
  { data_type => "tinyint", is_nullable => 1 },
  "opt_acknowledgement",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "opt_downloads_report",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "opt_comment",
  { data_type => "tinytext", is_nullable => 1 },
  "opt_password",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "id_status",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "expiration_days",
  { data_type => "tinyint", is_nullable => 0 },
  "expiration_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "created_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "created_ip",
  { data_type => "varchar", is_nullable => 0, size => 19 },
  "created_useragent",
  { data_type => "varchar", is_nullable => 0, size => 150 },
);
__PACKAGE__->set_primary_key("id_deposit", "id_user", "id_status");

=head1 RELATIONS

=head2 id_status

Type: belongs_to

Related object: L<DB::intrabox::Result::Status>

=cut

__PACKAGE__->belongs_to(
  "id_status",
  "DB::intrabox::Result::Status",
  { id_status => "id_status" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id_user

Type: belongs_to

Related object: L<DB::intrabox::Result::User>

=cut

__PACKAGE__->belongs_to(
  "id_user",
  "DB::intrabox::Result::User",
  { id_user => "id_user" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 files

Type: has_many

Related object: L<DB::intrabox::Result::File>

=cut

__PACKAGE__->has_many(
  "files",
  "DB::intrabox::Result::File",
  { "foreign.id_deposit" => "self.id_deposit" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-30 17:27:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:w+wR39jZXMxO6o/Vdog2bg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
