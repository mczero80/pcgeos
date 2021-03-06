COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	dBase III
MODULE:		Lib		
FILE:		libFormat.asm

AUTHOR:		Ted H. Kim, 9/14/92

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/92		Initial revision

DESCRIPTION:
	This file contains the library definition of dBase III.	

	$Id: libFormat.asm,v 1.1 97/04/07 11:43:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefTransLib

DefTransFormat	TF_DBASE_THREE, \
		"dBase III", \
		"*.DBF", \
		ImportOptionsGroup, \
		ExportOptionsGroup, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>

EndTransLib	<mask IDC_SPREADSHEET>

idata   segment
	ImpexMappingControlClass
idata   ends
