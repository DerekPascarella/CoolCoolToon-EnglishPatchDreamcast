#!/usr/bin/perl
#
# mbin_build.pl
# MBIN archive builder for "Cool Cool Toon".
#
# Written by Derek Pascarella (ateam)

use strict;
use String::HexConvert ':all';

my $folder_source = "/mnt/z/dc/gdi/new/cool_cool_toon/custom_tools/ATL_REBUILT";
my $folder_original_source = "/mnt/z/dc/gdi/new/cool_cool_toon/custom_tools/MBIN_EXTRACTED_ATL";
my $folder_output = "/mnt/z/dc/gdi/new/cool_cool_toon/custom_tools/MBIN_REBUILT";

opendir(DIR, $folder_source);
my @files_source = grep !/^\.\.?$/, readdir(DIR);
closedir(DIR);

for(my $i = 0; $i < scalar(@files_source); $i ++)
{
	if(-d $folder_source . "/" . $files_source[$i])
	{
		my $archive_filename = $files_source[$i];
		print "==========[ Rebuilding \"$archive_filename\" ]==========\n";

		my @file_list_source = ();
		my $file_hex_output = "4d42494e";
		my $file_output = $folder_output . "/" . $archive_filename;

		opendir(DIR, $folder_original_source . "/" . $archive_filename);
		my @files_original_source = grep !/^\.\.?$/, readdir(DIR);
		closedir(DIR);

		for(my $j = 0; $j < scalar(@files_original_source); $j ++)
		{
			if(-e $folder_source . "/" . $files_source[$i] . "/" . $files_original_source[$j])
			{
				push(@file_list_source, $folder_source . "/" . $archive_filename . "/" . $files_original_source[$j]);
				print "Source file " . scalar(@file_list_source) . ": " . $folder_source . "/" . $files_source[$i] . "/" . $files_original_source[$j] . "\n";
			}
			else
			{
				push(@file_list_source, $folder_original_source . "/" . $archive_filename . "/" . $files_original_source[$j]);
				print "Source file " . scalar(@file_list_source) . ": " . $folder_original_source . "/" . $files_original_source[$j] . "\n";
			}
		}

		$file_hex_output .= &endian_swap(&decimal_to_hex(scalar(@file_list_source), 4)) . "000000002000000000000000000000000000000000000000";

		my $file_pointer_padding;

		if(scalar(@file_list_source) % 4 == 0)
		{
			$file_pointer_padding = 4;
		}
		else
		{
			$file_pointer_padding = scalar(@file_list_source);

			while($file_pointer_padding % 4 != 0)
			{
				$file_pointer_padding ++;
			}

			$file_pointer_padding -= scalar(@file_list_source);
		}

		print "Header pointer padding = $file_pointer_padding (" . $file_pointer_padding * 4 . " bytes)\n";

		for(my $j = 0; $j < scalar(@file_list_source); $j ++)
		{
			print "Reading $file_list_source[$j] (" . (stat $file_list_source[$j])[7] . " bytes | pointer = ";
			
			my $file_pointer;

			if($j > 0)
			{
				my $existing_data = 0;

				for(my $k = $j - 1; $k >= 0; $k --)
				{
					$existing_data += (stat $file_list_source[$k])[7];
				}

				$file_pointer = &endian_swap(&decimal_to_hex(32 + (scalar(@file_list_source) * 4) + ($file_pointer_padding * 4) + 0 + $existing_data, 4));
			}
			else
			{
				$file_pointer = &endian_swap(&decimal_to_hex(32 + (scalar(@file_list_source) * 4) + ($file_pointer_padding * 4) + 0, 4));
			}
			
			print "$file_pointer)\n";

			$file_hex_output .= $file_pointer;
		}

		for(1 .. $file_pointer_padding)
		{
			$file_hex_output .= "00000000";
		}

		print "Writing header to \"$archive_filename\"...\n";

		&write_bytes($folder_output . "/" . $archive_filename, $file_hex_output);

		for(my $j = 0; $j < scalar(@file_list_source); $j ++)
		{
			print "Adding $file_list_source[$j]...\n";
			my $file_source_hex = &read_bytes($file_list_source[$j], (stat $file_list_source[$j])[7]);
			&append_bytes($folder_output . "/" . $archive_filename, $file_source_hex);
		}

		print "Rebuild of \"$archive_filename\" complete!\n";
	}
}

# Subroutine to return hexadecimal representation of a decimal number.
#
# 1st parameter - Decimal number.
# 2nd parameter - Number of bytes with which to represent hexadecimal number.
sub decimal_to_hex
{
	return sprintf("%0" . $_[1] * 2 . "X", $_[0]);
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

# Subroutine to append a sequence of hexadecimal values to a specified file.
#
# 1st parameter - Full path of file to append.
# 2nd parameter - Hexadecimal representation of data to be appended to file.
sub append_bytes
{
	my $output_file = $_[0];
	(my $hex_data = $_[1]) =~ s/\s+//g;
	my @hex_data_array = split(//, $hex_data);

	open my $filehandle, '>>', $output_file or die $!;
	binmode $filehandle;

	for(my $i = 0; $i < @hex_data_array; $i += 2)
	{
		my($high, $low) = @hex_data_array[$i, $i + 1];
		print $filehandle pack "H*", $high . $low;
	}

	close $filehandle;
}