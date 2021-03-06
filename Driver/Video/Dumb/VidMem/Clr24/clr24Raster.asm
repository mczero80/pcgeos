COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:           vga24Raster.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92		Initial revision
        FR       9/15/97                24bit version        

DESCRIPTION:

        $Id: vga24Raster.asm $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Blt


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltSimpleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	blt a single scan line 

CALLED BY:	INTERNAL

PASS:		bx	- first x point in simple region
		ax	- last x point in simple region
		d_x1	- left side of blt
		d_x2	- right side of blt
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		if source is to right of destination
		   mask left;
		   copy left byte;
		   mask = ff;
		   copy middle bytes
		   mask right;
		   copy right byte;
		else
		   do the same, but from right to left

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
BltSimpleLine   proc	near
                uses	ds
                .enter

		mov	ds, ss:[bm_lastSegSrc]	; get source segment

		; calc some setup values

                mov     bx, ss:[bmLeft]		; save passed values
                mov     ax, ss:[bmRight]        

		; calculate # bytes to fill in and indices into source and 
		; dest scan lines.  We have to compensate here if the left 
		; side of the clip region is to the right of the left side 
		; of the destination rectangle.

		mov	dx, bx			; save left clipped side
		add	di, bx			; setup dest pointer
		add	di, bx
		add	di, bx
		sub	dx, ss:[d_x1]		; sub dest unclipped left side
		add	dx, ss:[d_x1src]	; get offset to source
		add	si, dx			; add that to source index
		add	si, dx
		add	si, dx
		sub	ax, bx			; ax = count of pixels - 1
		inc	ax			; ax = count of pixels
		mov	cx, ax			; cx = count of pixels
		add	cx, ax
		add	cx, ax			; cx = count of bytes

		mov	ax, ss:[d_x1]		; if going right, copy left
		cmp	ax, ss:[d_x1src]	; 
		jle	goingLeft
		std				; copy backwards
		add	si, cx			; start on right side
		dec	si
		add	di, cx
		dec	di
goingLeft:
		shr	cx, 1
		rep	movsw			; copy 'em
		adc	cx, cx
		rep	movsb			; copy 'em
		cld				; restore direction in case

		.leave
		ret
BltSimpleLine	endp

VidEnds		Blt


VidSegment 	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor8Scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data

CALLED BY:	INTERNAL
		
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor24Scan  proc    near

                mov     bx, ss:[bmLeft]           
                mov     ax, ss:[d_x1]     
                sub     bx, ax     
                mov     cx, bx

                add     si, bx
                add     si, bx
                add     si, bx

                mov     dl, 0FFh
                mov     bx, 0FFFFh

Color24Common   label   near

                ; dl - mask of bitmap
                ; bx - index to mask
                ; cx - offset from left

                push    bx

                ; read mask byte
                and     dl,ss:[lineMask]

                ; mask for testing mask
                and     cl,007h                     
                mov     dh,080h                     
                shr     dh,cl                       

                ; count of pixel per scan
                mov     cx,ss:[bmRight]      
                sub     cx,ss:[bmLeft]       
                inc     cx       

                mov     bx,ss:[bmLeft]      

		add	di, bx
		add	di, bx
		add	di, bx
pixLoop:
		lodsw
		mov	bx, ax
		lodsb

                test    dh, dl
                je      noPix

                mov	{word}es:[di], bx
		mov	{byte}es:[di+2], al
noPix:
                add     di, 3
                shr     dh, 1                  
                jnc     nextPix      
                mov     dh, 080h

                pop     bx
                or      bx, bx

                js      noLineMask

                mov     dl, [bx]                    
                and     dl, ss:[lineMask]
                inc     bx                         
noLineMask:
                push    bx
nextPix:
                loop    pixLoop

                pop     bx

                ret
PutColor24Scan  endp

PutColor24ScanMask      proc    near

                mov     bx, ss:[bmLeft]
                mov     ax, ss:[d_x1]        
                sub     bx, ax               
                mov     dx, bx           
                mov     cx, bx          

                xchg    si, bx        

                add     si, bx      
                add     si, dx
                add     si, dx

                sub     bx, ss:[bmMaskSize]              

                ; override mask pixel

		shr     dx, 3
                add     bx, dx                  

                ; mask for testing mask

		and     cl, 007h             
                mov     dh, 080h                
                shr     dh, cl               

                ; read mask byte

		mov     dl, ds:[bx]                    
                inc     bx                          
                jmp     Color24Common

