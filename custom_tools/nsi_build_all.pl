#!/usr/bin/perl

chop(@files = `ls NSI_EXTRACTED_TRANSLATED`);

foreach(@files)
{
	system "perl nsi_build_from_spreadsheet.pl NSI_EXTRACTED_TRANSLATED/$_";
}
