#!/usr/bin/perl
#
# nsi_extract.pl
# NSI archive extractor for "Cool Cool Toon".
#
# Written by Derek Pascarella (ateam)

use strict;
use utf8;
use JSON;
use POSIX;
use HTTP::Tiny;
use Spreadsheet::WriteExcel;
use Encode qw(decode encode);
use String::HexConvert ':all';
use URI::Encode qw(uri_encode uri_decode);

my $file_input = $ARGV[0];
(my $file_input_basename = $file_input) =~ s{^.*/}{}g;
my $folder_output = $ARGV[1];
my $file_size = (stat $file_input)[7];
my $text_section_offset = hex(&endian_swap(&read_bytes_at_offset($file_input, 4, 108)));
my $text_rolling_offset = $text_section_offset;
my $string_number = 0;
my $end_of_file = 0;
my %text_chunk;

print "------------------------------------\n";
print "Processing $file_input_basename...\n";
print "> File size: $file_size\n";
print "> Initial text offset: $text_section_offset\n";
print "Extracting text chunks...\n";

while($end_of_file == 0)
{
	my $text_bytes = "";
	my $text_byte = "";

	$string_number ++;

	my $text_chunk_offset = $text_rolling_offset;

	while($text_byte ne "00")
	{
		$text_byte = &read_bytes_at_offset($file_input, 1, $text_rolling_offset);
		
		if($text_byte ne "00")
		{
			$text_bytes .= $text_byte;
			$text_rolling_offset ++;
		}
	}

	$text_chunk{$text_chunk_offset} = $text_bytes;

	if((length($text_bytes) / 2) % 4 == 0)
	{
		$text_rolling_offset += 4;
	}
	else
	{
		while($text_rolling_offset % 4 != 0)
		{
			$text_rolling_offset ++;
		}
	}

	if($text_rolling_offset >= (stat $file_input)[7])
	{
		$end_of_file = 1;
	}
}

print "> Text extraction count: $string_number\n";
print "Writing spreadsheet $file_input_basename.xlsx...\n";

&write_spreadsheet(\%text_chunk);

print "Process complete!\n";

print "------------------------------------\n";

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

# Subroutine to write spreadsheet.
sub write_spreadsheet
{
	my $text_chunk = shift;
	my $row_count = 1;

	my $workbook = Spreadsheet::WriteExcel->new("/mnt/z/dc/gdi/new/cool_cool_toon/custom_tools/NSI_EXTRACTED/$file_input_basename.xls");
	my $worksheet = $workbook->add_worksheet();
	my $header_bg_color = $workbook->set_custom_color(40, 191, 191, 191);

	my $header_format = $workbook->add_format();
	$header_format->set_bold();
	$header_format->set_border();
	$header_format->set_bg_color(40);

	my $cell_format = $workbook->add_format();
	$cell_format->set_border();
	$cell_format->set_align('left');
	$cell_format->set_text_wrap();

	$worksheet->set_column('B:B', 65);
	$worksheet->set_column('C:C', 50);
	$worksheet->set_column('D:D', 30);
	$worksheet->set_column('E:E', 50);

	$worksheet->write(0, 0, "Offset", $header_format);
	$worksheet->write(0, 1, "Japanese Text", $header_format);
	$worksheet->write(0, 2, "English Translation", $header_format);
	$worksheet->write(0, 3, "Notes", $header_format);
	$worksheet->write(0, 4, "Machine Translation", $header_format);

	foreach my $offset (sort {$a <=> $b} keys %text_chunk)
	{
		&write_bytes("temp.bin", $text_chunk{$offset});

		my $extracted_string;

		open(FH, '<', "temp.bin") or die $!;

		while(<FH>)
		{
			$extracted_string .= Encode::encode("utf-8", Encode::decode("shiftjis", $_));
		}

		close(FH);

		unlink("temp.bin");

		my $japanese_text = Encode::decode("utf-8", $extracted_string);
		$japanese_text =~ s/\r\n//g;
		$japanese_text =~ s/\r//g;
		$japanese_text =~ s/\n//g;

		my $http = HTTP::Tiny->new;
		my $post_data = uri_encode("auth_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&target_lang=EN-US&source_lang=JA&text=" . $japanese_text);
		my $response = $http->get("https://api-free.deepl.com/v2/translate?" . $post_data);
		my $machine_translation = decode_json($response->{'content'})->{'translations'}->[0]->{'text'};

		$worksheet->write($row_count, 0, $offset, $cell_format);
		$worksheet->write_utf16be_string($row_count, 1, Encode::encode("utf-16", Encode::decode("utf-8", $extracted_string)), $cell_format);
		$worksheet->write($row_count, 2, "", $cell_format);
		$worksheet->write($row_count, 3, "", $cell_format);
		$worksheet->write($row_count, 4, "$machine_translation", $cell_format);

		$row_count ++;
	}

	$workbook->close();
}