PutColor24ScanMask      endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor8Scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data

CALLED BY:	INTERNAL
		
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor8Scan	proc	near

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
                mov     cx, bx
                mov	ax, ss:[d_x1]		;
		add	si, bx			; 
		sub	si, ax			; ds:si -> pic bytes

                ; read line mask
                sub     cx, ax
                and     cx, 7                   ; calc mask offset

                mov     dh, ss:[lineMask]       ; real line mask
                ror     dh, cl                  ; shift line mask

		mov	cx, ss:[bmRight]	; compute #bytes to write
		sub	cx, bx			; #bytes-1
		inc	cx

		add	di, bx
		add	di, bx
		add	di, bx			; es:di -> dest byte

                call    PutCol8ScanLow

		ret
PutColor8Scan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PutCol8ScanLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data
                without jump over an page border

CALLED BY:	INTERNAL
		
PASS:           dh      - common byte mask
                cx      - count of pixels to put out
                ds:si   - source data to put out
                es:di   - destination in video memory

RETURN:         ds:si   - source data following
                es:di   - frame ptr of following byte
                dh      - mask shifted right

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
        ----    ----            -----------
	Jim	10/26/92	Initial version
        FR      08/29/97        made the low part

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutCol8ScanLow  proc    near

mapPalette:
		lodsb
                test    dh, 080h
                jz      nopix2

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                add	bx, ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx
nopix2:
                add     di, 3
                rol     dh                      ; rotate line mask

		loop	mapPalette

                ret
PutCol8ScanLow  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PutColor8ScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data

CALLED BY:	INTERNAL
		
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
        ----    ----            -----------
	Jim	10/26/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor8ScanMask	proc	near

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		mov	ax, ss:[d_x1]		; 
		sub	bx, ax			; bx = index into pic data
		mov	dx, bx			; save index
		mov	cx, bx
		xchg	bx, si			; ds:bx -> mask data
		add	si, bx
		sub	bx, ss:[bmMaskSize]	; ds:si -> pic data
		shr	dx, 3			; bx = index into mask
		add	bx, dx			; ds:bx -> into mask data
		and	cl, 7
		mov	dh, 0x80		; test bit for mask data
		shr	dh, cl			; dh = starting mask bit
		mov	cx, ss:[bmRight]	; compute #bytes to write
		sub	cx, ss:[bmLeft]		; #bytes-1
		inc	cx
		mov	dl, ds:[bx]		; get first mask byte
                and     dl, ss:[lineMask]
                inc	bx

                mov     ax, ss:[bmLeft]

		add	di, ax
		add	di, ax
		add	di, ax

                call    PutCol8ScanMaskLow

                ret
PutColor8ScanMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PutCol8ScanMaskLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Draw an 8-bit/pixel scan line of bitmap data with mask
                without jump over an page border

CALLED BY:	INTERNAL
		
PASS:           dh      - common byte mask
                cx      - count of pixels to put out
                ds:si   - source data to put out
                ds:bx   - mask data for scan line
                es:di   - destination in video memory

RETURN:         ds:si   - source data following
                ds:bx   - ptr to next mask byte
                es:di   - frame ptr of following byte
                dh      - mask shifted right

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
        ----    ----            -----------
	Jim	10/26/92	Initial version
        FR      08/29/97        made the low part
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutCol8ScanMaskLow      proc    near

mapPalette:
		lodsb
		test	dl, dh			; do this pixel ?
		jz	paletteNextPixel

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
		add	bx, ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx

paletteNextPixel:
                add     di, 3
		shr	dh, 1			; move test bit down
		jc	paletteReloadTester	;  until we need some more
paletteHaveTester:
		loop	mapPalette
                ret

		; done with this mask byte, get next
paletteReloadTester:
		mov	dl, ds:[bx]		; load next mask byte
                and     dl, ss:[lineMask]
                inc	bx
		mov	dh, 0x80
		jmp	paletteHaveTester

PutCol8ScanMaskLow      endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
PutColorScan	proc	near
		uses	bp
		.enter

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		mov	bp, bx			; get # bits into image
		sub	bp, ss:[d_x1]		; get left coordinate
		mov	ax, ss:[bmRight]	; get right side to get #bytes
		mov	dx, bp			; save low bit
		shr	bp, 1			; bp = #bytes index
		add	si, bp			; index into bitmap

		add	di, bx
		add	di, bx
		add	di, bx

		mov	bp, ax			; get right side in bp
		sub	bp, bx			; bp = # dest bytes to write -1
		inc	bp			; bp = #dest bytes to write

                mov     dh, ss:[lineMask]
                mov     cl, dl
                and     cl, 7
                rol     dh, cl
		mov	cl, 4			; shift amount
                call    PutColScanLow

		.leave
		ret
PutColorScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PutColScanLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Draw an 4-bit/pixel scan line of bitmap data
                without jump over an page border

CALLED BY:	INTERNAL
		
PASS:           dh      - common byte mask
                bp      - count of pixels to put out
                ds:si   - source data to put out
                es:di   - destination in video memory

RETURN:         ds:si   - source data following
                es:di   - frame ptr of following byte
                dh      - mask shifted right

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                lineMask is currently not suppored

REVISION HISTORY:
	Name	Date		Description
        ----    ----            -----------
	Jim	10/26/92	Initial version
        FR      08/29/97        made the low part
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutColScanLow   proc    near

		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	paletteEvenLoop

		; do first one specially
		lodsb

                rol     dh
                jnc     maskLoop5

                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
                shl     ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx

maskLoop5:
                add     di, 3
                xor     dl, 1
		dec	bp
		LONG jz	done

		; specially, though.
paletteEvenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels

                sub     bp, 2
                js      lastByte

                rol     dh
                jnc     maskLoop6

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
		add	bx, ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx

maskLoop6:
                add     di, 3
                xor     dl, 1
		xchg	ah,al
                rol     dh
                jnc     maskLoop7

                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
		add	bx, ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx

maskLoop7:
                add     di, 3
                xor     dl, 1

		tst	bp			; if only one byte to do...
		jnz	paletteEvenLoop
		jmp	done
                
		; odd number of bytes to do.  Last one here...
lastByte:
                rol     dh
                jnc     maskLoop4      

                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
		add	bx, ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx
maskLoop4:
                add     di, 3
                xor     dl, 1
done:
                ret
PutColScanLow   endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen
		applying a bitmap mask

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
PutColorScanMask	proc	near
		uses	bp
		.enter

		; calculate # bytes to fill in

		mov	ax, ss:[bmLeft]
		mov	bp, ax			; get # bits into image
		sub	bp, ss:[d_x1]		; get left coordinate
		mov	dx, bp			; save low bit
		mov	bx, bp			; save pixel index into bitmap
		sar	bp, 1			; compute index into pic data
		sar	bx, 1			; compute index into mask data
		sar	bx, 1
		sar	bx, 1
		add	bx, si			; ds:bx -> mask byte
		sub	bx, ss:[bmMaskSize]	; ds:si -> picture data
		add	si, bp			; ds:si -> into picture data

		mov	bp, ss:[bmRight]	; get right side in bp
		sub	bp, ax			; bp = # dest bytes to write -1
		inc	bp

		mov	cl, dl			; need index into mask byte
		mov	ch, 0x80		; form test bit for BM mask
		and	cl, 7
		shr	ch, cl			; ch = mask test bit
		mov	cl, 4			; cl = pic data shift amount

		; get first mask byte

		mov	dh, ds:[bx]		; dh = mask byte
                and     dh, ss:[lineMask]
                inc	bx			; get ready for next mask byte

		add	di, ax
		add	di, ax
		add	di, ax

                call    PutColScanMaskLow

		.leave
		ret
PutColorScanMask endp

PutColScanMaskLow       proc    near
                
		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	paletteEvenLoop

		; do first one specially

		lodsb
		test	dh, ch			; mask bit set ?
		jz	paletteDoneFirst

                push    ax, bx
                clr     ah
                and     al, 00Fh
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
		add	bx, ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx

paletteDoneFirst:
                add     di, 3
                xor     dl, 1
		shr	ch, 1			; test next bit
                jnc     loop2
		mov	dh, ds:[bx]		; load next mask byte
                and     dh, ss:[lineMask]
                inc	bx
		mov	ch, 0x80		; reload test bit
loop2:
		dec	bp
		jz	done

		; specially, though.
paletteEvenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels
		test	dh, ch			; check pixel
		jz	paletteDoSecond

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
		add	bx, ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx

