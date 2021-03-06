/*
 * Copyright (c) 1980, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#if defined(LIBC_SCCS) && !defined(lint)
	.asciz "@(#)_setjmp.s	8.1 (Berkeley) 6/4/93"
#endif /* LIBC_SCCS and not lint */

/*
 * C library -- _setjmp, _longjmp
 *
 *	_longjmp(a,v)
 * will generate a "return(v)" from
 * the last call to
 *	_setjmp(a)
 * by restoring registers from the stack,
 * The previous signal state is NOT restored.
 */

#include "DEFS.h"

ENTRY(_setjmp, 0)
	movl	4(ap),r0
	movl	12(fp),(r0)		# save frame pointer of caller
	movl	16(fp),4(r0)		# save pc of caller
	clrl	r0
	ret

ENTRY(_longjmp, 0)
	movl	8(ap),r0		# return(v)
	movl	4(ap),r1		# fetch buffer
	tstl	(r1)
	beql	botch
loop:
	bitw	$1,6(fp)		# r0 saved?
	beql	1f
	movl	r0,20(fp)
	bitw	$2,6(fp)		# was r1 saved?
	beql	2f
	movl	r1,24(fp)
	brb	2f
1:
	bitw	$2,6(fp)		# was r1 saved?
	beql	2f
	movl	r1,20(fp)
2:
	cmpl	(r1),12(fp)
	beql	done
	blssu	botch
	movl	$loop,16(fp)
	ret				# pop another frame

done:
	cmpb	*16(fp),reiins		# returning to an "rei"?
	bneq	1f
	movab	3f,16(fp)		# do return w/ psl-pc pop
	brw	2f
1:
	movab	4f,16(fp)		# do standard return
2:
	ret				# unwind stack before signals enabled
3:
	addl2	$8,sp			# compensate for PSL-PC push
4:
	jmp	*4(r1)			# done, return....

botch:
	calls	$0,_longjmperror
	halt

	.data
reiins: rei
