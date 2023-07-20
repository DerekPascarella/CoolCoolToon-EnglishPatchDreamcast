#!/usr/bin/perl
#
# nsi_build_from_spreadsheet.pl
# NSI archive builder for "Cool Cool Toon".
#
# Written by Derek Pascarella (ateam)

# Include necessary modules.
use utf8;
use strict;
use HTML::Entities;
use String::HexConvert ':all';
use Spreadsheet::Read qw(ReadData);

# Initialize/declare initial variables.
my $file_input = $ARGV[0];
(my $file_input_basename = $file_input) =~ s{^.*/|\.[^.]+$}{}g;
my $folder_output = "/mnt/z/dc/gdi/new/cool_cool_toon/custom_tools/NSI_REBUILT/";
my $folder_source = "/mnt/z/dc/gdi/new/cool_cool_toon/gdi_original_extracted/CCT/";
my %sjis_character_map = &generate_character_map_hash("sjis_char_map.txt");
my $rolling_offset = 0;
my $rolling_hex;
my %new_pointers;

# Read and store spreadsheet.
my $spreadsheet = ReadData($file_input);
my @spreadsheet_rows = Spreadsheet::Read::rows($spreadsheet->[1]);

# Store offset of first text chunk, representing length of file before text starts.
my $nsi_file_pre_text_size = int($spreadsheet_rows[1][0]);

# Store contents of original NSI file before text processing starts.
print "Storing initial portion of NSI file...\n";
my $nsi_file_hex = lc(&read_bytes($folder_source . "/" . $file_input_basename, $nsi_file_pre_text_size));

# Status message.
print "Processing script file \"$file_input_basename\.xlsx\" (" . scalar(@spreadsheet_rows) . " rows)...\n";