paletteDoSecond:
                add     di, 3
                xor     dl, 1
                shr     ch, 1
		dec	bp			; one less to go
		jz	done
		test	dh, ch
		jz	paletteNextPixel
		mov	al, ah			; get second pixel value in al

                push    ax, bx
                clr     ah
                push    es

		les	bx, ss:[bmPalette]	; es:bx - palette

                add     bx, ax
		add	bx, ax
                add     bx, ax

                mov     ax, es:[bx]
                mov     bl, es:[bx+2]

                pop     es

                mov     es:[di], ax
                mov     es:[di+2], bl

                pop     ax, bx

paletteNextPixel:
                add     di, 3
                xor     dl, 1
		shr	ch, 1
		jc	paletteReloadTester
paletteHaveTester:
		dec	bp
		jnz	paletteEvenLoop
done:
                ret

paletteReloadTester:
		mov	dh, ds:[bx]		; get next mask byte
                and     dh, ss:[lineMask]
                inc	bx
		mov	ch, 0x80
		jmp	paletteHaveTester

PutColScanMaskLow       endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillBWScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen
		draws monochrome info as a mask, using current area color

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		set drawing color;
		mask left;
		shift and copy left byte;
		shift and copy middle bytes
		mask right;
		shift and copy right byte;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PutBWScan	proc	near
		mov	{word}ss:[currentColor].RGB_red, 0
		mov	{byte}ss:[currentColor].RGB_blue, 0
		FALL_THRU FillBWScan
PutBWScan	endp

