##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Nimbus Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Gene Anderson
#
# DESCRIPTION:
#	Special definitions required for the Nimbus font driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:45:28 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../FontCom $(INSTALL_DIR:H)/FontCom \

#include	<$(SYSMAKEFILE)>