# Iterate through each row of spreadsheet.
for(my $i = 1; $i < scalar(@spreadsheet_rows); $i ++)
{
	# Status message.
	print "----ROW $i----\n";

	# Store data from current spreadsheet row.
	my $offset = int($spreadsheet_rows[$i][0]);
	my $japanese_text = decode_entities($spreadsheet_rows[$i][1]);
	my $english_text_raw = decode_entities($spreadsheet_rows[$i][2]);

	# Clean English text.
	$english_text_raw =~ s/…/\.\.\./g;
	$english_text_raw =~ s/’/'/g;
	$english_text_raw =~ s/”/"/g;
	$english_text_raw =~ s/“/"/g;
	$english_text_raw =~ s/[\r\n]+/ /g;
	$english_text_raw =~ s/[\r]+/ /g;
	$english_text_raw =~ s/[\n]+/ /g;
	$english_text_raw =~ s/\P{IsPrint}//g;
	$english_text_raw =~ s/[^[:ascii:]]+//g;
	$english_text_raw =~ s/\b(all right)\b/alright/g;
	$english_text_raw =~ s/\b(All right)\b/Alright/g;
	$english_text_raw =~ s/\b(ALL RIGHT)\b/ALRIGHT/g;
	$english_text_raw =~ s/ +/ /;
	$english_text_raw =~ s/\s+/ /g;
	$english_text_raw =~ s/’/'/g;
	$english_text_raw =~ s/”/"/g;
	$english_text_raw =~ s/“/"/g;
	$english_text_raw =~ s/\.{4,}/\.\.\./g;
	$english_text_raw =~ s/…/\.\.\./g;
	$english_text_raw =~ s/\.\.\.\!\?/\.\.\.\?\!/g;
	$english_text_raw =~ s/^\s+|\s+$//g;

	# Account for string entries of one or more empty spaces.
	if($english_text_raw eq "")
	{
		$english_text_raw = " ";
	}

	# Status message.
	print "Original offset: " . $offset . " / 0x". &decimal_to_hex($offset, 4) . "\n";
	print "Original pointer: " . &endian_swap(&decimal_to_hex($offset, 4)) . "\n";
	print "English text: " . $english_text_raw . "\n";

	# Initialize empty variable for storing each dialogue instance's hex representation.
	my $english_text_hex = "";

	# If line starts with open bracket ([) and ends with close bracket (]), consider it speaker's name and process
	# as Shift-JIS, removing brackets.
	if($english_text_raw =~ /^\[[a-zA-Z].*\]$/)
	{
		# Prepend Shift-JIS space to speaker name.
		$english_text_hex = "8140";

		# Remove open and close brackets.
		$english_text_raw =~ s/\[//g;
		$english_text_raw =~ s/\]//g;

		my @speaker_name_characters = split(//, $english_text_raw);

		# Append Shift-JIS speaker name to hex data.
		foreach(@speaker_name_characters)
		{
			$english_text_hex .= $sjis_character_map{uc($_)};
		}
	}
	# Otherwise, process normal dialogue text.
	else
	{
		# Convert text to ASCII-encoded byte-string.
		$english_text_hex = ascii_to_hex($english_text_raw);

		# Prepend a Shift-JIS blank space to English text if Japanese equivalent starts with two ASCII spaces, or Shift-JIS
		# open bracket (「).
		if(ascii_to_hex($japanese_text) =~ /^ff2020/i || ascii_to_hex($japanese_text) =~ /^2020/i
			|| ascii_to_hex($japanese_text) =~ /^ff0c/i || ascii_to_hex($japanese_text) =~ /^0c/i)
		{
			$english_text_hex = "8140" . $english_text_hex;
		}

		# Replace any double less-than/greater-than signs (<< and >>) with Shift-JIS equivalent (《 and 》).
		$english_text_hex =~ s/3c3c20/8173/gi;
		$english_text_hex =~ s/203e3e/8174/gi;

		# Throw warnings if English text consumes too much horizontal space.
		if(($english_text_hex =~ /^8140/ && length($english_text_hex) / 2 > 50)
			|| ($english_text_hex !~ /^8140/ && length($english_text_hex) / 2 > 48))
		{
			print "WARNING: Oversized dialogue entry!\n";
			system "echo \"[$file_input_basename]\" >> ./warning_nsi.log";
			system "echo \"$english_text_raw\" >> ./warning_nsi.log";
			system "echo \"String number $i\n\" >> ./warning_nsi.log";
		}
	}

	# Process hex representation of English text for "fancy" double-quotes.
	my @english_text_hex_bytes = ($english_text_hex =~ m/../g);

	my $quote_start_found = 0;

	foreach(@english_text_hex_bytes)
	{
		if($_ eq "22" && $quote_start_found == 0)
		{
			$_ = "5C";

			$quote_start_found = 1;
		}
		elsif($_ eq "22")
		{
			$quote_start_found = 0;
		}
	}

	$english_text_hex = join("", @english_text_hex_bytes);

	# Pad end of data to be evenly divisible by 4 bytes.
	$english_text_hex .= "00";

	while((length($english_text_hex) / 2) % 4 != 0)
	{
		$english_text_hex .= "00";
	}

	# Status message.
	print "Hex representation: " . $english_text_hex . "\n";

	# Append to rolling hex representation of new string data.
	$rolling_hex .= $english_text_hex;

	# Update rolling offset for first entry.
	if($rolling_offset == 0)
	{
		# Start rolling offset at the beginning.
		$rolling_offset = $offset;
		
		# Status message.
		print "String's starting offset: " . $rolling_offset . " / 0x". &decimal_to_hex($rolling_offset, 4) . "\n";
		print "String's starting pointer: " . &endian_swap(&decimal_to_hex($rolling_offset, 4)) . "\n";
		
		# Calculate and store rolling offset.
		$rolling_offset += length($english_text_hex) / 2;
	}
	# Update rolling offset for all additional entries, while also modifying original pointer value.
	else
	{
		# Status message.
		print "New offset: " . $rolling_offset . " / 0x". &decimal_to_hex($rolling_offset, 4) . "\n";
		print "New pointer: " . &endian_swap(&decimal_to_hex($rolling_offset, 4)) . "\n";

		# Initialize/declare variables.
		my $pointer_original = lc(&endian_swap(&decimal_to_hex($offset, 4)));
		my $pointer_new = lc(&endian_swap(&decimal_to_hex($rolling_offset, 4)));
		my $match_rolling_index = 0;
		my $match_rolling_offset = 0;
		my $match_count = 0;
		my $bytes_index;

		# Create new empty array to store all offsets at which original pointer was found.
		my @new_pointer_offset = ();

		# Store index of first match in target file.
		$match_rolling_index = index($nsi_file_hex, $pointer_original, $match_rolling_offset);

		# Continue searching target file for additional matches.
		while($match_rolling_index != -1)
		{
			# Store offset of match.
			$bytes_index = index($nsi_file_hex, $pointer_original, $match_rolling_offset) / 2;

			# Add offset of old pointer to array.
			push(@new_pointer_offset, $bytes_index);

			# Increase match count by one.
			$match_count ++;

			# Increase search offset by four bytes.
			$match_rolling_offset = $match_rolling_index + 8;

			# Store index of next potential match.
			$match_rolling_index = index($nsi_file_hex, $pointer_original, $match_rolling_offset);
		}

		# Store old pointer array in a new key in the new pointers hash.
		if(@new_pointer_offset)
		{
			$new_pointers{$pointer_new} = [@new_pointer_offset];
		}

		#Status message.
		print "Number of pointers updated: " . $match_count . "\n";
		
		# Calculate and store rolling offset.
		$rolling_offset += length($english_text_hex) / 2;
	}
}

# Status message.
print "--------------\n";
print "Updating new pointers...\n";

# Iterate through each pointer key, updating each offset with its new value.
foreach my $pointer (keys %new_pointers)
{
	print "-" . uc($pointer) . ":\n";

	foreach my $offset(@{$new_pointers{$pointer}})
	{
		print " * Offset " . $offset . " (0x" . &decimal_to_hex($offset, 4) . ")\n";

		substr($nsi_file_hex, $offset * 2, 8) = $pointer;
	}
}

# Write new NSI file.
&write_bytes($folder_output . "/" . $file_input_basename, $nsi_file_hex . $rolling_hex);

# Status message.
print "New NSI file \"" . $file_input_basename . "\" written!\n";

# Subroutine to return hexadecimal representation of a decimal number.
#
# 1st parameter - Decimal number.
# 2nd parameter - Number of bytes with which to represent hexadecimal number (omit parameter for no
#				  padding).
sub decimal_to_hex
{
	if($_[1] eq "")
	{
		$_[1] = 0;
	}

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

# Subroutine to generate hash mapping ASCII characters to custom hexadecimal values. Source character
# map file should be formatted with each character definition on its own line (<hex>|<ascii>). Example
# character map file:
#  ______
# |	     |
# | 00|A |
# | 01|B |
# | 02|C |
# |______|
#
# The ASCII key in the returned hash will contain the custom hexadecimal value (e.g. $hash{'B'} will
# equal "01").
#
# 1st parameter - Full path of character map file.
sub generate_character_map_hash
{
	my $character_map_file = $_[0];
	my %character_table;

	open my $filehandle, '<', $character_map_file or die $!;
	chomp(my @mapped_characters = <$filehandle>);
	close $filehandle;

	foreach(@mapped_characters)
	{
		$character_table{(split /\|/, $_)[1]} = (split /\|/, $_)[0];
	}

	return %character_table;
}