FillBWScan	proc	near
		push	bp
		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		add	di, bx		; add to screen offset
		add	di, bx
		add	di, bx
		mov	bp, bx		; get #bits into image at start
		mov	cx, ss:[d_x1]	; get left coordinate
		sub	bp, cx		; bp = (bmLeft-x1)
		sub	ax, cx		; ax = (bmRight-x1)
		mov	dh, al		; figure new right mask
		and	dh, 7
		mov	ss:[bmShift], dh
		mov	bx, bp		; save low three bits of x indx
		mov	cl, 3
		sar	bp, cl		; compute byte index
		add	si, bp		; add bytes-to-left-side
		sar	ax, cl
		sub	ax, bp		; ax = (#srcBytes-1) to write
		mov	cx, bx
		and	cl, 7
		mov	dh, 0x80	; dh = test bit
		shr	dh, cl		;       properly aligned
		mov	cx, ax		; cx = source byte count - 1
		mov	ah, ss:lineMask	; draw mask to use
		jcxz	lastByte

		; for each byte of input data
byteLoop:
		lodsb			; next data byte
		call	WriteMonoByte
		loop	byteLoop

		; the loop will do all but the last byte.  It's probably a 
		; partial byte, so apply the right mask before finishing
lastByte:
		mov	al, 0x80
		mov	cl, ss:[bmShift]	
		sar	al, cl
		and	ah, al
		lodsb
		call	WriteMonoByte
		
		pop	bp
		ret
FillBWScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteMonoByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a monochrome source byte to the screen

CALLED BY:	INTERNAL
		PutBWScan
PASS:		al	- byte to write
		ah	- bitmap draw mask
		dh	- bit mask of bit to start with
		es:di	- frame buffer pointer
		dl	- color to use to draw
RETURN:		dh	- 0x80
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteMonoByte	proc	near
		and	al, ah		; apply bitmap mask
pixLoop:
		test	al, dh		; check next pixel
		jz	nextPixel

		mov	bx, {word}es:[di]
		mov	dl, {byte}es:[di+2]
		call	ss:[modeRoutine]
		mov	{word}es:[di], bx	; store pixel color
		mov	{byte}es:[di+2], dl
nextPixel:
		add	di, 3		; next pixel
		shr	dh, 1		; go until we hit a carry
		jnc	pixLoop

		mov	dh, 0x80	; reload test bit
		ret
WriteMonoByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a monochrome bitmap with a store mask

CALLED BY:	see above
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutBWScanMask	proc	near
		uses	bp
		.enter
		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		add	di, bx		; add to screen offset too
		add	di, bx
		add	di, bx
		mov	bp, bx		; get #bits into image at start
		mov	cx, ss:[d_x1]	; get left coordinate
		sub	bp, cx		; bp = (bmLeft-x1)
		sub	ax, cx		; ax = (bmRight-x1)
		mov	dl, al		; figure new right mask
		and	dl, 7
		mov	ss:[bmShift], dl
		mov	dx, bp		; save low three bits of x indx
		mov	cl, 3		; want to get byte indices
		sar	bp, cl
		add	si, bp		; add bytes-to-left-side
		sar	ax, cl
		sub	ax, bp		; ax = (#srcBytes-1) to write
		mov	cl, dl		; need low three bits of index
		and	cl, 7
		mov	dh, 0x80	; dh = test bit
		shr	dh, cl		;       properly aligned
		clr	dl		; dl = color to draw
		mov	cx, ax		; cx = source byte count - 1
		mov	bp, si		; ds:bp -> mask data
		sub	bp, ss:[bmMaskSize] ; ds:si -> picture data
		jcxz	lastByte

		; for each byte of input data
byteLoop:
		lodsb			; next data byte
		mov	ah, ds:[bp]	; get mask byte
		inc	bp
		and	ah, ss:lineMask
		call	WriteMonoByte
		loop	byteLoop

		; the loop will do all but the last byte.  It's probably a 
		; partial byte, so apply the right mask before finishing
lastByte:
		mov	ah, 0x80
		mov	cl, ss:[bmShift]
		sar	ah, cl
		and	ah, ds:[bp]
		and	ah, ss:lineMask
		lodsb
		call	WriteMonoByte
		
		.leave
		ret
PutBWScanMask	endp

NullBMScan	proc	near
		ret
NullBMScan	endp

VidEnds		Bitmap


VidSegment	Misc


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOneScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one scan line of video buffer to system memory

CALLED BY:	INTERNAL
		VidGetBits

PASS:		ds:si	- address of start of scan line in frame buffer
		es:di	- pointer into sys memory where scan line to be stored
		cx	- # bytes left in buffer
		d_x1	- left side of source
		d_dx	- # source pixels
		shiftCount - # bits to shift

RETURN:		es:di	- pointer moved on past scan line info just stored
		cx	- # bytes left in buffer
			- set to -1 if not enough room to fit next scan (no
			  bytes are copied)

DESTROYED:	ax,bx,dx,si

PSEUDO CODE/STRATEGY:
		if (there's enough room to fit scan in buffer)
		   copy the scan out
		else
		   just return

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOneScan	proc	near
		uses	si
		.enter

		; form full address, copy bytes
                mov     dx, ss:[d_dx]
                add	dx, dx
                add     dx, ss:[d_dx]

		cmp	cx, dx			; get width to copy
		jc	noRoom

                mov     ax, ss:[d_x1]
		add	si, ax
		add	si, ax
		add	si, ax

		sub	cx, dx			; cx = bytes left after copy
		xchg	cx, dx			; dx = bytes left after copy
		shr	cx, 1
		rep	movsw
		adc	cx, cx
		rep	movsb
		mov	cx, dx			; cx = bytes left after copy
done:
		.leave
		ret

		; not enough room to copy scan line
noRoom:
		mov	cx, 0xffff
                jmp     done

GetOneScan	endp

VidEnds		Misc

VidSegment	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ByteModeRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various stub routines to implement mix modes

CALLED BY:	INTERNAL
		various low-level drawing routines
PASS:		dl - color
		bl - screen
RETURN:		bl - destination (byte to write out)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ByteModeRoutines	proc		near
	ForceRef ByteModeRoutines

ByteCLEAR	label near
                clr     bx
                clr     dl
ByteNOP		label near
		ret
ByteCOPY	label  near
                mov     bx, {word} ss:[currentColor].RGB_red
                mov     dl, ss:[currentColor].RGB_blue
		ret
ByteAND		label  near		
                and     bx, {word} ss:[currentColor].RGB_red
                and     dl, ss:[currentColor].RGB_blue
		ret
ByteINV		label  near
                xor     bx, 0FFFFh
                xor     dl, 0FFh
		ret
ByteXOR		label  near
                xor     bx, {word} ss:[currentColor].RGB_red
                xor     dl, ss:[currentColor].RGB_blue
		ret
ByteSET		label  near
                mov     bx, 0FFFFh
                mov     dl, 0FFh
		ret
ByteOR		label  near
                or      bx, {word} ss:[currentColor].RGB_red
                or      dl, ss:[currentColor].RGB_blue
		ret
ByteModeRoutines	endp


ByteModeRout	label	 word
	nptr	ByteCLEAR
	nptr	ByteCOPY
	nptr	ByteNOP
	nptr	ByteAND
	nptr	ByteINV
	nptr	ByteXOR
	nptr	ByteSET
	nptr	ByteOR

VidEnds		Bitmap
