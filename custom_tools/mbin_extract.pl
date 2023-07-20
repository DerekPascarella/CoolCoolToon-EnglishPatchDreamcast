#!/usr/bin/perl
#
# mbin_extract.pl
# MBIN archive extractor for "Cool Cool Toon".
#
# Written by Derek Pascarella (ateam)

use strict;
use String::HexConvert ':all';

my $file_input = $ARGV[0];
(my $file_input_without_path = $file_input) =~ s{^.*[/|\\]}{};
my $folder_output = $ARGV[1];
my $archive_size = (stat $file_input)[7];
my $file_count = hex(&endian_swap(&read_bytes_at_offset($file_input, 4, 4)));

print "\nArchive name:\t$file_input_without_path\n";
print "File count:\t$file_count\n\n";

for(my $i = 0; $i < $file_count; $i ++)
{
	my $pointer_location = ($i * 4) + 32;
	my $pointer_value = hex(&endian_swap(&read_bytes_at_offset($file_input, 4, $pointer_location)));
	my $file_size = 0;

	if($i < $file_count - 1)
	{
		my $pointer_location_next = (($i + 1) * 4) + 32;
		my $pointer_value_next = hex(&endian_swap(&read_bytes_at_offset($file_input, 4, $pointer_location_next)));
		$file_size = $pointer_value_next - $pointer_value;
	}
	else
	{
		$file_size = $archive_size - $pointer_value;
	}

	(my $file_name = hex_to_ascii(&read_bytes_at_offset($file_input, 4, $pointer_value))) =~ s/[^a-zA-Z0-9]//g;
	$file_name = sprintf("%03d", $i + 1) . "_" . $file_name;
	my $file_bytes = &read_bytes_at_offset($file_input, $file_size, $pointer_value);
	mkdir $folder_output . "/" . $file_input_without_path;
	&write_bytes($folder_output . $file_input_without_path . "/" . $file_name, $file_bytes);

	print "> File " . ($i + 1) . "\n";
	print "  - Pointer location:\t$pointer_location\n";
	print "  - Pointer value:\t$pointer_value\n";
	print "  - File size:\t\t$file_size\n";
	print "  - File name:\t\t$file_name\n\n";
}

# Subroutine to swap between big/little endian by reversing order of bytes from specified hexadecimal
# data.
#
# 1st parameter - Hexadecimal representation of data.
sub endian_swap
{
	(my $hex_data = $_[0]) =~ s/\s+//g;
	my @hex_data_array = ($hex_data =~ m/../g);

	return join("", reverse(@hex_data_array));
}

# Subroutine to read a specified number of bytes (starting at the beginning) of a specified file,
# returning hexadecimal representation of data.
#
# 1st parameter - Full path of file to read.
# 2nd parameter - Number of bytes to read.
sub read_bytes
{
	my $file_to_read = $_[0];
	my $bytes_to_read = $_[1];

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