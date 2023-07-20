#!/usr/bin/perl

use strict;

print "Patched 1ST_READ.BIN with font changes.\n";

my $font_data_double_quote_1 = "0D";
&patch_bytes("Z:\\dc\\gdi\\new\\cool_cool_toon\\gdi_extracted\\1ST_READ.BIN", $font_data_double_quote_1, 1734505);

my $font_data_double_quote_2 = "24090360D8000000000000000000000000000000";
&patch_bytes("Z:\\dc\\gdi\\new\\cool_cool_toon\\gdi_extracted\\1ST_READ.BIN", $font_data_double_quote_2, 1735896);

my $font_data_single_quote = "C0300401";
&patch_bytes("Z:\\dc\\gdi\\new\\cool_cool_toon\\gdi_extracted\\1ST_READ.BIN", $font_data_single_quote, 1734624);

# Subroutine to read a specified number of bytes (starting at the beginning) of a specified file,
# returning hexadecimal representation of data.
#
# 1st parameter - Full path of file to read.
# 2nd parameter - Number of bytes to read (omit parameter to read entire file).
sub read_bytes
{
	my $file_to_read = $_[0];
	my $bytes_to_read = $_[1];

	if($bytes_to_read eq "")
	{
		$bytes_to_read = (stat $file_to_read)[7];
	}

	open my $filehandle, '<:raw', "$file_to_read" or die $!;
	read $filehandle, my $bytes, $bytes_to_read;
	close $filehandle;
	
	return unpack 'H*', $bytes;
}

# Subroutine to read a specified number of bytes, starting at a specific offset (in decimal format), of
# a specified file, returning hexadecimal representation of data.
#
# 1st parameter - Full path of file to read.
# 2nd parameter - Number of bytes to read.
# 3rd parameter - Offset at which to read.
sub read_bytes_at_offset
{
	my $file_to_read = $_[0];
	my $bytes_to_read = $_[1];
	my $read_offset = $_[2];

	open my $filehandle, '<:raw', "$file_to_read" or die $!;
	seek $filehandle, $read_offset, 0;
	read $filehandle, my $bytes, $bytes_to_read;
	close $filehandle;
	
	return unpack 'H*', $bytes;
}

# Subroutine to write a sequence of hexadecimal values to a specified file.
#
# 1st parameter - Full path of file to write.
# 2nd parameter - Hexadecimal representation of data to be written to file.
sub write_bytes
{
	my $output_file = $_[0];
	(my $hex_data = $_[1]) =~ s/\s+//g;
	my @hex_data_array = split(//, $hex_data);

	open my $filehandle, '>', $output_file or die $!;
	binmode $filehandle;

	for(my $i = 0; $i < @hex_data_array; $i += 2)
	{
		my($high, $low) = @hex_data_array[$i, $i + 1];
		print $filehandle pack "H*", $high . $low;
	}

	close $filehandle;
}

# Subroutine to write a sequence of hexadecimal values at a specified offset (in decimal format) into
# a specified file, as to patch the existing data at that offset.
#
# 1st parameter - Full path of file in which to insert patch data.
# 2nd parameter - Hexadecimal representation of data to be inserted.
# 3rd parameter - Offset at which to patch.
sub patch_bytes
{
	my $output_file = $_[0];
	(my $hex_data = $_[1]) =~ s/\s+//g;
	my $insert_offset = $_[2];
	my $hex_data_length = length($hex_data) / 2;
	
	my $data_before = &read_bytes($output_file, $insert_offset);
	my $data_after = &read_bytes_at_offset($output_file, (stat $output_file)[7] - $insert_offset - $hex_data_length, $insert_offset + $hex_data_length);
	
	&write_bytes($output_file, $data_before . $hex_data . $data_after);
}