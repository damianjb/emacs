;;; ebnf2ps --- Translate an EBNF to a syntatic chart on PostScript

;; Copyright (C) 1999, 2000 Free Software Foundation, Inc.

;; Author:     Vinicius Jose Latorre <vinicius@cpqd.com.br>
;; Maintainer: Vinicius Jose Latorre <vinicius@cpqd.com.br>
;; Keywords:   wp, ebnf, PostScript
;; Time-stamp: <2000/07/29 13:09:47 vinicius>
;; Version:    3.2
;; X-URL: http://www.cpqd.com.br/~vinicius/emacs/Emacs.html

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

(defconst ebnf-version "3.2"
  "ebnf2ps.el, v 3.2 <2000/07/29 vinicius>

Vinicius's last change version.  When reporting bugs, please also
report the version of Emacs, if any, that ebnf2ps was running with.

Please send all bug fixes and enhancements to
	Vinicius Jose Latorre <vinicius@cpqd.com.br>.
")


;;; Commentary:

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Introduction
;; ------------
;;
;; This package translates an EBNF to a syntatic chart on PostScript.
;;
;; To use ebnf2ps, insert in your ~/.emacs:
;;
;;        (require 'ebnf2ps)
;;
;; ebnf2ps uses ps-print package (version 5.2.3 or later), so see ps-print to
;; know how to set options like landscape printing, page headings, margins,
;; etc.
;;
;; NOTE: ps-print zebra stripes and line number options doesn't have effect on
;;       ebnf2ps, they behave as it's turned off.
;;
;; For good performance, be sure to byte-compile ebnf2ps.el, e.g.
;;
;;    M-x byte-compile-file <give the path to ebnf2ps.el when prompted>
;;
;; This will generate ebnf2ps.elc, which will be loaded instead of ebnf2ps.el.
;;
;; ebnf2ps was tested with GNU Emacs 20.4.1.
;;
;;
;; Using ebnf2ps
;; -------------
;;
;; ebnf2ps provides six commands for generating PostScript syntatic chart
;; images of Emacs buffers:
;;
;;	ebnf-print-buffer
;;	ebnf-print-region
;;	ebnf-spool-buffer
;;	ebnf-spool-region
;;	ebnf-eps-buffer
;;	ebnf-eps-region
;;
;; These commands all perform essentially the same function: they generate
;; PostScript syntatic chart images suitable for printing on a PostScript
;; printer or displaying with GhostScript.  These commands are collectively
;; referred to as "ebnf- commands".
;;
;; The word "print", "spool" and "eps" in the command name determines when the
;; PostScript image is sent to the printer (or file):
;;
;;	print  - The PostScript image is immediately sent to the printer;
;;
;;	spool  - The PostScript image is saved temporarily in an Emacs buffer.
;;		 Many images may be spooled locally before printing them.  To
;;		 send the spooled images to the printer, use the command
;;		 `ebnf-despool'.
;;
;;	eps    - The PostScript image is immediately sent to a EPS file.
;;
;; The spooling mechanism is the same as used by ps-print and was designed for
;; printing lots of small files to save paper that would otherwise be wasted on
;; banner pages, and to make it easier to find your output at the printer (it's
;; easier to pick up one 50-page printout than to find 50 single-page
;; printouts).  As ebnf2ps and ps-print use the same Emacs buffer to spool
;; images, you can intermix the spooling of ebnf2ps and ps-print images.
;;
;; ebnf2ps use the same hook of ps-print in the `kill-emacs-hook' so that you
;; won't accidentally quit from Emacs while you have unprinted PostScript
;; waiting in the spool buffer.  If you do attempt to exit with spooled
;; PostScript, you'll be asked if you want to print it, and if you decline,
;; you'll be asked to confirm the exit; this is modeled on the confirmation
;; that Emacs uses for modified buffers.
;;
;; The word "buffer" or "region" in the command name determines how much of the
;; buffer is printed:
;;
;;	buffer  - Print the entire buffer.
;;
;;	region  - Print just the current region.
;;
;; Two ebnf- command examples:
;;
;;	ebnf-print-buffer  - translate and print the entire buffer, and send it
;;			     immediately to the printer.
;;
;;	ebnf-spool-region  - translate and print just the current region, and
;;			     spool the image in Emacs to send to the printer
;;			     later.
;;
;; Note that `ebnf-eps-buffer' and `ebnf-eps-region' never spool the EPS image,
;; so they don't use the ps-print spooling mechanism.  See section "Actions in
;; Comments" for an explanation about EPS file generation.
;;
;;
;; Invoking Ebnf2ps
;; ----------------
;;
;; To translate and print your buffer, type
;;
;;        M-x ebnf-print-buffer
;;
;; or substitute one of the other four ebnf- commands.  The command will
;; generate the PostScript image and print or spool it as specified.  By giving
;; the command a prefix argument
;;
;;        C-u M-x ebnf-print-buffer
;;
;; it will save the PostScript image to a file instead of sending it to the
;; printer; you will be prompted for the name of the file to save the image to.
;; The prefix argument is ignored by the commands that spool their images, but
;; you may save the spooled images to a file by giving a prefix argument to
;; `ebnf-despool':
;;
;;        C-u M-x ebnf-despool
;;
;; When invoked this way, `ebnf-despool' will prompt you for the name of the
;; file to save to.
;;
;; The prefix argument is also ignored by `ebnf-eps-buffer' and
;; `ebnf-eps-region'.
;;
;; Any of the `ebnf-' commands can be bound to keys.  Here are some examples:
;;
;;   (global-set-key 'f22 'ebnf-print-buffer) ;f22 is prsc
;;   (global-set-key '(shift f22) 'ebnf-print-region)
;;   (global-set-key '(control f22) 'ebnf-despool)
;;
;;
;; EBNF Syntax
;; -----------
;;
;; The current EBNF that ebnf2ps accepts has the following constructions:
;;
;;    ;			comment (until end of line)
;;    A			non-terminal
;;    "C"		terminal
;;    ?C?		special
;;    $A		default non-terminal (see text below)
;;    $"C"		default terminal (see text below)
;;    $?C?		default special (see text below)
;;    A = B.		production (A is the header and B the body)
;;    C D		sequence (C occurs before D)
;;    C | D		alternative (C or D occurs)
;;    A - B		exception (A excluding B, B without any non-terminal)
;;    n * A		repetition (A repeats n (integer) times)
;;    (C)		group (expression C is grouped together)
;;    [C]		optional (C may or not occurs)
;;    C+		one or more occurrences of C
;;    {C}+		one or more occurrences of C
;;    {C}*		zero or more occurrences of C
;;    {C}		zero or more occurrences of C
;;    C / D		equivalent to: C {D C}*
;;    {C || D}+		equivalent to: C {D C}*
;;    {C || D}*		equivalent to: [C {D C}*]
;;    {C || D}		equivalent to: [C {D C}*]
;;
;; The EBNF syntax written using the notation above is:
;;
;;    EBNF = {production}+.
;;
;;    production = non_terminal "=" body ".".   ;; production
;;
;;    body = {sequence || "|"}*.                ;; alternative
;;
;;    sequence = {exception}*.                  ;; sequence
;;
;;    exception = repeat [ "-" repeat].         ;; exception
;;
;;    repeat = [ integer "*" ] term.            ;; repetition
;;
;;    term = factor
;;         | [factor] "+"                       ;; one-or-more
;;         | [factor] "/" [factor]              ;; one-or-more
;;         .
;;
;;    factor = [ "$" ] "\"" terminal "\""       ;; terminal
;;           | [ "$" ] non_terminal             ;; non-terminal
;;           | [ "$" ] "?" special "?"          ;; special
;;           | "(" body ")"                     ;; group
;;           | "[" body "]"                     ;; zero-or-one
;;           | "{" body [ "||" body ] "}+"      ;; one-or-more
;;           | "{" body [ "||" body ] "}*"      ;; zero-or-more
;;           | "{" body [ "||" body ] "}"       ;; zero-or-more
;;           .
;;
;;    non_terminal = "[A-Za-z\\240-\\377][!#%&'*-,0-:<>@-Z\\^-z~\\240-\\377]*".
;;
;;    terminal = "\\([^\"\\]\\|\\\\[ -~\\240-\\377]\\)+".
;;
;;    special = "[^?\\n\\000-\\010\\016-\\037\\177-\\237]*".
;;
;;    integer = "[0-9]+".
;;
;;    comment = ";" "[^\\n\\000-\\010\\016-\\037\\177-\\237]*" "\\n".
;;
;; Try to use the above EBNF to test ebnf2ps.
;;
;; The `default' terminal, non-terminal and special is a way to indicate a
;; default path in a production.  For example, the production:
;;
;;    X = [ $A ( B | $C ) | D ].
;;
;; Indicates that the default meaning for "X" is "A C" if "X" is empty.
;;
;; The terminal name is controlled by `ebnf-terminal-regexp' and
;; `ebnf-case-fold-search', so it's possible to match other kind of terminal
;; name besides that enclosed by `"'.
;;
;; Let's see an example:
;;
;;    (setq ebnf-terminal-regexp "[A-Z][_A-Z]*") ; upper case name
;;    (setq ebnf-case-fold-search nil) ; exact matching
;;
;; If you have the production:
;;
;;    Logical = "(" Expression ( OR | AND | "XOR" ) Expression ")".
;;
;; The names are classified as:
;;
;;    Logical  Expression		non-terminal
;;    "("  OR  AND  "XOR"  ")"		terminal
;;
;; The line comment is controlled by `ebnf-lex-comment-char'.  The default
;; value is ?\; (character `;').
;;
;; The end of production is controlled by `ebnf-lex-eop-char'.  The default
;; value is ?. (character `.').
;;
;; The variable `ebnf-syntax' specifies which syntax to recognize:
;;
;;    `ebnf'		ebnf2ps recognizes the syntax described above.
;;			The following variables *ONLY* have effect with this
;;			setting:
;;			`ebnf-terminal-regexp', `ebnf-case-fold-search',
;;			`ebnf-lex-comment-char' and `ebnf-lex-eop-char'.
;;
;;    `iso-ebnf'	ebnf2ps recognizes the syntax described in the URL:
;;			`http://www.cl.cam.ac.uk/~mgk25/iso-ebnf.html'
;;			("International Standard of the ISO EBNF Notation").
;;			The following variables *ONLY* have effect with this
;;			setting:
;;			`ebnf-iso-alternative-p' and `ebnf-iso-normalize-p'.
;;
;;    `yacc'		ebnf2ps recognizes the Yacc/Bison syntax.
;;			The following variable *ONLY* has effect with this
;;			setting:
;;			`ebnf-yac-ignore-error-recovery'.
;;
;; Any other value is treated as `ebnf'.
;;
;; The default value is `ebnf'.
;;
;;
;; Optimizations
;; -------------
;;
;; The following EBNF optimizations are done:
;;
;;    [ { A }* ]          ==> { A }*
;;    [ { A }+ ]          ==> { A }*
;;    [ A ] +             ==> { A }*
;;    { A }* +            ==> { A }*
;;    { A }+ +            ==> { A }+
;;    { A }-              ==> { A }+
;;    [ A ]-              ==> A
;;    ( A | EMPTY )-      ==> A
;;    ( A | B | EMPTY )-  ==> A | B
;;    [ A | B ]           ==> A | B | EMPTY
;;    n * EMPTY           ==> EMPTY
;;    EMPTY +             ==> EMPTY
;;    EMPTY / EMPTY       ==> EMPTY
;;    EMPTY - A           ==> EMPTY
;;
;; The following optimizations are done when `ebnf-optimize' is non-nil:
;;
;; left recursion:
;;    1.  A = B | A C.             ==>   A = B {C}*.
;;    2.  A = B | A B.             ==>   A = {B}+.
;;    3.  A =   | A B.             ==>   A = {B}*.
;;    4.  A = B | A C B.           ==>   A = {B || C}+.
;;    5.  A = B | D | A C | A E.   ==>   A = ( B | D ) { C | E }*.
;;
;; optional:
;;    6.  A = B | .                ==>   A = [B].
;;    7.  A =   | B .              ==>   A = [B].
;;
;; factoration:
;;    8.  A = B C | B D.           ==>   A = B (C | D).
;;    9.  A = C B | D B.           ==>   A = (C | D) B.
;;    10. A = B C E | B D E.       ==>   A = B (C | D) E.
;;
;; The above optimizations are specially useful when `ebnf-syntax' is `yacc'.
;;
;;
;; Form Feed
;; ---------
;;
;; You may use form feed (^L \014) to force a production to start on a new
;; page, for example:
;;
;;    a) A = B | C.
;;	 ^L
;;	 X = Y | Z.
;;
;;    b) A = B ^L | C.
;;	 X = Y | Z.
;;
;;    c) A = B ^L^L^L | C.^L
;;	 ^L
;;	 X = Y | Z.
;;
;; In all examples above, only the production X will start on a new page.
;;
;;
;; Actions in Comments
;; -------------------
;;
;; ebnf2ps accepts the following actions in comments:
;;
;;    ;>	the next production starts in the same line as the current one.
;;		It is useful when `ebnf-horizontal-orientation' is nil.
;;
;;    ;<	the next production starts in the next line.
;;		It is useful when `ebnf-horizontal-orientation' is non-nil.
;;
;;    ;[EPS	open a new EPS file.  The EPS file name has the form:
;;			<PREFIX><NAME>.eps
;;		where <PREFIX> is given by variable `ebnf-eps-prefix' and
;;		<NAME> is the string given by ;[ action comment, this string is
;;		mapped to form a valid file name (see documentation for
;;		`ebnf-eps-buffer' or `ebnf-eps-region').
;;		It has effect only during `ebnf-eps-buffer' or
;;		`ebnf-eps-region' execution.
;;		It's an error to try to open an already opened EPS file.
;;
;;    ;]EPS	close an opened EPS file.
;;		It has effect only during `ebnf-eps-buffer' or
;;		`ebnf-eps-region' execution.
;;		It's an error to try to close a not opened EPS file.
;;
;; So if you have:
;;
;;    (setq ebnf-horizontal-orientation nil)
;;
;;    A = t.
;;    C = x.
;;    ;> C and B are drawn in the same line
;;    B = y.
;;    W = v.
;;
;; The graphical result is:
;;
;;    +---+
;;    | A |
;;    +---+
;;
;;    +---------+   +-----+
;;    |         |   |     |
;;    |    C    |   |     |
;;    |         |   |  B  |
;;    +---------+   |     |
;;                  |     |
;;                  +-----+
;;
;;    +-----------+
;;    |     W     |
;;    +-----------+
;;
;; Note that if ascending production sort is used, the productions A and B will
;; be drawn in the same line instead of C and B.
;;
;; If consecutive actions occur, only the last one takes effect, so if you
;; have:
;;
;;    A = X.
;;    ;<
;;    ^L
;;    ;>
;;    B = Y.
;;
;; Only the ;> will take effect, that is, A and B will be drawn in the same
;; line.
;;
;; In ISO EBNF the above actions are specified as (*>*), (*<*), (*[EPS*) and
;; (*]EPS*).  The first example above should be written:
;;
;;    A = t;
;;    C = x;
;;    (*> C and B are drawn in the same line *)
;;    B = y;
;;    W = v;
;;
;; For an example of EPS action when executing `ebnf-eps-buffer' or
;; `ebnf-eps-region':
;;
;;    Z = B0.
;;    ;[CC
;;    ;[AA
;;    A = B1.
;;    ;[BB
;;    C = B2.
;;    ;]AA
;;    B = B3.
;;    ;]BB
;;    ;]CC
;;    D = B4.
;;    E = B5.
;;    ;[CC
;;    F = B6.
;;    ;]CC
;;    G = B7.
;;
;; The following table summarizes the results:
;;
;; EPS FILE NAME    NO SORT    ASCENDING SORT    DESCENDING SORT
;; ebnf--AA.eps     A C        A C               C A
;; ebnf--BB.eps     C B        B C               C B
;; ebnf--CC.eps     A C B F    A B C F           F C B A
;; ebnf--D.eps      D          D                 D
;; ebnf--E.eps      E          E                 E
;; ebnf--G.eps      G          G                 G
;; ebnf--Z.eps      Z          Z                 Z
;;
;; As you can see if EPS actions is not used, each single production is
;; generated per EPS file.  To avoid overriding EPS files, use names in ;[ that
;; it's not an existing production name.
;;
;; In the following case:
;;
;;    A = B0.
;;    ;[AA
;;    A = B1.
;;    ;[BB
;;    A = B2.
;;
;; The production A is generated in both files ebnf--AA.eps and ebnf--BB.eps.
;;
;;
;; Utilities
;; ---------
;;
;; Some tools are provided to help you.
;;
;; `ebnf-setup' returns the current setup.
;;
;; `ebnf-syntax-buffer' does a syntatic analysis of your EBNF in the current
;; buffer.
;;
;; `ebnf-syntax-region' does a syntatic analysis of your EBNF in the current
;; region.
;;
;; `ebnf-customize' activates a customization buffer for ebnf2ps options.
;;
;; `ebnf-syntax-buffer', `ebnf-syntax-region' and `ebnf-customize' can be bound
;; to keys in the same way as `ebnf-' commands.
;;
;;
;; Hooks
;; -----
;;
;; ebn2ps has the following hook variables:
;;
;; `ebnf-hook'
;;    It is evaluated once before any ebnf2ps process.
;;
;; `ebnf-production-hook'
;;    It is evaluated on each beginning of production.
;;
;; `ebnf-page-hook'
;;    It is evaluated on each beginning of page.
;;
;;
;; Options
;; -------
;;
;; Below it's shown a brief description of ebnf2ps options, please, see the
;; options declaration in the code for a long documentation.
;;
;; `ebnf-horizontal-orientation'	Non-nil means productions are drawn
;;					horizontally.
;;
;; `ebnf-horizontal-max-height'		Non-nil means to use maximum production
;;					height in horizontal orientation.
;;
;; `ebnf-production-horizontal-space'	Specify horizontal space in points
;;					between productions.
;;
;; `ebnf-production-vertical-space'	Specify vertical space in points
;;					between productions.
;;
;; `ebnf-justify-sequence'		Specify justification of terms in a
;;					sequence inside alternatives.
;;
;; `ebnf-terminal-regexp'		Specify how it's a terminal name.
;;
;; `ebnf-case-fold-search'		Non-nil means ignore case on matching.
;;
;; `ebnf-terminal-font'			Specify terminal font.
;;
;; `ebnf-terminal-shape'		Specify terminal box shape.
;;
;; `ebnf-terminal-shadow'		Non-nil means terminal box will have a
;;					shadow.
;;
;; `ebnf-terminal-border-width'		Specify border width for terminal box.
;;
;; `ebnf-terminal-border-color'		Specify border color for terminal box.
;;
;; `ebnf-sort-production'		Specify how productions are sorted.
;;
;; `ebnf-production-font'		Specify production font.
;;
;; `ebnf-non-terminal-font'		Specify non-terminal font.
;;
;; `ebnf-non-terminal-shape'		Specify non-terminal box shape.
;;
;; `ebnf-non-terminal-shadow'		Non-nil means non-terminal box will
;;					have a shadow.
;;
;; `ebnf-non-terminal-border-width'	Specify border width for non-terminal
;;					box.
;;
;; `ebnf-non-terminal-border-color'	Specify border color for non-terminal
;;					box.
;;
;; `ebnf-special-font'			Specify special font.
;;
;; `ebnf-special-shape'			Specify special box shape.
;;
;; `ebnf-special-shadow'		Non-nil means special box will have a
;;					shadow.
;;
;; `ebnf-special-border-width'		Specify border width for special box.
;;
;; `ebnf-special-border-color'		Specify border color for special box.
;;
;; `ebnf-except-font'			Specify except font.
;;
;; `ebnf-except-shape'			Specify except box shape.
;;
;; `ebnf-except-shadow'			Non-nil means except box will have a
;;					shadow.
;;
;; `ebnf-except-border-width'		Specify border width for except box.
;;
;; `ebnf-except-border-color'		Specify border color for except box.
;;
;; `ebnf-repeat-font'			Specify repeat font.
;;
;; `ebnf-repeat-shape'			Specify repeat box shape.
;;
;; `ebnf-repeat-shadow'			Non-nil means repeat box will have a
;;					shadow.
;;
;; `ebnf-repeat-border-width'		Specify border width for repeat box.
;;
;; `ebnf-repeat-border-color'		Specify border color for repeat box.
;;
;; `ebnf-entry-percentage'		Specify entry height on alternatives.
;;
;; `ebnf-arrow-shape'			Specify the arrow shape.
;;
;; `ebnf-chart-shape'			Specify chart flow shape.
;;
;; `ebnf-color-p'			Non-nil means use color.
;;
;; `ebnf-line-width'			Specify flow line width.
;;
;; `ebnf-line-color'			Specify flow line color.
;;
;; `ebnf-user-arrow'			Specify a user arrow shape (a
;;					PostScript code).
;;
;; `ebnf-debug-ps'			Non-nil means to generate PostScript
;;					debug procedures.
;;
;; `ebnf-lex-comment-char'		Specify the line comment character.
;;
;; `ebnf-lex-eop-char'			Specify the end of production
;;					character.
;;
;; `ebnf-syntax'			Specify syntax to be recognized.
;;
;; `ebnf-iso-alternative-p'		Non-nil means use alternative ISO EBNF.
;;
;; `ebnf-iso-normalize-p'		Non-nil means normalize ISO EBNF syntax
;;					names.
;;
;; `ebnf-default-width'			Specify additional border width over
;;					default terminal, non-terminal or
;;					special.
;;
;; `ebnf-eps-prefix'			Specify EPS prefix file name.
;;
;; `ebnf-use-float-format'		Non-nil means use `%f' float format.
;;
;; `ebnf-yac-ignore-error-recovery'	Non-nil means ignore error recovery.
;;
;; `ebnf-ignore-empty-rule'		Non-nil means ignore empty rules.
;;
;; `ebnf-optimize'			Non-nil means optimize syntatic chart
;;					of rules.
;;
;; To set the above options you may:
;;
;; a) insert the code in your ~/.emacs, like:
;;
;;	 (setq ebnf-terminal-shape 'bevel)
;;
;;    This way always keep your default settings when you enter a new Emacs
;;    session.
;;
;; b) or use `set-variable' in your Emacs session, like:
;;
;;	 M-x set-variable RET ebnf-terminal-shape RET bevel RET
;;
;;    This way keep your settings only during the current Emacs session.
;;
;; c) or use customization, for example:
;;	 click on menu-bar *Help* option,
;;	 then click on *Customize*,
;;	 then click on *Browse Customization Groups*,
;;	 expand *PostScript* group,
;;	 expand *Ebnf2ps* group
;;	 and then customize ebnf2ps options.
;;    Through this way, you may choose if the settings are kept or not when
;;    you leave out the current Emacs session.
;;
;; d) or see the option value:
;;
;;	 C-h v ebnf-terminal-shape RET
;;
;;    and click the *customize* hypertext button.
;;    Through this way, you may choose if the settings are kept or not when
;;    you leave out the current Emacs session.
;;
;; e) or invoke:
;;
;;	 M-x ebnf-customize RET
;;
;;    and then customize ebnf2ps options.
;;    Through this way, you may choose if the settings are kept or not when
;;    you leave out the current Emacs session.
;;
;;
;; Styles
;; ------
;;
;; Sometimes you need to change the EBNF style you are using, for example,
;; change the shapes and colors.  These changes may force you to set some
;; variables and after use, set back the variables to the old values.
;;
;; To help to handle this situation, ebnf2ps has the following commands to
;; handle styles:
;;
;; `ebnf-insert-style'	Insert a new style NAME with inheritance INHERITS and
;;			values VALUES.
;;
;; `ebnf-merge-style'	Merge values of style NAME with style VALUES.
;;
;; `ebnf-apply-style'	Set STYLE to current style.
;;
;; `ebnf-reset-style'	Reset current style.
;;
;; `ebnf-push-style'	Push the current style and set STYLE to current style.
;;
;; `ebnf-pop-style'	Pop a style and set it to current style.
;;
;; These commands helps to put together a lot of variable settings in a group
;; and name this group.  So when you wish to apply these settings it's only
;; needed to give the name.
;;
;; There is also a notion of simple inheritance of style; so if you declare
;; that a style A inherits from a style B, all settings of B is applied first
;; and then the settings of A is applied.  This is useful when you wish to
;; modify some aspects of an existing style, but at same time wish to keep it
;; unmodified.
;;
;; See documentation for `ebnf-style-database'.
;;
;;
;; Layout
;; ------
;;
;; Below it is the layout of minimum area to draw each element, and it's used
;; the following terms:
;;
;;    font height	is given by:
;;			(terminal font height + non-terminal font height) / 2
;;
;;    entry		is the vertical position used to know where it should
;;			be drawn the flow line in the current element.
;;
;;
;;    * SPECIAL, TERMINAL and NON-TERMINAL
;;
;;           +==============+...................................
;;           |              |      } font height / 2  } entry  }
;;           |   XXXXXXXX...|.......                  }        }
;;       ====+   XXXXXXXX   +====  } text height ......        } height
;;       :   |   XXXXXXXX...|...:...                           }
;;       :   |   :      :   |   :  } font height / 2           }
;;       :   +==============+...:...............................
;;       :   :   :      :   :   :
;;       :   :   :      :   :   :......................
;;       :   :   :      :   :      } font height      }
;;       :   :   :      :   :.......                  }
;;       :   :   :      :          } font height / 2  }
;;       :   :   :      :...........                  }
;;       :   :   :                 } text width       } width
;;       :   :   :..................                  }
;;       :   :                     } font height / 2  }
;;       :   :......................                  }
;;       :                         } font height      }
;;       :.............................................
;;
;;
;;    * OPTIONAL
;;
;;              +==========+.....................................
;;              |          |         }        }                 }
;;              |          |         } entry  }                 }
;;              |          |         }        }                 }
;;       ===+===+          +===+===...        } element height  } height
;;       :   \  |          |  /   :           }                 }
;;       :    + |          | +    :           }                 }
;;       :    | +==========+.|.................                 }
;;       :    | :          : |    :           } font height     }
;;       :    +==============+...................................
;;       :      :          :      :
;;       :      :          :      :......................
;;       :      :          :         } font height * 2  }
;;       :      :          :..........                  }
;;       :      :                    } element width    } width
;;       :      :.....................                  }
;;       :                           } font height * 2  }
;;       :...............................................
;;
;;
;;    * ALTERNATIVE
;;
;;               +===+...................................
;;            +==+ A +==+       } A height     }        }
;;            |  +===+..|........              } entry  }
;;            +         +       } font height  }        }
;;           /   +===+...\.......              }        }
;;       ===+====+ B +====+===  } B height .....        } height
;;       :   \   +===+.../.......                       }
;;       :    +         +    :  } font height           }
;;       :    |  +===+..|........                       }
;;       :    +==+ C +==+    :  } C height              }
;;       :     : +===+...................................
;;       :     :       :     :
;;       :     :       :     :......................
;;       :     :       :        } font height * 2  }
;;       :     :       :.........                  }
;;       :     :                } max width        } width
;;       :     :.................                  }
;;       :                      } font height * 2  }
;;       :..........................................
;;
;;       NOTES:
;;          1. An empty alternative has zero of height.
;;
;;          2. The variable `ebnf-entry-percentage' is used to determine the
;;             entry point.
;;
;;
;;    * ZERO OR MORE
;;
;;               +===========+...............................
;;             +=+ separator +=+        } separator height  }
;;            /  +===========+..\........                   }
;;           +                   +      }                   }
;;           |                   |      } font height       }
;;           +                   +      }                   }
;;            \  +===========+../........                   } height = entry
;;             +=+ element   +=+        } element height    }
;;            /: +===========+..\........                   }
;;           + :               : +      }                   }
;;           + :               : +      } font height       }
;;          /  :               :  \     }                   }
;;       ==+=======================+==.......................
;;       :     :               :     :
;;       :     :               :     :.......................
;;       :     :               :        } font height * 2   }
;;       :     :               :.........                   }
;;       :     :                        } max width         } width
;;       :     :.........................                   }
;;       :                              } font height * 2   }
;;       :...................................................
;;
;;
;;    * ONE OR MORE
;;
;;            +===========+......................................
;;          +=+ separator +=+      } separator height  }        }
;;         /  +===========+..\......                   }        }
;;        +                   +    }                   } entry  }
;;        |                   |    } font height       }        } height
;;        +                   +    }                   }        }
;;         \  +===========+../......                   }        }
;;       ===+=+ element   +=+===   } element height ....        }
;;       :  : +===========+......................................
;;       :  :               :  :
;;       :  :               :  :........................
;;       :  :               :      } font height * 2   }
;;       :  :               :.......                   }
;;       :  :                      } max width         } width
;;       :  :.......................                   }
;;       :                         } font height * 2   }
;;       :..............................................
;;
;;
;;    * PRODUCTION
;;
;;       XXXXXX:......................................
;;       XXXXXX:           } production font height  }
;;       XXXXXX:............                         }
;;                         } font height             }
;;           +======+.......                         } height = entry
;;           |      |      }                         }
;;       ====+      +====  } element height          }
;;       :   |      |   :  }                         }
;;       :   +======+.................................
;;       :   :      :   :
;;       :   :      :   :......................
;;       :   :      :      } font height * 2  }
;;       :   :      :.......                  }
;;       :   :             } element width    } width
;;       :   :..............                  }
;;       :                 } font height * 2  }
;;       :.....................................
;;
;;
;;    * REPEAT
;;
;;           +================+...................................
;;           |                |      } font height / 2  } entry  }
;;           |        +===+...|.......                  }        }
;;       ====+  N *   | X |   +====  } X height .........        } height
;;       :   |  :  :  +===+...|...:...                           }
;;       :   |  :  :  :   :   |   :  } font height / 2           }
;;       :   +================+...:...............................
;;       :   :  :  :  :   :   :   :
;;       :   :  :  :  :   :   :   :......................
;;       :   :  :  :  :   :   :      } font height      }
;;       :   :  :  :  :   :   :.......                  }
;;       :   :  :  :  :   :          } font height / 2  }
;;       :   :  :  :  :   :...........                  }
;;       :   :  :  :  :              } X width          }
;;       :   :  :  :  :...............                  }
;;       :   :  :  :                 } font height / 2  } width
;;       :   :  :  :..................                  }
;;       :   :  :                    } text width       }
;;       :   :  :.....................                  }
;;       :   :                       } font height / 2  }
;;       :   :........................                  }
;;       :                           } font height      }
;;       :...............................................
;;
;;
;;    * EXCEPT
;;
;;           +==================+...................................
;;           |                  |      } font height / 2  } entry  }
;;           |  +===+   +===+...|.......                  }        }
;;       ====+  | X | - | y |   +====  } max height .......        } height
;;       :   |  +===+   +===+...|...:...                           }
;;       :   |  :   :   :   :   |   :  } font height / 2           }
;;       :   +==================+...:...............................
;;       :   :  :   :   :   :   :   :
;;       :   :  :   :   :   :   :   :......................
;;       :   :  :   :   :   :   :      } font height      }
;;       :   :  :   :   :   :   :.......                  }
;;       :   :  :   :   :   :          } font height / 2  }
;;       :   :  :   :   :   :...........                  }
;;       :   :  :   :   :              } Y width          }
;;       :   :  :   :   :...............                  }
;;       :   :  :   :                  } font height      } width
;;       :   :  :   :...................                  }
;;       :   :  :                      } X width          }
;;       :   :  :.......................                  }
;;       :   :                         } font height / 2  }
;;       :   :..........................                  }
;;       :                             } font height      }
;;       :.................................................
;;
;;       NOTE: If Y element is empty, it's draw nothing at Y place.
;;
;;
;; Internal Structures
;; -------------------
;;
;; ebnf2ps has two passes.  The first pass does a lexical and syntatic analysis
;; of current buffer and generates an intermediate representation.  The second
;; pass uses the intermediate representation to generate the PostScript
;; syntatic chart.
;;
;; The intermediate representation is a list of vectors, the vector element
;; represents a syntatic chart element.  Below is a vector representation for
;; each syntatic chart element.
;;
;; [production   WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH NAME   PRODUCTION ACTION]
;; [alternative  WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH LIST]
;; [sequence     WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH LIST]
;; [terminal     WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH NAME    DEFAULT]
;; [non-terminal WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH NAME    DEFAULT]
;; [special      WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH NAME    DEFAULT]
;; [empty        WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH]
;; [optional     WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH ELEMENT]
;; [one-or-more  WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH ELEMENT SEPARATOR]
;; [zero-or-more WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH ELEMENT SEPARATOR]
;; [repeat       WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH TIMES   ELEMENT]
;; [except       WIDTH-FUN DIM-FUN ENTRY HEIGHT WIDTH ELEMENT ELEMENT]
;;
;; The first vector position is a function symbol used to generate PostScript
;; for this element.
;; WIDTH-FUN is a function symbol called to adjust the element width.
;; DIM-FUN is a function symbol called to set the element dimensions.
;; ENTRY is the element entry point.
;; HEIGHT and WIDTH are the element height and width, respectively.
;; NAME is a string that it's the element name.
;; DEFAULT is a boolean that indicates if it's a `default' element.
;; PRODUCTION and ELEMENT are vectors that represents sub-elements of current
;; one.
;; LIST is a list of vector that represents the list part for alternatives and
;; sequences.
;; SEPARATOR is a vector that represents the sub-element used to separate the
;; list elements.
;; TIMES is a string representing the number of times that ELEMENT is repeated
;; on a repeat construction.
;; ACTION indicates some action that should be done before production is
;; generated.  The current actions are:
;;
;;    nil		no action.
;;
;;    form-feed		current production starts on a new page.
;;
;;    newline		current production starts on next line, this is useful
;;			when `ebnf-horizontal-orientation' is non-nil.
;;
;;    keep-line		current production continues on the current line, this
;;			is useful when `ebnf-horizontal-orientation' is nil.
;;
;;
;; Things To Change
;; ----------------
;;
;; . Handle situations when syntatic chart is out of paper.
;; . Use other alphabet than ascii.
;; . Optimizations...
;;
;;
;; Acknowledgements
;; ----------------
;;
;; Thanks to all who emailed comments.
;;
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; code:


(require 'ps-print)

(and (string< ps-print-version "5.2.3")
     (error "`ebnf2ps' requires `ps-print' package version 5.2.3 or later"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User Variables:


;;; Interface to the command system

(defgroup postscript nil
  "PostScript Group"
  :tag "PostScript"
  :group 'emacs)


(defgroup ebnf2ps nil
  "Translate an EBNF to a syntatic chart on PostScript"
  :prefix "ebnf-"
  :group 'wp
  :group 'postscript)


(defgroup ebnf-special nil
  "Special customization"
  :prefix "ebnf-"
  :tag "Special"
  :group 'ebnf2ps)


(defgroup ebnf-except nil
  "Except customization"
  :prefix "ebnf-"
  :tag "Except"
  :group 'ebnf2ps)


(defgroup ebnf-repeat nil
  "Repeat customization"
  :prefix "ebnf-"
  :tag "Repeat"
  :group 'ebnf2ps)


(defgroup ebnf-terminal nil
  "Terminal customization"
  :prefix "ebnf-"
  :tag "Terminal"
  :group 'ebnf2ps)


(defgroup ebnf-non-terminal nil
  "Non-Terminal customization"
  :prefix "ebnf-"
  :tag "Non-Terminal"
  :group 'ebnf2ps)


(defgroup ebnf-production nil
  "Production customization"
  :prefix "ebnf-"
  :tag "Production"
  :group 'ebnf2ps)


(defgroup ebnf-shape nil
  "Shapes customization"
  :prefix "ebnf-"
  :tag "Shape"
  :group 'ebnf2ps)


(defgroup ebnf-displacement nil
  "Displacement customization"
  :prefix "ebnf-"
  :tag "Displacement"
  :group 'ebnf2ps)


(defgroup ebnf-syntatic nil
  "Syntatic customization"
  :prefix "ebnf-"
  :tag "Syntatic"
  :group 'ebnf2ps)


(defgroup ebnf-optimization nil
  "Optimization customization"
  :prefix "ebnf-"
  :tag "Optimization"
  :group 'ebnf2ps)


(defcustom ebnf-horizontal-orientation nil
  "*Non-nil means productions are drawn horizontally."
  :type 'boolean
  :group 'ebnf-displacement)


(defcustom ebnf-horizontal-max-height nil
  "*Non-nil means to use maximum production height in horizontal orientation.

It is only used when `ebnf-horizontal-orientation' is non-nil."
  :type 'boolean
  :group 'ebnf-displacement)


(defcustom ebnf-production-horizontal-space 0.0 ; use ebnf2ps default value
  "*Specify horizontal space in points between productions.

Value less or equal to zero forces ebnf2ps to set a proper default value."
  :type 'number
  :group 'ebnf-displacement)


(defcustom ebnf-production-vertical-space 0.0 ; use ebnf2ps default value
  "*Specify vertical space in points between productions.

Value less or equal to zero forces ebnf2ps to set a proper default value."
  :type 'number
  :group 'ebnf-displacement)


(defcustom ebnf-justify-sequence 'center
  "*Specify justification of terms in a sequence inside alternatives.

Valid values are:

   `left'		left justification
   `right'		right justification
   any other value	centralize"
  :type '(radio :tag "Sequence Justification"
		(const left) (const right) (other :tag "center" center))
  :group 'ebnf-displacement)


(defcustom ebnf-special-font '(7 Courier "Black" "Gray95" bold italic)
  "*Specify special font.

See documentation for `ebnf-production-font'."
  :type '(list :tag "Special Font"
	       (number :tag "Font Size")
	       (symbol :tag "Font Name")
	       (choice :tag "Foreground Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (choice :tag "Background Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (repeat :tag "Font Attributes" :inline t
		       (choice (const bold)      (const italic)
			       (const underline) (const strikeout)
			       (const overline)  (const shadow)
			       (const box)       (const outline))))
  :group 'ebnf-special)


(defcustom ebnf-special-shape 'bevel
  "*Specify special box shape.

See documentation for `ebnf-non-terminal-shape'."
  :type '(radio :tag "Special Shape"
		(const miter) (const round) (const bevel))
  :group 'ebnf-special)


(defcustom ebnf-special-shadow nil
  "*Non-nil means special box will have a shadow."
  :type 'boolean
  :group 'ebnf-special)


(defcustom ebnf-special-border-width 0.5
  "*Specify border width for special box."
  :type 'number
  :group 'ebnf-special)


(defcustom ebnf-special-border-color "Black"
  "*Specify border color for special box."
  :type 'string
  :group 'ebnf-special)


(defcustom ebnf-except-font '(7 Courier "Black" "Gray90" bold italic)
  "*Specify except font.

See documentation for `ebnf-production-font'."
  :type '(list :tag "Except Font"
	       (number :tag "Font Size")
	       (symbol :tag "Font Name")
	       (choice :tag "Foreground Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (choice :tag "Background Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (repeat :tag "Font Attributes" :inline t
		       (choice (const bold)      (const italic)
			       (const underline) (const strikeout)
			       (const overline)  (const shadow)
			       (const box)       (const outline))))
  :group 'ebnf-except)


(defcustom ebnf-except-shape 'bevel
  "*Specify except box shape.

See documentation for `ebnf-non-terminal-shape'."
  :type '(radio :tag "Except Shape"
		(const miter) (const round) (const bevel))
  :group 'ebnf-except)


(defcustom ebnf-except-shadow nil
  "*Non-nil means except box will have a shadow."
  :type 'boolean
  :group 'ebnf-except)


(defcustom ebnf-except-border-width 0.25
  "*Specify border width for except box."
  :type 'number
  :group 'ebnf-except)


(defcustom ebnf-except-border-color "Black"
  "*Specify border color for except box."
  :type 'string
  :group 'ebnf-except)


(defcustom ebnf-repeat-font '(7 Courier "Black" "Gray85" bold italic)
  "*Specify repeat font.

See documentation for `ebnf-production-font'."
  :type '(list :tag "Repeat Font"
	       (number :tag "Font Size")
	       (symbol :tag "Font Name")
	       (choice :tag "Foreground Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (choice :tag "Background Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (repeat :tag "Font Attributes" :inline t
		       (choice (const bold)      (const italic)
			       (const underline) (const strikeout)
			       (const overline)  (const shadow)
			       (const box)       (const outline))))
  :group 'ebnf-repeat)


(defcustom ebnf-repeat-shape 'bevel
  "*Specify repeat box shape.

See documentation for `ebnf-non-terminal-shape'."
  :type '(radio :tag "Repeat Shape"
		(const miter) (const round) (const bevel))
  :group 'ebnf-repeat)


(defcustom ebnf-repeat-shadow nil
  "*Non-nil means repeat box will have a shadow."
  :type 'boolean
  :group 'ebnf-repeat)


(defcustom ebnf-repeat-border-width 0.0
  "*Specify border width for repeat box."
  :type 'number
  :group 'ebnf-repeat)


(defcustom ebnf-repeat-border-color "Black"
  "*Specify border color for repeat box."
  :type 'string
  :group 'ebnf-repeat)


(defcustom ebnf-terminal-font '(7 Courier "Black" "White")
  "*Specify terminal font.

See documentation for `ebnf-production-font'."
  :type '(list :tag "Terminal Font"
	       (number :tag "Font Size")
	       (symbol :tag "Font Name")
	       (choice :tag "Foreground Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (choice :tag "Background Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (repeat :tag "Font Attributes" :inline t
		       (choice (const bold)      (const italic)
			       (const underline) (const strikeout)
			       (const overline)  (const shadow)
			       (const box)       (const outline))))
  :group 'ebnf-terminal)


(defcustom ebnf-terminal-shape 'miter
  "*Specify terminal box shape.

See documentation for `ebnf-non-terminal-shape'."
  :type '(radio :tag "Terminal Shape"
		(const miter) (const round) (const bevel))
  :group 'ebnf-terminal)


(defcustom ebnf-terminal-shadow nil
  "*Non-nil means terminal box will have a shadow."
  :type 'boolean
  :group 'ebnf-terminal)


(defcustom ebnf-terminal-border-width 1.0
  "*Specify border width for terminal box."
  :type 'number
  :group 'ebnf-terminal)


(defcustom ebnf-terminal-border-color "Black"
  "*Specify border color for terminal box."
  :type 'string
  :group 'ebnf-terminal)


(defcustom ebnf-sort-production nil
  "*Specify how productions are sorted.

Valid values are:

   nil			don't sort productions.
   `ascending'		ascending sort.
   any other value	descending sort."
  :type '(radio :tag "Production Sort"
		(const :tag "Ascending" ascending)
		(const :tag "Descending" descending)
		(other :tag "No Sort" nil))
  :group 'ebnf-production)


(defcustom ebnf-production-font '(10 Helvetica "Black" "White" bold)
  "*Specify production header font.

It is a list with the following form:

   (SIZE NAME FOREGROUND BACKGROUND ATTRIBUTE...)

Where:
SIZE is the font size.
NAME is the font name symbol.
ATTRIBUTE is one of the following symbols:
   bold      - use bold font.
   italic    - use italic font.
   underline - put a line under text.
   strikeout - like underline, but the line is in middle of text.
   overline  - like underline, but the line is over the text.
   shadow    - text will have a shadow.
   box       - text will be surrounded by a box.
   outline   - print characters as hollow outlines.
FOREGROUND is a foreground string color name; if it's nil, the default color is
\"Black\".
BACKGROUND is a background string color name; if it's nil, the default color is
\"White\".

See `ps-font-info-database' for valid font name."
  :type '(list :tag "Production Font"
	       (number :tag "Font Size")
	       (symbol :tag "Font Name")
	       (choice :tag "Foreground Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (choice :tag "Background Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (repeat :tag "Font Attributes" :inline t
		       (choice (const bold)      (const italic)
			       (const underline) (const strikeout)
			       (const overline)  (const shadow)
			       (const box)       (const outline))))
  :group 'ebnf-production)


(defcustom ebnf-non-terminal-font '(7 Helvetica "Black" "White")
  "*Specify non-terminal font.

See documentation for `ebnf-production-font'."
  :type '(list :tag "Non-Terminal Font"
	       (number :tag "Font Size")
	       (symbol :tag "Font Name")
	       (choice :tag "Foreground Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (choice :tag "Background Color"
		       (string :tag "Name")
		       (other :tag "Default" nil))
	       (repeat :tag "Font Attributes" :inline t
		       (choice (const bold)      (const italic)
			       (const underline) (const strikeout)
			       (const overline)  (const shadow)
			       (const box)       (const outline))))
  :group 'ebnf-non-terminal)


(defcustom ebnf-non-terminal-shape 'round
  "*Specify non-terminal box shape.

Valid values are:

   `miter'	+-------+
		|       |
		+-------+

   `round'	 -------
		(       )
		 -------

   `bevel'	/-------\\
		|       |
		\\-------/

Any other value is treated as `miter'."
  :type '(radio :tag "Non-Terminal Shape"
		(const miter) (const round) (const bevel))
  :group 'ebnf-non-terminal)


(defcustom ebnf-non-terminal-shadow nil
  "*Non-nil means non-terminal box will have a shadow."
  :type 'boolean
  :group 'ebnf-non-terminal)


(defcustom ebnf-non-terminal-border-width 1.0
  "*Specify border width for non-terminal box."
  :type 'number
  :group 'ebnf-non-terminal)


(defcustom ebnf-non-terminal-border-color "Black"
  "*Specify border color for non-terminal box."
  :type 'string
  :group 'ebnf-non-terminal)


(defcustom ebnf-arrow-shape 'hollow
  "*Specify the arrow shape.

Valid values are:

   `none'	======

   `semi-up'	   *		   `transparent'  *
		    *				  |*
		=====*				  | *
						==+==*
						  | *
						  |*
						  *

   `semi-down'	=====*		   `hollow'	  *
		    *				  |*
		   *				  | *
						==+  *
						  | *
						  |*
						  *

   `simple'	   *		   `full'	  *
		    *				  |*
		=====*				  |X*
		    *				==+XX*
		   *				  |X*
						  |*
						  *

   `user'	See also documentation for variable `ebnf-user-arrow'.

Any other value is treated as `none'."
  :type '(radio :tag "Arrow Shape"
		(const none)        (const semi-up)
		(const semi-down)   (const simple)
		(const transparent) (const hollow)
		(const full)        (const user))
  :group 'ebnf-shape)


(defcustom ebnf-chart-shape 'round
  "*Specify chart flow shape.

See documentation for `ebnf-non-terminal-shape'."
  :type '(radio :tag "Chart Flow Shape"
		(const miter) (const round) (const bevel))
  :group 'ebnf-shape)


(defcustom ebnf-user-arrow nil
  "*Specify a user arrow shape (a PostScript code).

PostScript code should draw a right arrow.

The anatomy of a right arrow is:

   ...... Initial position
   :
   :     *.................
   :     | *       }      }
   :     |   *     } hT4  }
   v     |     *   }      }
   ======+======*...      } hT2
   :     |     *:  }      }
   :     |   *  :  } hT4  }
   :     | *    :  }      }
   :     *.................
   :     :      :
   :     :      :..........
   :     :         } hT2  }
   :     :..........      } hT
   :               } hT2  }
   :.......................

Where `hT', `hT2' and `hT4' are predefined PostScript variable names that can
be used to generate your own arrow.  As these variables are used along
PostScript execution, *DON'T* modify the values of them.  Instead, copy the
values, if you need to modify them.

The relation between these variables is: hT = 2 * hT2 = 4 * hT4.

The variable `ebnf-user-arrow' is only used when `ebnf-arrow-shape' is set to
symbol `user'.

See function `ebnf-user-arrow' for valid values and how values are processed."
  :type '(radio :tag "User Arrow Shape"
		(const nil)
		string
		symbol
		(repeat :tag "List"
			(radio string
			       symbol
			       sexp)))
  :group 'ebnf-shape)


(defcustom ebnf-syntax 'ebnf
  "*Specify syntax to be recognized.

Valid values are:

   `ebnf'	ebnf2ps recognizes the syntax described in ebnf2ps
		documentation.
		The following variables *ONLY* have effect with this
		setting:
		`ebnf-terminal-regexp', `ebnf-case-fold-search',
		`ebnf-lex-comment-char' and `ebnf-lex-eop-char'.

   `iso-ebnf'	ebnf2ps recognizes the syntax described in the URL:
		`http://www.cl.cam.ac.uk/~mgk25/iso-ebnf.html'
		(\"International Standard of the ISO EBNF Notation\").
		The following variables *ONLY* have effect with this
		setting:
		`ebnf-iso-alternative-p' and `ebnf-iso-normalize-p'.

   `yacc'	ebnf2ps recognizes the Yacc/Bison syntax.
		The following variable *ONLY* has effect with this
		setting:
		`ebnf-yac-ignore-error-recovery'.

Any other value is treated as `ebnf'."
  :type '(radio :tag "Syntax"
		(const ebnf) (const iso-ebnf) (const yacc))
  :group 'ebnf-syntatic)


(defcustom ebnf-lex-comment-char ?\;
  "*Specify the line comment character.

It's used only when `ebnf-syntax' is `ebnf'."
  :type 'character
  :group 'ebnf-syntatic)


(defcustom ebnf-lex-eop-char ?.
  "*Specify the end of production character.

It's used only when `ebnf-syntax' is `ebnf'."
  :type 'character
  :group 'ebnf-syntatic)


(defcustom ebnf-terminal-regexp nil
  "*Specify how it's a terminal name.

If it's nil, the terminal name must be enclosed by `\"'.
If it's a string, it should be a regexp that it'll be used to determine a
terminal name; terminal name may also be enclosed by `\"'.

It's used only when `ebnf-syntax' is `ebnf'."
  :type '(radio :tag "Terminal Name"
		(const nil) regexp)
  :group 'ebnf-syntatic)


(defcustom ebnf-case-fold-search nil
  "*Non-nil means ignore case on matching.

It's only used when `ebnf-terminal-regexp' is non-nil and when `ebnf-syntax' is
`ebnf'."
  :type 'boolean
  :group 'ebnf-syntatic)


(defcustom ebnf-iso-alternative-p nil
  "*Non-nil means use alternative ISO EBNF.

It's only used when `ebnf-syntax' is `iso-ebnf'.

This variable affects the following symbol set:

   STANDARD   ALTERNATIVE
      |    ==>   / or !
      [    ==>   (/
      ]    ==>   /)
      {    ==>   (:
      }    ==>   :)
      ;    ==>   ."
  :type 'boolean
  :group 'ebnf-syntatic)


(defcustom ebnf-iso-normalize-p nil
  "*Non-nil means normalize ISO EBNF syntax names.

Normalize a name means that several contiguous spaces inside name become a
single space, so \"A  B   C\" is normalized to  \"A B C\".

It's only used when `ebnf-syntax' is `iso-ebnf'."
  :type 'boolean
  :group 'ebnf-syntatic)


(defcustom ebnf-eps-prefix "ebnf--"
  "*Specify EPS prefix file name.

See `ebnf-eps-buffer' and `ebnf-eps-region' commands."
  :type 'string
  :group 'ebnf2ps)


(defcustom ebnf-entry-percentage 0.5	; middle
  "*Specify entry height on alternatives.

It must be a float between 0.0 (top) and 1.0 (bottom)."
  :type 'number
  :group 'ebnf2ps)


(defcustom ebnf-default-width 0.6
  "*Specify additional border width over default terminal, non-terminal or
special."
  :type 'number
  :group 'ebnf2ps)


;; Printing color requires x-color-values.
(defcustom ebnf-color-p (or (fboundp 'x-color-values) ; Emacs
			    (fboundp 'color-instance-rgb-components)) ; XEmacs
  "*Non-nil means use color."
  :type 'boolean
  :group 'ebnf2ps)


(defcustom ebnf-line-width 1.0
  "*Specify flow line width."
  :type 'number
  :group 'ebnf2ps)


(defcustom ebnf-line-color "Black"
  "*Specify flow line color."
  :type 'string
  :group 'ebnf2ps)


(defcustom ebnf-debug-ps nil
  "*Non-nil means to generate PostScript debug procedures.

It is intended to help PostScript programmers in debugging."
  :type 'boolean
  :group 'ebnf2ps)


(defcustom ebnf-use-float-format t
  "*Non-nil means use `%f' float format.

The advantage of using float format is that ebnf2ps generates a little short
PostScript file.

If it occurs the error message:

   Invalid format operation %f

when executing ebnf2ps, set `ebnf-use-float-format' to nil."
  :type 'boolean
  :group 'ebnf2ps)


(defcustom ebnf-yac-ignore-error-recovery nil
  "*Non-nil means ignore error recovery.

It's only used when `ebnf-syntax' is `yacc'."
  :type 'boolean
  :group 'ebnf-syntatic)


(defcustom ebnf-ignore-empty-rule nil
  "*Non-nil means ignore empty rules.

It's interesting to set this variable if your Yacc/Bison grammar has a lot of
middle action rule."
  :type 'boolean
  :group 'ebnf-optimization)


(defcustom ebnf-optimize nil
  "*Non-nil means optimize syntatic chart of rules.

The following optimizations are done:

   left recursion:
   1.  A = B | A C.             ==>   A = B {C}*.
   2.  A = B | A B.             ==>   A = {B}+.
   3.  A =   | A B.             ==>   A = {B}*.
   4.  A = B | A C B.           ==>   A = {B || C}+.
   5.  A = B | D | A C | A E.   ==>   A = ( B | D ) { C | E }*.

   optional:
   6.  A = B | .                ==>   A = [B].
   7.  A =   | B .              ==>   A = [B].

   factoration:
   8.  A = B C | B D.           ==>   A = B (C | D).
   9.  A = C B | D B.           ==>   A = (C | D) B.
   10. A = B C E | B D E.       ==>   A = B (C | D) E.

The above optimizations are specially useful when `ebnf-syntax' is `yacc'."
  :type 'boolean
  :group 'ebnf-optimization)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customization


;;;###autoload
(defun ebnf-customize ()
  "Customization for ebnf group."
  (interactive)
  (customize-group 'ebnf2ps))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User commands


;;;###autoload
(defun ebnf-print-buffer (&optional filename)
  "Generate and print a PostScript syntatic chart image of the buffer.

When called with a numeric prefix argument (C-u), prompts the user for
the name of a file to save the PostScript image in, instead of sending
it to the printer.

More specifically, the FILENAME argument is treated as follows: if it
is nil, send the image to the printer.  If FILENAME is a string, save
the PostScript image in a file with that name.  If FILENAME is a
number, prompt the user for the name of the file to save in."
  (interactive (list (ps-print-preprint current-prefix-arg)))
  (ebnf-print-region (point-min) (point-max) filename))


;;;###autoload
(defun ebnf-print-region (from to &optional filename)
  "Generate and print a PostScript syntatic chart image of the region.
Like `ebnf-print-buffer', but prints just the current region."
  (interactive (list (point) (mark) (ps-print-preprint current-prefix-arg)))
  (run-hooks 'ebnf-hook)
  (or (ebnf-spool-region from to)
      (ps-do-despool filename)))


;;;###autoload
(defun ebnf-spool-buffer ()
  "Generate and spool a PostScript syntatic chart image of the buffer.
Like `ebnf-print-buffer' except that the PostScript image is saved in a
local buffer to be sent to the printer later.

Use the command `ebnf-despool' to send the spooled images to the printer."
  (interactive)
  (ebnf-spool-region (point-min) (point-max)))


;;;###autoload
(defun ebnf-spool-region (from to)
  "Generate a PostScript syntatic chart image of the region and spool locally.
Like `ebnf-spool-buffer', but spools just the current region.

Use the command `ebnf-despool' to send the spooled images to the printer."
  (interactive "r")
  (ebnf-generate-region from to 'ebnf-generate))


;;;###autoload
(defun ebnf-eps-buffer ()
  "Generate a PostScript syntatic chart image of the buffer in a EPS file.

Indeed, for each production is generated a EPS file.
The EPS file name has the following form:

   <PREFIX><PRODUCTION>.eps

<PREFIX>     is given by variable `ebnf-eps-prefix'.
	     The default value is \"ebnf--\".

<PRODUCTION> is the production name.
	     The production name is mapped to form a valid file name.
	     For example, the production name \"A/B + C\" is mapped to
	     \"A_B_+_C\" and the EPS file name used is \"ebnf--A_B_+_C.eps\".

WARNING: It's *NOT* asked any confirmation to override an existing file."
  (interactive)
  (ebnf-eps-region (point-min) (point-max)))


;;;###autoload
(defun ebnf-eps-region (from to)
  "Generate a PostScript syntatic chart image of the region in a EPS file.

Indeed, for each production is generated a EPS file.
The EPS file name has the following form:

   <PREFIX><PRODUCTION>.eps

<PREFIX>     is given by variable `ebnf-eps-prefix'.
	     The default value is \"ebnf--\".

<PRODUCTION> is the production name.
	     The production name is mapped to form a valid file name.
	     For example, the production name \"A/B + C\" is mapped to
	     \"A_B_+_C\" and the EPS file name used is \"ebnf--A_B_+_C.eps\".

WARNING: It's *NOT* asked any confirmation to override an existing file."
  (interactive "r")
  (let ((ebnf-eps-executing t))
    (ebnf-generate-region from to 'ebnf-generate-eps)))


;;;###autoload
(defalias 'ebnf-despool 'ps-despool)


;;;###autoload
(defun ebnf-syntax-buffer ()
  "Does a syntatic analysis of the current buffer."
  (interactive)
  (ebnf-syntax-region (point-min) (point-max)))


;;;###autoload
(defun ebnf-syntax-region (from to)
  "Does a syntatic analysis of a region."
  (interactive "r")
  (ebnf-generate-region from to nil))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utilities


;;;###autoload
(defun ebnf-setup ()
  "Return the current ebnf2ps setup."
  (format
   "
\(setq ebnf-special-font                %s
      ebnf-special-shape               %s
      ebnf-special-shadow              %S
      ebnf-special-border-width        %S
      ebnf-special-border-color        %S
      ebnf-except-font                 %s
      ebnf-except-shape                %s
      ebnf-except-shadow               %S
      ebnf-except-border-width         %S
      ebnf-except-border-color         %S
      ebnf-repeat-font                 %s
      ebnf-repeat-shape                %s
      ebnf-repeat-shadow               %S
      ebnf-repeat-border-width         %S
      ebnf-repeat-border-color         %S
      ebnf-terminal-regexp             %S
      ebnf-case-fold-search            %S
      ebnf-terminal-font               %s
      ebnf-terminal-shape              %s
      ebnf-terminal-shadow             %S
      ebnf-terminal-border-width       %S
      ebnf-terminal-border-color       %S
      ebnf-non-terminal-font           %s
      ebnf-non-terminal-shape          %s
      ebnf-non-terminal-shadow         %S
      ebnf-non-terminal-border-width   %S
      ebnf-non-terminal-border-color   %S
      ebnf-sort-production             %s
      ebnf-production-font             %s
      ebnf-arrow-shape                 %s
      ebnf-chart-shape                 %s
      ebnf-user-arrow                  %s
      ebnf-horizontal-orientation      %S
      ebnf-horizontal-max-height       %S
      ebnf-production-horizontal-space %S
      ebnf-production-vertical-space   %S
      ebnf-justify-sequence            %s
      ebnf-lex-comment-char            ?\\%03o
      ebnf-lex-eop-char                ?\\%03o
      ebnf-syntax                      %s
      ebnf-iso-alternative-p           %S
      ebnf-iso-normalize-p             %S
      ebnf-eps-prefix                  %S
      ebnf-entry-percentage            %S
      ebnf-color-p                     %S
      ebnf-line-width                  %S
      ebnf-line-color                  %S
      ebnf-debug-ps                    %S
      ebnf-use-float-format            %S
      ebnf-yac-ignore-error-recovery   %S
      ebnf-ignore-empty-rule           %S
      ebnf-optimize                    %S)
"
   (ps-print-quote ebnf-special-font)
   (ps-print-quote ebnf-special-shape)
   ebnf-special-shadow
   ebnf-special-border-width
   ebnf-special-border-color
   (ps-print-quote ebnf-except-font)
   (ps-print-quote ebnf-except-shape)
   ebnf-except-shadow
   ebnf-except-border-width
   ebnf-except-border-color
   (ps-print-quote ebnf-repeat-font)
   (ps-print-quote ebnf-repeat-shape)
   ebnf-repeat-shadow
   ebnf-repeat-border-width
   ebnf-repeat-border-color
   ebnf-terminal-regexp
   ebnf-case-fold-search
   (ps-print-quote ebnf-terminal-font)
   (ps-print-quote ebnf-terminal-shape)
   ebnf-terminal-shadow
   ebnf-terminal-border-width
   ebnf-terminal-border-color
   (ps-print-quote ebnf-non-terminal-font)
   (ps-print-quote ebnf-non-terminal-shape)
   ebnf-non-terminal-shadow
   ebnf-non-terminal-border-width
   ebnf-non-terminal-border-color
   (ps-print-quote ebnf-sort-production)
   (ps-print-quote ebnf-production-font)
   (ps-print-quote ebnf-arrow-shape)
   (ps-print-quote ebnf-chart-shape)
   (ps-print-quote ebnf-user-arrow)
   ebnf-horizontal-orientation
   ebnf-horizontal-max-height
   ebnf-production-horizontal-space
   ebnf-production-vertical-space
   (ps-print-quote ebnf-justify-sequence)
   ebnf-lex-comment-char
   ebnf-lex-eop-char
   (ps-print-quote ebnf-syntax)
   ebnf-iso-alternative-p
   ebnf-iso-normalize-p
   ebnf-eps-prefix
   ebnf-entry-percentage
   ebnf-color-p
   ebnf-line-width
   ebnf-line-color
   ebnf-debug-ps
   ebnf-use-float-format
   ebnf-yac-ignore-error-recovery
   ebnf-ignore-empty-rule
   ebnf-optimize))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Style variables


(defvar ebnf-stack-style nil
  "Used in functions `ebnf-reset-style', `ebnf-push-style' and
`ebnf-pop-style'.")


(defvar ebnf-current-style 'default
  "Used in functions `ebnf-apply-style' and `ebnf-push-style'.")


(defconst ebnf-style-custom-list
  '(ebnf-special-font
    ebnf-special-shape
    ebnf-special-shadow
    ebnf-special-border-width
    ebnf-special-border-color
    ebnf-except-font
    ebnf-except-shape
    ebnf-except-shadow
    ebnf-except-border-width
    ebnf-except-border-color
    ebnf-repeat-font
    ebnf-repeat-shape
    ebnf-repeat-shadow
    ebnf-repeat-border-width
    ebnf-repeat-border-color
    ebnf-terminal-regexp
    ebnf-case-fold-search
    ebnf-terminal-font
    ebnf-terminal-shape
    ebnf-terminal-shadow
    ebnf-terminal-border-width
    ebnf-terminal-border-color
    ebnf-non-terminal-font
    ebnf-non-terminal-shape
    ebnf-non-terminal-shadow
    ebnf-non-terminal-border-width
    ebnf-non-terminal-border-color
    ebnf-sort-production
    ebnf-production-font
    ebnf-arrow-shape
    ebnf-chart-shape
    ebnf-user-arrow
    ebnf-horizontal-orientation
    ebnf-horizontal-max-height
    ebnf-production-horizontal-space
    ebnf-production-vertical-space
    ebnf-justify-sequence
    ebnf-lex-comment-char
    ebnf-lex-eop-char
    ebnf-syntax
    ebnf-iso-alternative-p
    ebnf-iso-normalize-p
    ebnf-eps-prefix
    ebnf-entry-percentage
    ebnf-color-p
    ebnf-line-width
    ebnf-line-color
    ebnf-debug-ps
    ebnf-use-float-format
    ebnf-yac-ignore-error-recovery
    ebnf-ignore-empty-rule
    ebnf-optimize)
  "List of valid symbol custom variable.")


(defvar ebnf-style-database
  '(;; EBNF default
    (default
      nil
      (ebnf-special-font          . '(7 Courier "Black" "Gray95" bold italic))
      (ebnf-special-shape               . 'bevel)
      (ebnf-special-shadow              . nil)
      (ebnf-special-border-width        . 0.5)
      (ebnf-special-border-color        . "Black")
      (ebnf-except-font           . '(7 Courier "Black" "Gray90" bold italic))
      (ebnf-except-shape                . 'bevel)
      (ebnf-except-shadow               . nil)
      (ebnf-except-border-width         . 0.25)
      (ebnf-except-border-color         . "Black")
      (ebnf-repeat-font           . '(7 Courier "Black" "Gray85" bold italic))
      (ebnf-repeat-shape                . 'bevel)
      (ebnf-repeat-shadow               . nil)
      (ebnf-repeat-border-width         . 0.0)
      (ebnf-repeat-border-color         . "Black")
      (ebnf-terminal-regexp             . nil)
      (ebnf-case-fold-search            . nil)
      (ebnf-terminal-font               . '(7  Courier   "Black" "White"))
      (ebnf-terminal-shape              . 'miter)
      (ebnf-terminal-shadow             . nil)
      (ebnf-terminal-border-width       . 1.0)
      (ebnf-terminal-border-color       . "Black")
      (ebnf-non-terminal-font           . '(7  Helvetica "Black" "White"))
      (ebnf-non-terminal-shape          . 'round)
      (ebnf-non-terminal-shadow         . nil)
      (ebnf-non-terminal-border-width   . 1.0)
      (ebnf-non-terminal-border-color   . "Black")
      (ebnf-sort-production             . nil)
      (ebnf-production-font             . '(10 Helvetica "Black" "White" bold))
      (ebnf-arrow-shape                 . 'hollow)
      (ebnf-chart-shape                 . 'round)
      (ebnf-user-arrow                  . nil)
      (ebnf-horizontal-orientation      . nil)
      (ebnf-horizontal-max-height       . nil)
      (ebnf-production-horizontal-space . 0.0)
      (ebnf-production-vertical-space   . 0.0)
      (ebnf-justify-sequence            . 'center)
      (ebnf-lex-comment-char            . ?\;)
      (ebnf-lex-eop-char                . ?.)
      (ebnf-syntax                      . 'ebnf)
      (ebnf-iso-alternative-p           . nil)
      (ebnf-iso-normalize-p             . nil)
      (ebnf-eps-prefix                  . "ebnf--")
      (ebnf-entry-percentage            . 0.5)
      (ebnf-color-p   . (or (fboundp 'x-color-values) ; Emacs
			    (fboundp 'color-instance-rgb-components))) ; XEmacs
      (ebnf-line-width                  . 1.0)
      (ebnf-line-color                  . "Black")
      (ebnf-debug-ps                    . nil)
      (ebnf-use-float-format            . t)
      (ebnf-yac-ignore-error-recovery   . nil)
      (ebnf-ignore-empty-rule           . nil)
      (ebnf-optimize                    . nil))
    ;; Happy EBNF default
    (happy
     default
     (ebnf-justify-sequence            . 'left)
     (ebnf-lex-comment-char            . ?\#)
     (ebnf-lex-eop-char                . ?\;))
    ;; ISO EBNF default
    (iso-ebnf
     default
     (ebnf-syntax                      . 'iso-ebnf))
    ;; Yacc/Bison default
    (yacc
     default
     (ebnf-syntax                      . 'yacc))
    )
  "Style database.

Each element has the following form:

   (CUSTOM INHERITS (VAR . VALUE)...)

CUSTOM is a symbol name style.
INHERITS is a symbol name style from which the current style inherits the
context.  If INHERITS is nil, means that there is no inheritance.
VAR is a valid ebnf2ps symbol custom variable.  See `ebnf-style-custom-list'
for valid symbol variable.
VALUE is a sexp which it'll be evaluated to set the value to VAR.  So, don't
forget to quote symbols and constant lists.  See `default' style for an
example.

Don't handle this variable directly.  Use functions `ebnf-insert-style' and
`ebnf-merge-style'.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Style commands


;;;###autoload
(defun ebnf-insert-style (name inherits &rest values)
  "Insert a new style NAME with inheritance INHERITS and values VALUES."
  (interactive)
  (and (assoc name ebnf-style-database)
       (error "Style name already exists: %s" name))
  (or (assoc inherits ebnf-style-database)
      (error "Style inheritance name does'nt exist: %s" inherits))
  (setq ebnf-style-database
	(cons (cons name (cons inherits (ebnf-check-style-values values)))
	      ebnf-style-database)))


;;;###autoload
(defun ebnf-merge-style (name &rest values)
  "Merge values of style NAME with style VALUES."
  (interactive)
  (let ((style (or (assoc name ebnf-style-database)
		   (error "Style name does'nt exist: %s" name)))
	(merge (ebnf-check-style-values values))
	val elt new check)
    ;; modify value of existing variables
    (setq val (nthcdr 2 style))
    (while merge
      (setq check (car merge)
	    merge (cdr merge)
	    elt   (assoc (car check) val))
      (if elt
	  (setcdr elt (cdr check))
	(setq new (cons check new))))
    ;; insert new variables
    (nconc style (nreverse new))))


;;;###autoload
(defun ebnf-apply-style (style)
  "Set STYLE to current style.

It returns the old style symbol."
  (interactive)
  (prog1
      ebnf-current-style
    (and (ebnf-apply-style1 style)
	 (setq ebnf-current-style style))))


;;;###autoload
(defun ebnf-reset-style (&optional style)
  "Reset current style.

It returns the old style symbol."
  (interactive)
  (setq ebnf-stack-style nil)
  (ebnf-apply-style (or style 'default)))


;;;###autoload
(defun ebnf-push-style (&optional style)
  "Push the current style and set STYLE to current style.

It returns the old style symbol."
  (interactive)
  (prog1
      ebnf-current-style
    (setq ebnf-stack-style (cons ebnf-current-style ebnf-stack-style))
    (and style
	 (ebnf-apply-style style))))


;;;###autoload
(defun ebnf-pop-style ()
  "Pop a style and set it to current style.

It returns the old style symbol."
  (interactive)
  (prog1
      (ebnf-apply-style (car ebnf-stack-style))
    (setq ebnf-stack-style (cdr ebnf-stack-style))))


(defun ebnf-apply-style1 (style)
  (let ((value (cdr (assoc style ebnf-style-database))))
    (prog1
	value
      (and (car value) (ebnf-apply-style1 (car value)))
      (while (setq value (cdr value))
	(set (caar value) (eval (cdar value)))))))


(defun ebnf-check-style-values (values)
  (let (style)
    (while values
      (and (memq (car values) ebnf-style-custom-list)
	   (setq style (cons (car values) style)))
      (setq values (cdr values)))
    (nreverse style)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Internal variables


(make-local-hook 'ebnf-hook)
(make-local-hook 'ebnf-production-hook)
(make-local-hook 'ebnf-page-hook)


(defvar ebnf-eps-buffer-name " *EPS*")
(defvar ebnf-parser-func     nil)
(defvar ebnf-eps-executing   nil)
(defvar ebnf-eps-upper-x     0.0)
(make-variable-buffer-local 'ebnf-eps-upper-x)
(defvar ebnf-eps-upper-y     0.0)
(make-variable-buffer-local 'ebnf-eps-upper-y)
(defvar ebnf-eps-prod-width  0.0)
(make-variable-buffer-local 'ebnf-eps-prod-width)
(defvar ebnf-eps-max-height 0.0)
(make-variable-buffer-local 'ebnf-eps-max-height)
(defvar ebnf-eps-max-width  0.0)
(make-variable-buffer-local 'ebnf-eps-max-width)


(defvar ebnf-eps-context nil
  "List of EPS file name during parsing.

See section \"Actions in Comments\" in ebnf2ps documentation.")


(defvar ebnf-eps-production-list nil
  "Alist associating production name with EPS file name list.

Each element has the following form:

   (PRODUCTION EPS-FILENAME...)

PRODUCTION is the production name.
EPS-FILENAME is the EPS file name.

It's generated during parsing and used during EPS generation.

See `ebnf-eps-context' and section \"Actions in Comments\" in ebnf2ps
documentation.")


(defconst ebnf-arrow-shape-alist
  '((none        . 0)
    (semi-up     . 1)
    (semi-down   . 2)
    (simple      . 3)
    (transparent . 4)
    (hollow      . 5)
    (full        . 6)
    (user        . 7))
  "Alist associating values for `ebnf-arrow-shape'.

See documentation for `ebnf-arrow-shape'.")


(defconst ebnf-terminal-shape-alist
  '((miter . 0)
    (round . 1)
    (bevel . 2))
  "Alist associating values from `ebnf-terminal-shape' to a bit vector.

See documentation for `ebnf-terminal-shape', `ebnf-non-terminal-shape' and
`ebnf-chart-shape'.")


(defvar ebnf-limit            nil)
(defvar ebnf-action           nil)
(defvar ebnf-action-list      nil)


(defvar ebnf-default-p        nil)


(defvar ebnf-font-height-P    0)
(defvar ebnf-font-height-T    0)
(defvar ebnf-font-height-NT   0)
(defvar ebnf-font-height-S    0)
(defvar ebnf-font-height-E    0)
(defvar ebnf-font-height-R    0)
(defvar ebnf-font-width-P     0)
(defvar ebnf-font-width-T     0)
(defvar ebnf-font-width-NT    0)
(defvar ebnf-font-width-S     0)
(defvar ebnf-font-width-E     0)
(defvar ebnf-font-width-R     0)
(defvar ebnf-space-T          0)
(defvar ebnf-space-NT         0)
(defvar ebnf-space-S          0)
(defvar ebnf-space-E          0)
(defvar ebnf-space-R          0)


(defvar ebnf-basic-width      0)
(defvar ebnf-basic-height     0)
(defvar ebnf-vertical-space   0)
(defvar ebnf-horizontal-space 0)


(defvar ebnf-settings         nil)
(defvar ebnf-fonts-required   nil)


(defconst ebnf-debug
  "
% === begin EBNF procedures to help debugging

% Mark visually current point:  string debug
/debug
{/-s- exch def
 currentpoint
 gsave -s- show grestore
 gsave
 20 20 rlineto
 0 -40 rlineto
 -40 40 rlineto
 0 -40 rlineto
 20 20 rlineto
 stroke
 grestore
 moveto
}def

% Show number value:  number string debug-number
/debug-number
{gsave
 20 0 rmoveto show ([) show 60 string cvs show (]) show
 grestore
}def

% === end   EBNF procedures to help debugging

"
  "This is intended to help debugging PostScript programming.")


(defconst ebnf-prologue
  "
% === begin EBNF engine

% --- Basic Definitions

/fS F
/SpaceS FontHeight 0.5 mul def
/HeightS FontHeight FontHeight add def

/fE F
/SpaceE FontHeight 0.5 mul def
/HeightE FontHeight FontHeight add def

/fR F
/SpaceR FontHeight 0.5 mul def
/HeightR FontHeight FontHeight add def

/fT F
/SpaceT FontHeight 0.5 mul def
/HeightT FontHeight FontHeight add def

/fNT F
/SpaceNT FontHeight 0.5 mul def
/HeightNT FontHeight FontHeight add def

/T HeightT HeightNT add 0.5 mul def
/hT T 0.5 mul def
/hT2 hT 0.5 mul def
/hT4 hT 0.25 mul def

/Er 0.1 def	% Error factor


/c{currentpoint}bind def
/xyi{/xi c /yi exch def def}bind def
/xyo{/xo c /yo exch def def}bind def
/xyp{/xp c /yp exch def def}bind def
/xyt{/xt c /yt exch def def}bind def

% vertical movement: x y height vm
/vm{add moveto}bind def

% horizontal movement: x y width hm
/hm{3 -1 roll exch add exch moveto}bind def

% set color: [R G B] SetRGB
/SetRGB{aload pop setrgbcolor}bind def

% filling gray area: gray-scale FillGray
/FillGray{gsave setgray fill grestore}bind def

% filling color area: [R G B] FillRGB
/FillRGB{gsave SetRGB fill grestore}bind def

/Stroke{LineWidth setlinewidth LineColor SetRGB stroke}bind def
/StrokeShape{borderwidth setlinewidth bordercolor SetRGB stroke}bind def
/Gstroke{gsave Stroke grestore}bind def

% Empty Line: width EL
/EL{0 rlineto Gstroke}bind def

% --- Arrows

/Down{hT2 neg hT4 neg rlineto}bind def

/Arrow
{hT2 neg hT4 rmoveto
 hT2 hT4 neg rlineto
 Down
}bind def

/ArrowPath{c newpath moveto Arrow closepath}bind def

%>Right Arrow: RA
%    \\
% *---+
%    /
/RA-vector
[{}					% 0 - none
 {hT2 neg hT4 rlineto}			% 1 - semi-up
 {Down}					% 2 - semi-down
 {Arrow}				% 3 - simple
 {Gstroke ArrowPath}			% 4 - transparent
 {Gstroke ArrowPath 1 FillGray}		% 5 - hollow
 {Gstroke ArrowPath LineColor FillRGB}	% 6 - full
 {Gstroke gsave UserArrow grestore}	% 7 - user
]def

/RA
{hT 0 rlineto
 c
 RA-vector ArrowShape get exec
 Gstroke
 moveto
}def

% rotation DrawArrow
/DrawArrow
{gsave
 0 0 translate
 rotate
 RA
 c
 grestore
 rmoveto
}def

%>Left Arrow: LA
%  /
% +---*
%  \\
/LA{180 DrawArrow}def

%>Up Arrow: UA
%  +
% /|\\
%  |
%  *
/UA{90 DrawArrow}def

%>Down Arrow: DA
%  *
%  |
% \\|/
%  +
/DA{270 DrawArrow}def

% --- Corners

%>corner Right Descendent: height arrow corner_RD
%   _             | arrow
%  /   height > 0 |  0 - none
% |               |  1 - right
% *    ---------- |  2 - left
% |               |  3 - vertical
%  \\   height < 0 |
%   -             |
/cRD0-vector
[% 0 - none
 {0 h rlineto
  hT 0 rlineto}
 % 1 - right
 {0 h rlineto
  RA}
 % 2 - left
 {hT 0 rmoveto xyi
  LA
  0 h neg rlineto
  xi yi moveto}
 % 3 - vertical
 {hT h rmoveto xyi
  hT neg 0 rlineto
  h 0 gt{DA}{UA}ifelse
  xi yi moveto}
]def

/cRD-vector
[{cRD0-vector arrow get exec}	% 0 - miter
 {0 0 0 h hT h rcurveto}	% 1 - rounded
 {hT h rlineto}			% 2 - bevel
]def

/corner_RD
{/arrow exch def /h exch def
 cRD-vector ChartShape get exec
 Gstroke
}def

%>corner Right Ascendent: height arrow corner_RA
%                 | arrow
%    | height > 0 |  0 - none
%   /             |  1 - right
% *-   ---------- |  2 - left
%   \\             |  3 - vertical
%    | height < 0 |
%                 |
/cRA0-vector
[% 0 - none
 {hT 0 rlineto
  0 h rlineto}
 % 1 - right
 {RA
  0 h rlineto}
 % 2 - left
 {hT h rmoveto xyi
  0 h neg rlineto
  LA
  xi yi moveto}
 % 3 - vertical
 {hT h rmoveto xyi
  h 0 gt{DA}{UA}ifelse
  hT neg 0 rlineto
  xi yi moveto}
]def

/cRA-vector
[{cRA0-vector arrow get exec}	% 0 - miter
 {0 0 hT 0 hT h rcurveto}	% 1 - rounded
 {hT h rlineto}			% 2 - bevel
]def

/corner_RA
{/arrow exch def /h exch def
 cRA-vector ChartShape get exec
 Gstroke
}def

%>corner Left Descendent: height arrow corner_LD
%  _              | arrow
%   \\  height > 0 |  0 - none
%    |            |  1 - right
%    * ---------- |  2 - left
%    |            |  3 - vertical
%   /  height < 0 |
%  -              |
/cLD0-vector
[% 0 - none
 {0 h rlineto
  hT neg 0 rlineto}
 % 1 - right
 {hT neg h rmoveto xyi
  RA
  0 h neg rlineto
  xi yi moveto}
 % 2 - left
 {0 h rlineto
  LA}
 % 3 - vertical
 {hT neg h rmoveto xyi
  hT 0 rlineto
  h 0 gt{DA}{UA}ifelse
  xi yi moveto}
]def

/cLD-vector
[{cLD0-vector arrow get exec}	% 0 - miter
 {0 0 0 h hT neg h rcurveto}	% 1 - rounded
 {hT neg h rlineto}		% 2 - bevel
]def

/corner_LD
{/arrow exch def /h exch def
 cLD-vector ChartShape get exec
 Gstroke
}def

%>corner Left Ascendent: height arrow corner_LA
%                 | arrow
% |    height > 0 |  0 - none
%  \\              |  1 - right
%   -* ---------- |  2 - left
%  /              |  3 - vertical
% |    height < 0 |
%                 |
/cLA0-vector
[% 0 - none
 {hT neg 0 rlineto
  0 h rlineto}
 % 1 - right
 {hT neg h rmoveto xyi
  0 h neg rlineto
  RA
  xi yi moveto}
 % 2 - left
 {LA
  0 h rlineto}
 % 3 - vertical
 {hT neg h rmoveto xyi
  h 0 gt{DA}{UA}ifelse
  hT 0 rlineto
  xi yi moveto}
]def

/cLA-vector
[{cLA0-vector arrow get exec}		% 0 - miter
 {0 0 hT neg 0 hT neg h rcurveto}	% 1 - rounded
 {hT neg h rlineto}			% 2 - bevel
]def

/corner_LA
{/arrow exch def /h exch def
 cLA-vector ChartShape get exec
 Gstroke
}def

% --- Flow Stuff

% height prepare_height |- line_height corner_height corner_height
/prepare_height
{dup 0 gt
 {T sub hT}
 {T add hT neg}ifelse
 dup
}def

%>Left Alternative: height LAlt
%      _
%     /
%    |   height > 0
%    |
%   /
% *-     ----------
%   \\
%    |
%    |   height < 0
%     \\
%      -
/LAlt
{dup 0 eq
 {T exch rlineto}
 {dup abs T lt
  {0.5 mul dup
   1 corner_RA
   0 corner_RD}
  {prepare_height
   1 corner_RA
   exch 0 exch rlineto
   0 corner_RD
  }ifelse
 }ifelse
}def

%>Left Loop: height LLoop
%   _
%  /
% |      height > 0
% |
%  \\
%   -*   ----------
%  /
% |
% |      height < 0
%  \\
%   -
/LLoop
{prepare_height
 3 corner_LA
 exch 0 exch rlineto
 0 corner_RD
}def

%>Right Alternative: height RAlt
% _
%  \\
%   |    height > 0
%   |
%    \\
%     -* ----------
%    /
%   |
%   |    height < 0
%  /
% -
/RAlt
{dup 0 eq
 {T neg exch rlineto}
 {dup abs T lt
  {0.5 mul dup
   1 corner_LA
   0 corner_LD}
  {prepare_height
   1 corner_LA
   exch 0 exch rlineto
   0 corner_LD
  }ifelse
 }ifelse
}def

%>Right Loop: height RLoop
%  _
%   \\
%    |   height > 0
%    |
%   /
% *-     ----------
%   \\
%    |
%    |   height < 0
%   /
%  -
/RLoop
{prepare_height
 1 corner_RA
 exch 0 exch rlineto
 0 corner_LD
}def

% --- Terminal, Non-terminal and Special Basics

% string width prepare-width |- string
/prepare-width
{/width exch def
 dup stringwidth pop space add space add width exch sub 0.5 mul
 /w exch def
}def

% string width begin-right
/begin-right
{xyo
 prepare-width
 w hT sub EL
 RA
}def

% end-right
/end-right
{xo width add Er add yo moveto
 w Er add neg EL
 xo yo moveto
}def

% string width begin-left
/begin-left
{xyo
 prepare-width
 w EL
}def

% end-left
/end-left
{xo width add Er add yo moveto
 hT w sub Er add EL
 LA
 xo yo moveto
}def

/ShapePath-vector
[% 0 - miter
 {xx yy moveto
  xx YY lineto
  XX YY lineto
  XX yy lineto}
 % 1 - rounded
 {/half YY yy sub 0.5 mul abs def
  xx half add YY moveto
  0 0 half neg 0 half neg half neg rcurveto
  0 0 0 half neg half half neg rcurveto
  XX xx sub abs half sub half sub 0 rlineto
  0 0 half 0 half half rcurveto
  0 0 0 half half neg half rcurveto}
 % 2 - bevel
 {/quarter YY yy sub 0.25 mul abs def
  xx quarter add YY moveto
  quarter neg quarter neg rlineto
  0 quarter quarter add neg rlineto
  quarter quarter neg rlineto
  XX xx sub abs quarter sub quarter sub 0 rlineto
  quarter quarter rlineto
  0 quarter quarter add rlineto
  quarter neg quarter rlineto}
]def

/doShapePath
{newpath
 ShapePath-vector shape get exec
 closepath
}def

/doShapeShadow
{gsave
 Xshadow Xshadow add Xshadow add
 Yshadow Yshadow add Yshadow add translate
 doShapePath
 0.9 FillGray
 grestore
}def

/doShape
{gsave
 doShapePath
 shapecolor FillRGB
 StrokeShape
 grestore
}def

% string SBound |- string
/SBound
{/xx c dup /yy exch def
 FontHeight add /YY exch def def
 dup stringwidth pop xx add /XX exch def
 Effect 8 and 0 ne
 {/yy yy YShadow add def
  /XX XX XShadow add def
 }if
}def

% string SBox
/SBox
{gsave
 c space sub moveto
 SBound
 /XX XX space add space add def
 /YY YY space add def
 /yy yy space sub def
 shadow{doShapeShadow}if
 doShape
 space Descent abs rmoveto
 foreground SetRGB S
 grestore
}def

% --- Terminal

% TeRminal: string TR
/TR
{/Effect EffectT def
 /shape ShapeT def
 /shapecolor BackgroundT def
 /borderwidth BorderWidthT def
 /bordercolor BorderColorT def
 /foreground ForegroundT def
 /shadow ShadowT def
 SBox
}def

%>Right Terminal: string width RT |- x y
/RT
{xyt
 /fT F
 /space SpaceT def
 begin-right
 TR
 end-right
 xt yt
}def

%>Left Terminal: string width LT |- x y
/LT
{xyt
 /fT F
 /space SpaceT def
 begin-left
 TR
 end-left
 xt yt
}def

%>Right Terminal Default: string width RTD |- x y
/RTD
{/-save- BorderWidthT def
 /BorderWidthT BorderWidthT DefaultWidth add def
 RT
 /BorderWidthT -save- def
}def

%>Left Terminal Default: string width LTD |- x y
/LTD
{/-save- BorderWidthT def
 /BorderWidthT BorderWidthT DefaultWidth add def
 LT
 /BorderWidthT -save- def
}def

% --- Non-Terminal

% Non-Terminal: string NT
/NT
{/Effect EffectNT def
 /shape ShapeNT def
 /shapecolor BackgroundNT def
 /borderwidth BorderWidthNT def
 /bordercolor BorderColorNT def
 /foreground ForegroundNT def
 /shadow ShadowNT def
 SBox
}def

%>Right Non-Terminal: string width RNT |- x y
/RNT
{xyt
 /fNT F
 /space SpaceNT def
 begin-right
 NT
 end-right
 xt yt
}def

%>Left Non-Terminal: string width LNT |- x y
/LNT
{xyt
 /fNT F
 /space SpaceNT def
 begin-left
 NT
 end-left
 xt yt
}def

%>Right Non-Terminal Default: string width RNTD |- x y
/RNTD
{/-save- BorderWidthNT def
 /BorderWidthNT BorderWidthNT DefaultWidth add def
 RNT
 /BorderWidthNT -save- def
}def

%>Left Non-Terminal Default: string width LNTD |- x y
/LNTD
{/-save- BorderWidthNT def
 /BorderWidthNT BorderWidthNT DefaultWidth add def
 LNT
 /BorderWidthNT -save- def
}def

% --- Special

% SPecial: string SP
/SP
{/Effect EffectS def
 /shape ShapeS def
 /shapecolor BackgroundS def
 /borderwidth BorderWidthS def
 /bordercolor BorderColorS def
 /foreground ForegroundS def
 /shadow ShadowS def
 SBox
}def

%>Right SPecial: string width RSP |- x y
/RSP
{xyt
 /fS F
 /space SpaceS def
 begin-right
 SP
 end-right
 xt yt
}def

%>Left SPecial: string width LSP |- x y
/LSP
{xyt
 /fS F
 /space SpaceS def
 begin-left
 SP
 end-left
 xt yt
}def

%>Right SPecial Default: string width RSPD |- x y
/RSPD
{/-save- BorderWidthS def
 /BorderWidthS BorderWidthS DefaultWidth add def
 RSP
 /BorderWidthS -save- def
}def

%>Left SPecial Default: string width LSPD |- x y
/LSPD
{/-save- BorderWidthS def
 /BorderWidthS BorderWidthS DefaultWidth add def
 LSP
 /BorderWidthS -save- def
}def

% --- Repeat and Except basics

/begin-direction
{/w width rwidth sub 0.5 mul def
 width 0 rmoveto}def

/end-direction
{gsave
 /xx c entry add /YY exch def def
 /yy YY height sub def
 /XX xx rwidth add def
 shadow{doShapeShadow}if
 doShape
 grestore
}def

/right-direction
{begin-direction
 w neg EL
 xt yt moveto
 w hT sub EL RA
 end-direction
}def

/left-direction
{begin-direction
 hT w sub EL LA
 xt yt moveto
 w EL
 end-direction
}def

% --- Repeat

% entry height width rwidth begin-repeat
/begin-repeat
{/rwidth exch def
 /width exch def
 /height exch def
 /entry exch def
 /fR F
 /space SpaceR def
 /Effect EffectR def
 /shape ShapeR def
 /shapecolor BackgroundR def
 /borderwidth BorderWidthR def
 /bordercolor BorderColorR def
 /foreground ForegroundR def
 /shadow ShadowR def
 xyt
}def

% string end-repeat |- x y
/end-repeat
{gsave
 space Descent rmoveto
 foreground SetRGB S
 c Descent sub
 grestore
 exch space add exch moveto
 xt yt
}def

%>Right RePeat: string entry height width rwidth RRP |- x y
/RRP{begin-repeat right-direction end-repeat}def

%>Left RePeat: string entry height width rwidth LRP |- x y
/LRP{begin-repeat left-direction end-repeat}def

% --- Except

% entry height width rwidth begin-except
/begin-except
{/rwidth exch def
 /width exch def
 /height exch def
 /entry exch def
 /fE F
 /space SpaceE def
 /Effect EffectE def
 /shape ShapeE def
 /shapecolor BackgroundE def
 /borderwidth BorderWidthE def
 /bordercolor BorderColorE def
 /foreground ForegroundE def
 /shadow ShadowE def
 xyt
}def

% x-width end-except |- x y
/end-except
{gsave
 space space add add Descent rmoveto
 (-) foreground SetRGB S
 grestore
 space 0 rmoveto
 xt yt
}def

%>Right EXcept: x-width entry height width rwidth REX |- x y
/REX{begin-except right-direction end-except}def

%>Left EXcept: x-width entry height width rwidth LEX |- x y
/LEX{begin-except left-direction end-except}def

% --- Sequence

%>Beginning Of Sequence: BOS |- x y
/BOS{currentpoint}bind def

%>End Of Sequence: x y x1 y1 EOS |- x y
/EOS{pop pop}bind def

% --- Production

%>Beginning Of Production: string width height BOP |- y x
/BOP
{xyp
 neg yp add /yw exch def
 xp add T sub /xw exch def
 /Effect EffectP def
 /fP F ForegroundP SetRGB BackgroundP aload pop true BG S
 /Effect 0 def
 ( :) S false BG
 xw yw moveto
 hT EL RA
 xp yw moveto
 T EL
 yp xp
}def

%>End Of Production: y x delta EOP
/EOPH{add exch moveto}bind def			% horizontal
/EOPV{exch pop sub 0 exch moveto}bind def	% vertical

% --- Empty Alternative

%>Empty Alternative: width EA |- x y
/EA
{gsave
 Er add 0 rlineto
 Stroke
 grestore
 c
}def

% --- Alternative

%>AlTernative: h1 h2 ... hn n width AT |- x y
/AT
{xyo xo add /xw exch def
 xw yo moveto
 Er EL
 {xw yo moveto
  dup RAlt
  xo yo moveto
  LAlt}repeat
 xo yo
}def

% --- Optional

%>OPtional: height width OP |- x y
/OP
{xyo
 T sub /ow exch def
 ow Er sub 0 rmoveto
 T Er add EL
 neg dup RAlt
 ow T sub neg EL
 xo yo moveto
 LAlt
 xo yo moveto
 T EL
 xo yo
}def

% --- List Flow

%>One or More: height width OM |- x y
/OM
{xyo
 /ow exch def
 ow Er add 0 rmoveto
 T Er add neg EL
 dup RLoop
 xo T add yo moveto
 LLoop
 xo yo moveto
 T EL
 xo yo
}def

%>Zero or More: h2 h1 width ZM |- x y
/ZM
{xyo
 Er add EL
 Er neg 0 rmoveto
 dup RAlt
 exch dup RLoop
 xo yo moveto
 exch dup LAlt
 exch LLoop
 yo add xo T add exch moveto
 xo yo
}def

% === end EBNF engine

"
  "EBNF PostScript prologue")


(defconst ebnf-eps-prologue
  "
/#ebnf2ps#dict 230 dict def
#ebnf2ps#dict begin

% Initiliaze variables to avoid name-conflicting with document variables.
% This is the case when using `bind' operator.
/-fillp-		0 def		/h		0 def
/-ox-			0 def		/half		0 def
/-oy-			0 def		/height		0 def
/-save-			0 def		/ow		0 def
/Ascent			0 def		/quarter	0 def
/Descent		0 def		/rXX		0 def
/Effect			0 def		/rYY		0 def
/FontHeight		0 def		/rwidth		0 def
/LineThickness		0 def		/rxx		0 def
/OverlinePosition	0 def		/ryy		0 def
/SpaceBackground	0 def		/shadow		0 def
/StrikeoutPosition	0 def		/shape		0 def
/UnderlinePosition	0 def		/shapecolor	0 def
/XBox			0 def		/space		0 def
/XX			0 def		/st		1 string def
/Xshadow		0 def		/w		0 def
/YBox			0 def		/width		0 def
/YY			0 def		/xi		0 def
/Yshadow		0 def		/xo		0 def
/arrow			0 def		/xp		0 def
/bg			false def	/xt		0 def
/bgcolor		0 def		/xw		0 def
/bordercolor		0 def		/xx		0 def
/borderwidth		0 def		/yi		0 def
/dd			0 def		/yo		0 def
/entry			0 def		/yp		0 def
/foreground		0 def		/yt		0 def
					/yy		0 def


% ISOLatin1Encoding stolen from ps_init.ps in GhostScript 2.6.1.4:
/ISOLatin1Encoding where
{pop}
{% -- The ISO Latin-1 encoding vector isn't known, so define it.
 % -- The first half is the same as the standard encoding,
 % -- except for minus instead of hyphen at code 055.
 /ISOLatin1Encoding
  StandardEncoding 0  45 getinterval aload pop
  /minus
  StandardEncoding 46 82 getinterval aload pop
 %*** NOTE: the following are missing in the Adobe documentation,
 %*** but appear in the displayed table:
 %*** macron at 0225, dieresis at 0230, cedilla at 0233, space at 0240.
 % 0200 (128)
  /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
  /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
  /dotlessi /grave /acute /circumflex /tilde /macron /breve /dotaccent
  /dieresis /.notdef /ring /cedilla /.notdef /hungarumlaut /ogonek /caron
 % 0240 (160)
  /space /exclamdown /cent /sterling
	/currency /yen /brokenbar /section
  /dieresis /copyright /ordfeminine /guillemotleft
	/logicalnot /hyphen /registered /macron
  /degree /plusminus /twosuperior /threesuperior
	/acute /mu /paragraph /periodcentered
  /cedilla /onesuperior /ordmasculine /guillemotright
	/onequarter /onehalf /threequarters /questiondown
 % 0300 (192)
  /Agrave /Aacute /Acircumflex /Atilde
	/Adieresis /Aring /AE /Ccedilla
  /Egrave /Eacute /Ecircumflex /Edieresis
	/Igrave /Iacute /Icircumflex /Idieresis
  /Eth /Ntilde /Ograve /Oacute
	/Ocircumflex /Otilde /Odieresis /multiply
  /Oslash /Ugrave /Uacute /Ucircumflex
	/Udieresis /Yacute /Thorn /germandbls
 % 0340 (224)
  /agrave /aacute /acircumflex /atilde
	/adieresis /aring /ae /ccedilla
  /egrave /eacute /ecircumflex /edieresis
	/igrave /iacute /icircumflex /idieresis
  /eth /ntilde /ograve /oacute
	/ocircumflex /otilde /odieresis /divide
  /oslash /ugrave /uacute /ucircumflex
	/udieresis /yacute /thorn /ydieresis
 256 packedarray def
}ifelse

/reencodeFontISO	%def
{dup
 length 12 add dict	% Make a new font (a new dict the same size
			% as the old one) with room for our new symbols.

 begin			% Make the new font the current dictionary.
  {1 index /FID ne
   {def}{pop pop}ifelse
  }forall		% Copy each of the symbols from the old dictionary
			% to the new one except for the font ID.

  currentdict /FontType get 0 ne
  {/Encoding ISOLatin1Encoding def}if	% Override the encoding with
					% the ISOLatin1 encoding.

  % Use the font's bounding box to determine the ascent, descent,
  % and overall height; don't forget that these values have to be
  % transformed using the font's matrix.

  %          ^    (x2 y2)
  %          |       |
  %          |       v
  %          |  +----+ - -
  %          |  |    |   ^
  %          |  |    |   | Ascent (usually > 0)
  %          |  |    |   |
  % (0 0) -> +--+----+-------->
  %             |    |   |
  %             |    |   v Descent (usually < 0)
  % (x1 y1) --> +----+ - -

  currentdict /FontType get 0 ne
  {/FontBBox load aload pop		% -- x1 y1 x2 y2
   FontMatrix transform /Ascent  exch def pop
   FontMatrix transform /Descent exch def pop}
  {/PrimaryFont FDepVector 0 get def
   PrimaryFont /FontBBox get aload pop
   PrimaryFont /FontMatrix get transform /Ascent exch def pop
   PrimaryFont /FontMatrix get transform /Descent exch def pop
  }ifelse

  /FontHeight Ascent Descent sub def	% use `sub' because descent < 0

  % Define these in case they're not in the FontInfo
  % (also, here they're easier to get to).
  /UnderlinePosition  Descent 0.70 mul def
  /OverlinePosition   Descent UnderlinePosition sub Ascent add def
  /StrikeoutPosition  Ascent 0.30 mul def
  /LineThickness      FontHeight 0.05 mul def
  /Xshadow            FontHeight  0.08 mul def
  /Yshadow            FontHeight -0.09 mul def
  /SpaceBackground    Descent neg UnderlinePosition add def
  /XBox               Descent neg def
  /YBox               LineThickness 0.7 mul def

  currentdict	% Leave the new font on the stack
 end		% Stop using the font as the current dictionary
 definefont	% Put the font into the font dictionary
 pop		% Discard the returned font
}bind def

% Font definition
/DefFont{findfont exch scalefont reencodeFontISO}def

% Font selection
/F
{findfont
 dup /Ascent            get /Ascent            exch def
 dup /Descent           get /Descent           exch def
 dup /FontHeight        get /FontHeight        exch def
 dup /UnderlinePosition get /UnderlinePosition exch def
 dup /OverlinePosition  get /OverlinePosition  exch def
 dup /StrikeoutPosition get /StrikeoutPosition exch def
 dup /LineThickness     get /LineThickness     exch def
 dup /Xshadow           get /Xshadow           exch def
 dup /Yshadow           get /Yshadow           exch def
 dup /SpaceBackground   get /SpaceBackground   exch def
 dup /XBox              get /XBox              exch def
 dup /YBox              get /YBox              exch def
 setfont
}def

/BG
{dup /bg exch def
 {mark 4 1 roll ]}
 {[ 1.0 1.0 1.0 ]}
 ifelse
 /bgcolor exch def
}def

% stack:  --
/FillBgColor{bgcolor aload pop setrgbcolor fill}bind def

% stack:  fill-or-not lower-x lower-y upper-x upper-y  |-  --
/doRect
{/rYY exch def
 /rXX exch def
 /ryy exch def
 /rxx exch def
 gsave
 newpath
 rXX rYY moveto
 rxx rYY lineto
 rxx ryy lineto
 rXX ryy lineto
 closepath
 % top of stack: fill-or-not
 {FillBgColor}
 {LineThickness setlinewidth stroke}
 ifelse
 grestore
}bind def

% stack:  string fill-or-not  |-  --
/doOutline
{/-fillp- exch def
 /-ox- currentpoint /-oy- exch def def
 gsave
 LineThickness setlinewidth
 {st 0 3 -1 roll put
  st dup true charpath
  -fillp- {gsave FillBgColor grestore}if
  stroke stringwidth
  -oy- add /-oy- exch def
  -ox- add /-ox- exch def
  -ox- -oy- moveto
 }forall
 grestore
 -ox- -oy- moveto
}bind def

% stack:  fill-or-not delta  |-  --
/doBox
{/dd exch def
 xx XBox sub dd sub yy YBox sub dd sub
 XX XBox add dd add YY YBox add dd add
 doRect
}bind def

% stack:  string  |-  --
/doShadow
{gsave
 Xshadow Yshadow rmoveto
 false doOutline
 grestore
}bind def

% stack:  position  |-  --
/Hline
{currentpoint exch pop add dup
 gsave
 newpath
 xx exch moveto
 XX exch lineto
 closepath
 LineThickness setlinewidth stroke
 grestore
}bind def

% stack:  string  |-  --
% effect: 1  - underline  2   - strikeout  4  - overline
%         8  - shadow     16  - box        32 - outline
/S
{/xx currentpoint dup Descent add /yy exch def
 Ascent add /YY exch def def
 dup stringwidth pop xx add /XX exch def
 Effect 8 and 0 ne
 {/yy yy Yshadow add def
  /XX XX Xshadow add def
 }if
 bg
 {true
  Effect 16 and 0 ne
  {SpaceBackground doBox}
  {xx yy XX YY doRect}
  ifelse
 }if						% background
 Effect 16 and 0 ne{false 0 doBox}if		% box
 Effect 8  and 0 ne{dup doShadow}if		% shadow
 Effect 32 and 0 ne
 {true doOutline}				% outline
 {show}						% normal text
 ifelse
 Effect 1  and 0 ne{UnderlinePosition Hline}if	% underline
 Effect 2  and 0 ne{StrikeoutPosition Hline}if	% strikeout
 Effect 4  and 0 ne{OverlinePosition  Hline}if	% overline
}bind def

"
  "EBNF EPS prologue")


(defconst ebnf-eps-begin
  "
end

% x y #ebnf2ps#begin
/#ebnf2ps#begin
{#ebnf2ps#dict begin /#ebnf2ps#save save def
 moveto false BG 0.0 0.0 0.0 setrgbcolor}def

/#ebnf2ps#end{showpage #ebnf2ps#save restore end}def

%%EndPrologue
"
  "EBNF EPS begin")


(defconst ebnf-eps-end
  "#ebnf2ps#end
%%EOF
"
  "EBNF EPS end")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Formatting


(defvar ebnf-format-float "%1.3f")


(defun ebnf-format-float (&rest floats)
  (mapconcat
   #'(lambda (float)
       (format ebnf-format-float float))
   floats
   " "))


(defun ebnf-format-color (format-str color default)
  (let* ((the-color (or color default))
	 (rgb (ps-color-scale the-color)))
    (format format-str
	    (concat "["
		    (ebnf-format-float (nth 0 rgb) (nth 1 rgb) (nth 2 rgb))
		    "]")
	    the-color)))


(defvar ebnf-message-float "%3.2f")


(defsubst ebnf-message-float (format-str value)
  (message format-str
	   (format ebnf-message-float value)))


(defsubst ebnf-message-info (messag)
  (message "%s...%3d%%"
	   messag
	   (round (/ (* (setq ebnf-nprod (1+ ebnf-nprod)) 100.0) ebnf-total))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Macros


(defmacro ebnf-node-kind (vec &optional value)
  (if value
      `(aset ,vec 0 ,value)
    `(aref ,vec 0)))


(defmacro ebnf-node-width-func (node width)
  `(funcall (aref ,node 1) ,node ,width))


(defmacro ebnf-node-dimension-func (node &optional value)
  (if value
      `(aset ,node 2 ,value)
    `(funcall (aref ,node 2) ,node)))


(defmacro ebnf-node-entry (vec &optional value)
  (if value
      `(aset ,vec 3 ,value)
    `(aref ,vec 3)))


(defmacro ebnf-node-height (vec &optional value)
  (if value
      `(aset ,vec 4 ,value)
    `(aref ,vec 4)))


(defmacro ebnf-node-width (vec &optional value)
  (if value
      `(aset ,vec 5 ,value)
    `(aref ,vec 5)))


(defmacro ebnf-node-name (vec)
  `(aref ,vec 6))


(defmacro ebnf-node-list (vec &optional value)
  (if value
      `(aset ,vec 6 ,value)
    `(aref ,vec 6)))


(defmacro ebnf-node-default (vec)
  `(aref ,vec 7))


(defmacro ebnf-node-production (vec &optional value)
  (if value
      `(aset ,vec 7 ,value)
    `(aref ,vec 7)))


(defmacro ebnf-node-separator (vec &optional value)
  (if value
      `(aset ,vec 7 ,value)
    `(aref ,vec 7)))


(defmacro ebnf-node-action (vec &optional value)
  (if value
      `(aset ,vec 8 ,value)
    `(aref ,vec 8)))


(defmacro ebnf-node-generation (node)
  `(funcall (ebnf-node-kind ,node) ,node))


(defmacro ebnf-max-width (prod)
  `(max (ebnf-node-width ,prod)
	(+ (* (length (ebnf-node-name ,prod))
	      ebnf-font-width-P)
	   ebnf-production-horizontal-space)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PostScript generation


(defun ebnf-generate-eps (ebnf-tree)
  (let* ((ps-color-p           (and ebnf-color-p (ps-color-device)))
	 (ps-print-color-scale (if ps-color-p
				   (float (car (ps-color-values "white")))
				 1.0))
	 (ebnf-total           (length ebnf-tree))
	 (ebnf-nprod           0)
	 (old-ps-output        (symbol-function 'ps-output))
	 (old-ps-output-string (symbol-function 'ps-output-string))
	 (eps-buffer           (get-buffer-create ebnf-eps-buffer-name))
	 ebnf-debug-ps error-msg horizontal
	 prod prod-name prod-width prod-height prod-list file-list)
    ;; redefines `ps-output' and `ps-output-string'
    (defalias 'ps-output        'ebnf-eps-output)
    (defalias 'ps-output-string 'ps-output-string-prim)
    ;; generate EPS file
    (save-excursion
      (condition-case data
	  (progn
	    (while ebnf-tree
	      (setq prod        (car ebnf-tree)
		    prod-name   (ebnf-node-name prod)
		    prod-width  (ebnf-max-width prod)
		    prod-height (ebnf-node-height prod)
		    horizontal  (memq (ebnf-node-action prod)
				      ebnf-action-list))
	      ;; generate production in EPS buffer
	      (save-excursion
		(set-buffer eps-buffer)
		(setq ebnf-eps-upper-x    0.0
		      ebnf-eps-upper-y    0.0
		      ebnf-eps-max-width  prod-width
		      ebnf-eps-max-height prod-height)
		(ebnf-generate-production prod))
	      (if (setq prod-list (cdr (assoc prod-name
					      ebnf-eps-production-list)))
		  ;; insert EPS buffer in all buffer associated with production
		  (ebnf-eps-production-list prod-list 'file-list horizontal
					    prod-width prod-height eps-buffer)
		;; write EPS file for production
		(ebnf-eps-finish-and-write eps-buffer
					   (ebnf-eps-filename prod-name)))
	      ;; prepare for next loop
	      (save-excursion
		(set-buffer eps-buffer)
		(erase-buffer))
	      (setq ebnf-tree (cdr ebnf-tree)))
	    ;; write and kill temporary buffers
	    (ebnf-eps-write-kill-temp file-list t)
	    (setq file-list nil))
	;; handler
	((quit error)
	 (setq error-msg (error-message-string data)))))
    ;; restore `ps-output' and `ps-output-string'
    (defalias 'ps-output        old-ps-output)
    (defalias 'ps-output-string old-ps-output-string)
    ;; kill temporary buffers
    (kill-buffer eps-buffer)
    (ebnf-eps-write-kill-temp file-list nil)
    (and error-msg (error error-msg))
    (message " ")))


;; write and kill temporary buffers
(defun ebnf-eps-write-kill-temp (file-list write-p)
  (while file-list
    (let ((buffer (get-buffer (concat " *" (car file-list) "*"))))
      (when buffer
	(and write-p
	     (ebnf-eps-finish-and-write buffer (car file-list)))
	(kill-buffer buffer)))
    (setq file-list (cdr file-list))))


;; insert EPS buffer in all buffer associated with production
(defun ebnf-eps-production-list (prod-list file-list-sym horizontal
					   prod-width prod-height eps-buffer)
  (while prod-list
    (add-to-list file-list-sym (car prod-list))
    (save-excursion
      (set-buffer (get-buffer-create (concat " *" (car prod-list) "*")))
      (goto-char (point-max))
      (cond
       ;; first production
       ((zerop (buffer-size))
	(setq ebnf-eps-upper-x    0.0
	      ebnf-eps-upper-y    0.0
	      ebnf-eps-max-width  prod-width
	      ebnf-eps-max-height prod-height))
       ;; horizontal
       (horizontal
	(ebnf-eop-horizontal ebnf-eps-prod-width)
	(setq ebnf-eps-max-width  (+ ebnf-eps-max-width
				     ebnf-production-horizontal-space
				     prod-width)
	      ebnf-eps-max-height (max ebnf-eps-max-height prod-height)))
       ;; vertical
       (t
	(ebnf-eop-vertical ebnf-eps-max-height)
	(setq ebnf-eps-upper-x    (max ebnf-eps-upper-x ebnf-eps-max-width)
	      ebnf-eps-upper-y    (if (zerop ebnf-eps-upper-y)
				      ebnf-eps-max-height
				    (+ ebnf-eps-upper-y
				       ebnf-production-vertical-space
				       ebnf-eps-max-height))
	      ebnf-eps-max-width  prod-width
	      ebnf-eps-max-height prod-height))
       )
      (setq ebnf-eps-prod-width prod-width)
      (insert-buffer eps-buffer))
    (setq prod-list (cdr prod-list))))


(defun ebnf-generate (ebnf-tree)
  (let* ((ps-color-p           (and ebnf-color-p (ps-color-device)))
	 (ps-print-color-scale (if ps-color-p
				   (float (car (ps-color-values "white")))
				 1.0))
	 ps-zebra-stripes ps-line-number ps-razzle-dazzle
	 ps-print-hook
	 ps-print-begin-sheet-hook
	 ps-print-begin-page-hook
	 ps-print-begin-column-hook)
    (ps-generate (current-buffer) (point-min) (point-max)
		 'ebnf-generate-postscript)))


(defvar ebnf-tree      nil)
(defvar ebnf-direction "R")
(defvar ebnf-total     0)
(defvar ebnf-nprod     0)


(defun ebnf-generate-postscript (from to)
  (ebnf-begin-file)
  (if ebnf-horizontal-max-height
      (ebnf-generate-with-max-height)
    (ebnf-generate-without-max-height))
  (message " "))


(defun ebnf-generate-with-max-height ()
  (let ((ebnf-total (length ebnf-tree))
	(ebnf-nprod 0)
	next-line max-height prod the-width)
    (while ebnf-tree
      ;; find next line point
      (setq next-line  ebnf-tree
	    prod       (car ebnf-tree)
	    max-height (ebnf-node-height prod))
      (ebnf-begin-line prod (ebnf-max-width prod))
      (while (and (setq next-line (cdr next-line))
		  (setq prod      (car next-line))
		  (memq (ebnf-node-action prod) ebnf-action-list)
		  (setq the-width (ebnf-max-width prod))
		  (<= the-width ps-width-remaining))
	(setq max-height         (max max-height (ebnf-node-height prod))
	      ps-width-remaining (- ps-width-remaining
				    (+ the-width
				       ebnf-production-horizontal-space))))
      ;; generate current line
      (ebnf-newline max-height)
      (setq prod (car ebnf-tree))
      (ebnf-generate-production prod)
      (while (not (eq (setq ebnf-tree (cdr ebnf-tree)) next-line))
	(ebnf-eop-horizontal (ebnf-max-width prod))
	(setq prod (car ebnf-tree))
	(ebnf-generate-production prod))
      (ebnf-eop-vertical max-height))))


(defun ebnf-generate-without-max-height ()
  (let ((ebnf-total (length ebnf-tree))
	(ebnf-nprod 0)
	max-height prod bef-width cur-width)
    (while ebnf-tree
      ;; generate current line
      (setq prod       (car ebnf-tree)
	    max-height (ebnf-node-height prod)
	    bef-width  (ebnf-max-width prod))
      (ebnf-begin-line prod bef-width)
      (ebnf-generate-production prod)
      (while (and (setq ebnf-tree (cdr ebnf-tree))
		  (setq prod      (car ebnf-tree))
		  (memq (ebnf-node-action prod) ebnf-action-list)
		  (setq cur-width (ebnf-max-width prod))
		  (<= cur-width ps-width-remaining)
		  (<= (ebnf-node-height prod) ps-height-remaining))
	(ebnf-eop-horizontal bef-width)
	(ebnf-generate-production prod)
	(setq bef-width          cur-width
	      max-height         (max max-height (ebnf-node-height prod))
	      ps-width-remaining (- ps-width-remaining
				    (+ cur-width
				       ebnf-production-horizontal-space))))
      (ebnf-eop-vertical max-height)
      ;; prepare next line
      (ebnf-newline max-height))))


(defun ebnf-begin-line (prod width)
  (and (or (eq (ebnf-node-action prod) 'form-feed)
	   (> (ebnf-node-height prod) ps-height-remaining))
       (ebnf-new-page))
  (setq ps-width-remaining (- ps-width-remaining
			      (+ width
				 ebnf-production-horizontal-space))))


(defun ebnf-newline (height)
  (and (> height ps-height-remaining)
       (ebnf-new-page))
  (setq ps-width-remaining  ps-print-width
	ps-height-remaining (- ps-height-remaining
			       (+ height
				  ebnf-production-vertical-space))))


;; [production width-fun dim-fun entry height width name production action]
(defun ebnf-generate-production (production)
  (ebnf-message-info "Generating")
  (run-hooks 'ebnf-production-hook)
  (ps-output-string (ebnf-node-name production))
  (ps-output " "
	     (ebnf-format-float
	      (ebnf-node-width production)
	      (+ ebnf-basic-height
		 (ebnf-node-entry (ebnf-node-production production))))
	     " BOP\n")
  (ebnf-node-generation (ebnf-node-production production))
  (ps-output "EOS\n"))


;; [alternative width-fun dim-fun entry height width list]
(defun ebnf-generate-alternative (alternative)
  (let ((alt   (ebnf-node-list alternative))
	(entry (ebnf-node-entry alternative))
	(nlist 0)
	alt-height alt-entry)
    (while alt
      (ps-output (ebnf-format-float (- entry (ebnf-node-entry (car alt))))
		 " ")
      (setq entry (- entry (ebnf-node-height (car alt)) ebnf-vertical-space)
	    nlist (1+ nlist)
	    alt   (cdr alt)))
    (ps-output (format "%d " nlist)
	       (ebnf-format-float (ebnf-node-width alternative))
	       " AT\n")
    (setq alt (ebnf-node-list alternative))
    (when alt
      (ebnf-node-generation (car alt))
      (setq alt-height (- (ebnf-node-height (car alt))
			  (ebnf-node-entry (car alt)))))
    (while (setq alt (cdr alt))
      (setq alt-entry (ebnf-node-entry (car alt)))
      (ebnf-vertical-movement
       (- (+ alt-height ebnf-vertical-space alt-entry)))
      (ebnf-node-generation (car alt))
      (setq alt-height (- (ebnf-node-height (car alt)) alt-entry))))
  (ps-output "EOS\n"))


;; [sequence width-fun dim-fun entry height width list]
(defun ebnf-generate-sequence (sequence)
  (ps-output "BOS\n")
  (let ((seq (ebnf-node-list sequence))
	seq-width)
    (when seq
      (ebnf-node-generation (car seq))
      (setq seq-width (ebnf-node-width (car seq))))
    (while (setq seq (cdr seq))
      (ebnf-horizontal-movement seq-width)
      (ebnf-node-generation (car seq))
      (setq seq-width (ebnf-node-width (car seq)))))
  (ps-output "EOS\n"))


;; [terminal width-fun dim-fun entry height width name]
(defun ebnf-generate-terminal (terminal)
  (ebnf-gen-terminal terminal "T"))


;; [non-terminal width-fun dim-fun entry height width name]
(defun ebnf-generate-non-terminal (non-terminal)
  (ebnf-gen-terminal non-terminal "NT"))


;; [empty width-fun dim-fun entry height width]
(defun ebnf-generate-empty (empty)
  (ebnf-empty-alternative (ebnf-node-width empty)))


;; [optional width-fun dim-fun entry height width element]
(defun ebnf-generate-optional (optional)
  (let ((the-optional (ebnf-node-list optional)))
    (ps-output (ebnf-format-float
		(+ (- (ebnf-node-height the-optional)
		      (ebnf-node-entry optional))
		   ebnf-vertical-space)
		(ebnf-node-width optional))
	       " OP\n")
    (ebnf-node-generation the-optional)
    (ps-output "EOS\n")))


;; [one-or-more width-fun dim-fun entry height width element separator]
(defun ebnf-generate-one-or-more (one-or-more)
  (let* ((width (ebnf-node-width one-or-more))
	 (sep   (ebnf-node-separator one-or-more))
	 (entry (- (ebnf-node-entry one-or-more)
		   (if sep
		       (ebnf-node-entry sep)
		     0))))
    (ps-output (ebnf-format-float entry width)
	       " OM\n")
    (ebnf-node-generation (ebnf-node-list one-or-more))
    (ebnf-vertical-movement entry)
    (if sep
	(let ((ebnf-direction "L"))
	  (ebnf-node-generation sep))
      (ebnf-empty-alternative (- width ebnf-horizontal-space))))
  (ps-output "EOS\n"))


;; [zero-or-more width-fun dim-fun entry height width element separator]
(defun ebnf-generate-zero-or-more (zero-or-more)
  (let* ((width      (ebnf-node-width zero-or-more))
	 (node-list  (ebnf-node-list zero-or-more))
	 (list-entry (ebnf-node-entry node-list))
	 (node-sep   (ebnf-node-separator zero-or-more))
	 (entry      (+ list-entry
			ebnf-vertical-space
			(if node-sep
			    (- (ebnf-node-height node-sep)
			       (ebnf-node-entry node-sep))
			  0))))
    (ps-output (ebnf-format-float entry
				  (+ (- (ebnf-node-height node-list)
					list-entry)
				     ebnf-vertical-space)
				  width)
	       " ZM\n")
    (ebnf-node-generation (ebnf-node-list zero-or-more))
    (ebnf-vertical-movement entry)
    (if (ebnf-node-separator zero-or-more)
	(let ((ebnf-direction "L"))
	  (ebnf-node-generation (ebnf-node-separator zero-or-more)))
      (ebnf-empty-alternative (- width ebnf-horizontal-space))))
  (ps-output "EOS\n"))


;; [special width-fun dim-fun entry height width name]
(defun ebnf-generate-special (special)
  (ebnf-gen-terminal special "SP"))


;; [repeat width-fun dim-fun entry height width times element]
(defun ebnf-generate-repeat (repeat)
  (let ((times   (ebnf-node-name repeat))
	(element (ebnf-node-separator repeat)))
    (ps-output-string times)
    (ps-output " "
	       (ebnf-format-float
		(ebnf-node-entry repeat)
		(ebnf-node-height repeat)
		(ebnf-node-width repeat)
		(if element
		    (+ (ebnf-node-width element)
		       ebnf-space-R ebnf-space-R ebnf-space-R
		       (* (length times) ebnf-font-width-R))
		  0.0))
	       " " ebnf-direction "RP\n")
    (and element
	 (ebnf-node-generation element)))
  (ps-output "EOS\n"))


;; [except width-fun dim-fun entry height width element element]
(defun ebnf-generate-except (except)
  (let* ((element   (ebnf-node-list except))
	 (exception (ebnf-node-separator except))
	 (width     (ebnf-node-width element)))
    (ps-output (ebnf-format-float
		width
		(ebnf-node-entry except)
		(ebnf-node-height except)
		(ebnf-node-width except)
		(+ width
		   ebnf-space-E ebnf-space-E ebnf-space-E
		   ebnf-font-width-E
		   (if exception
		       (+ (ebnf-node-width exception) ebnf-space-E)
		     0.0)))
	       " " ebnf-direction "EX\n")
    (ebnf-node-generation (ebnf-node-list except))
    (when exception
      (ebnf-horizontal-movement (+ width ebnf-space-E
				   ebnf-font-width-E ebnf-space-E))
      (ebnf-node-generation exception)))
  (ps-output "EOS\n"))


(defun ebnf-gen-terminal (node code)
  (ps-output-string (ebnf-node-name node))
  (ps-output " " (ebnf-format-float (ebnf-node-width node))
	     " " ebnf-direction code
	     (if (ebnf-node-default node)
		 "D\n"
	       "\n")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Internal functions


(defvar ebnf-map-name
  (let ((map (make-vector 256 ?\_)))
    (mapcar #'(lambda (char)
		(aset map char char))
	    (concat "#$%&+-.0123456789=?@~"
		    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		    "abcdefghijklmnopqrstuvwxyz"))
    map))


(defun ebnf-eps-filename (str)
  (let* ((len  (length str))
	 (stri 0)
	 (new  (make-string len ?\ )))
    (while (< stri len)
      (aset new stri (aref ebnf-map-name (aref str stri)))
      (setq stri (1+ stri)))
    (concat ebnf-eps-prefix new ".eps")))


(defun ebnf-eps-output (&rest args)
  (while args
    (insert (car args))
    (setq args (cdr args))))


(defun ebnf-generate-region (from to gen-func)
  (run-hooks 'ebnf-hook)
  (let ((ebnf-limit (max from to))
	the-point)
    (save-excursion
      (save-restriction
	(save-match-data
	  (condition-case data
	      (let ((tree (ebnf-parse-and-sort (min from to))))
		(when gen-func
		  (funcall gen-func
			   (ebnf-dimensions
			    (ebnf-optimize
			     (ebnf-eliminate-empty-rules tree))))))
	    ;; handler
	    ((quit error)
	     (ding)
	     (setq the-point (max (1- (point)) (point-min)))
	     (message (error-message-string data)))))))
    (cond
     (the-point
      (goto-char the-point))
     (gen-func
      nil)
     (t
      (message "EBNF syntatic analysis: NO ERRORS.")))))


(defun ebnf-parse-and-sort (start)
  (ebnf-begin-job)
  (let ((tree (funcall ebnf-parser-func start)))
    (if ebnf-sort-production
	(progn
	  (message "Sorting...")
	  (sort tree
		(if (eq ebnf-sort-production 'ascending)
		    'ebnf-sorter-ascending
		  'ebnf-sorter-descending)))
      (nreverse tree))))


(defun ebnf-sorter-ascending (first second)
  (string< (ebnf-node-name first)
	   (ebnf-node-name second)))


(defun ebnf-sorter-descending (first second)
  (string< (ebnf-node-name second)
	   (ebnf-node-name first)))


(defun ebnf-empty-alternative (width)
  (ps-output (ebnf-format-float width) " EA\n"))


(defun ebnf-vertical-movement (height)
  (ps-output (ebnf-format-float height) " vm\n"))


(defun ebnf-horizontal-movement (width)
  (ps-output (ebnf-format-float width) " hm\n"))


(defun ebnf-entry (height)
  (* height ebnf-entry-percentage))


(defun ebnf-eop-vertical (height)
  (ps-output (ebnf-format-float (+ height ebnf-production-vertical-space))
	     " EOPV\n\n"))


(defun ebnf-eop-horizontal (width)
  (ps-output (ebnf-format-float (+ width ebnf-production-horizontal-space))
	     " EOPH\n\n"))


(defun ebnf-new-page ()
  (when (< ps-height-remaining ps-print-height)
    (run-hooks 'ebnf-page-hook)
    (ps-next-page)
    (ps-output "\n")))


(defsubst ebnf-font-size (font) (nth 0 font))
(defsubst ebnf-font-name (font) (nth 1 font))
(defsubst ebnf-font-foreground (font) (nth 2 font))
(defsubst ebnf-font-background (font) (nth 3 font))
(defsubst ebnf-font-list (font) (nthcdr 4 font))
(defsubst ebnf-font-attributes (font)
  (lsh (ps-extension-bit (cdr font)) -2))


(defconst ebnf-font-name-select
  (vector 'normal 'bold 'italic 'bold-italic))


(defun ebnf-font-name-select (font)
  (let* ((font-list  (ebnf-font-list font))
	 (font-index (+ (if (memq 'bold   font-list) 1 0)
			(if (memq 'italic font-list) 2 0)))
	 (name       (ebnf-font-name font))
	 (database   (cdr (assoc name ps-font-info-database)))
	 (info-list  (or (cdr (assoc 'fonts database))
			 (error "Invalid font: %s" name))))
    (or (cdr (assoc (aref ebnf-font-name-select font-index)
		    info-list))
	(error "Invalid attributes for font %s" name))))


(defun ebnf-font-select (font select)
  (let* ((name     (ebnf-font-name font))
	 (database (cdr (assoc name ps-font-info-database)))
	 (size     (cdr (assoc 'size database)))
	 (base     (cdr (assoc select database))))
    (if (and size base)
	(/ (* (ebnf-font-size font) base)
	   size)
      (error "Invalid font: %s" name))))


(defsubst ebnf-font-width (font)
  (ebnf-font-select font 'avg-char-width))
(defsubst ebnf-font-height (font)
  (ebnf-font-select font 'line-height))


(defun ebnf-begin-job ()
  (ps-printing-region nil nil)
  (if ebnf-use-float-format
      (setq ebnf-format-float  "%1.3f"
	    ebnf-message-float "%3.2f")
    (setq ebnf-format-float  "%s"
	  ebnf-message-float "%s"))
  (ebnf-otz-initialize)
  ;; to avoid compilation gripes when calling autoloaded functions
  (funcall (cond ((eq ebnf-syntax 'iso-ebnf)
		  (setq ebnf-parser-func 'ebnf-iso-parser)
		  'ebnf-iso-initialize)
		 ((eq ebnf-syntax 'yacc)
		  (setq ebnf-parser-func 'ebnf-yac-parser)
		  'ebnf-yac-initialize)
		 (t
		  (setq ebnf-parser-func 'ebnf-bnf-parser)
		  'ebnf-bnf-initialize)))
  (and ebnf-terminal-regexp		; ensures that it's a string or nil
       (not (stringp ebnf-terminal-regexp))
       (setq ebnf-terminal-regexp nil))
  (or (and ebnf-eps-prefix		; ensures that it's a string
	   (stringp ebnf-eps-prefix))
      (setq ebnf-eps-prefix "ebnf--"))
  (setq ebnf-entry-percentage		; ensures value between 0.0 and 1.0
	(min (max ebnf-entry-percentage 0.0) 1.0)
	ebnf-action-list         (if ebnf-horizontal-orientation
				     '(nil keep-line)
				   '(keep-line))
	ebnf-settings            nil
	ebnf-fonts-required      nil
	ebnf-action              nil
	ebnf-default-p           nil
	ebnf-eps-context         nil
	ebnf-eps-production-list nil
	ebnf-eps-upper-x         0.0
	ebnf-eps-upper-y         0.0
	ebnf-font-height-P       (ebnf-font-height ebnf-production-font)
	ebnf-font-height-T       (ebnf-font-height ebnf-terminal-font)
	ebnf-font-height-NT      (ebnf-font-height ebnf-non-terminal-font)
	ebnf-font-height-S       (ebnf-font-height ebnf-special-font)
	ebnf-font-height-E       (ebnf-font-height ebnf-except-font)
	ebnf-font-height-R       (ebnf-font-height ebnf-repeat-font)
	ebnf-font-width-P        (ebnf-font-width ebnf-production-font)
	ebnf-font-width-T        (ebnf-font-width ebnf-terminal-font)
	ebnf-font-width-NT       (ebnf-font-width ebnf-non-terminal-font)
	ebnf-font-width-S        (ebnf-font-width ebnf-special-font)
	ebnf-font-width-E        (ebnf-font-width ebnf-except-font)
	ebnf-font-width-R        (ebnf-font-width ebnf-repeat-font)
	ebnf-space-T             (* ebnf-font-height-T 0.5)
	ebnf-space-NT            (* ebnf-font-height-NT 0.5)
	ebnf-space-S             (* ebnf-font-height-S 0.5)
	ebnf-space-E             (* ebnf-font-height-E 0.5)
	ebnf-space-R             (* ebnf-font-height-R 0.5))
  (let ((basic (+ ebnf-font-height-T ebnf-font-height-NT)))
    (setq ebnf-basic-width      (* basic 0.5)
	  ebnf-horizontal-space (+ basic basic)
	  ebnf-basic-height     ebnf-basic-width
	  ebnf-vertical-space   ebnf-basic-width)
    ;; ensures value is greater than zero
    (or (and (numberp ebnf-production-horizontal-space)
	     (> ebnf-production-horizontal-space 0.0))
	(setq ebnf-production-horizontal-space basic))
    ;; ensures value is greater than zero
    (or (and (numberp ebnf-production-vertical-space)
	     (> ebnf-production-vertical-space 0.0))
	(setq ebnf-production-vertical-space basic))))


(defsubst ebnf-shape-value (sym alist)
  (or (cdr (assq sym alist)) 0))


(defsubst ebnf-boolean (value)
  (if value "true" "false"))


(defun ebnf-begin-file ()
  (ps-flush-output)
  (save-excursion
    (set-buffer ps-spool-buffer)
    (goto-char (point-min))
    (and (search-forward "%%Creator: " nil t)
	 (not (search-forward "& ebnf2ps v"
			      (save-excursion (end-of-line) (point))
			      t))
	 (progn
	   ;; adjust creator comment
	   (end-of-line)
	   (backward-char)
	   (insert " & ebnf2ps v" ebnf-version)
	   ;; insert ebnf settings & engine
	   (goto-char (point-max))
	   (search-backward "\n%%EndPrologue\n")
	   (ebnf-insert-ebnf-prologue)
	   (ps-output "\n")))))


(defun ebnf-eps-finish-and-write (buffer filename)
  (save-excursion
    (set-buffer buffer)
    (setq ebnf-eps-upper-x (max ebnf-eps-upper-x ebnf-eps-max-width)
	  ebnf-eps-upper-y (if (zerop ebnf-eps-upper-y)
			       ebnf-eps-max-height
			     (+ ebnf-eps-upper-y
				ebnf-production-vertical-space
				ebnf-eps-max-height)))
    ;; prologue
    (goto-char (point-min))
    (insert
     "%!PS-Adobe-3.0 EPSF-3.0"
     "\n%%BoundingBox: 0 0 "
     (format "%d %d" (1+ ebnf-eps-upper-x) (1+ ebnf-eps-upper-y))
     "\n%%Title: " filename
     "\n%%CreationDate: " (time-stamp-hh:mm:ss) " " (time-stamp-mon-dd-yyyy)
     "\n%%Creator: " (user-full-name) " (using ebnf2ps v" ebnf-version ")"
     "\n%%DocumentNeededResources: font "
     (or ebnf-fonts-required
	 (setq ebnf-fonts-required
	       (let ((fonts (ps-remove-duplicates
			     (mapcar 'ebnf-font-name-select
				     (list ebnf-production-font
					   ebnf-terminal-font
					   ebnf-non-terminal-font
					   ebnf-special-font
					   ebnf-except-font
					   ebnf-repeat-font)))))
		 (concat (car fonts)
			 (and (cdr fonts) "\n%%+ font ")
			 (mapconcat 'identity (cdr fonts) "\n%%+ font ")))))
     "\n%%Pages: 0\n%%EndComments\n\n%%BeginPrologue\n"
     ebnf-eps-prologue)
    (ebnf-insert-ebnf-prologue)
    (insert ebnf-eps-begin
	    "\n0 " (ebnf-format-float
		    (- ebnf-eps-upper-y (* ebnf-font-height-P 0.7)))
	    " #ebnf2ps#begin\n")
    ;; epilogue
    (goto-char (point-max))
    (insert ebnf-eps-end)
    ;; write file
    (message "Saving...")
    (setq filename (expand-file-name filename))
    (let ((coding-system-for-write 'raw-text-unix))
      (write-region (point-min) (point-max) filename))
    (message "Wrote %s" filename)))


(defun ebnf-insert-ebnf-prologue ()
  (insert
   (or ebnf-settings
       (setq ebnf-settings
	     (concat
	      "\n\n% === begin EBNF settings\n\n"
	      ;; production
	      (format "/fP            %s /%s DefFont\n"
		      (ebnf-format-float (ebnf-font-size ebnf-production-font))
		      (ebnf-font-name-select ebnf-production-font))
	      (ebnf-format-color "/ForegroundP   %s def %% %s\n"
				 (ebnf-font-foreground ebnf-production-font)
				 "Black")
	      (ebnf-format-color "/BackgroundP   %s def %% %s\n"
				 (ebnf-font-background ebnf-production-font)
				 "White")
	      (format "/EffectP       %d def\n"
		      (ebnf-font-attributes ebnf-production-font))
	      ;; terminal
	      (format "/fT            %s /%s DefFont\n"
		      (ebnf-format-float (ebnf-font-size ebnf-terminal-font))
		      (ebnf-font-name-select ebnf-terminal-font))
	      (ebnf-format-color "/ForegroundT   %s def %% %s\n"
				 (ebnf-font-foreground ebnf-terminal-font)
				 "Black")
	      (ebnf-format-color "/BackgroundT   %s def %% %s\n"
				 (ebnf-font-background ebnf-terminal-font)
				 "White")
	      (format "/EffectT       %d def\n"
		      (ebnf-font-attributes ebnf-terminal-font))
	      (format "/BorderWidthT  %s def\n"
		      (ebnf-format-float ebnf-terminal-border-width))
	      (ebnf-format-color "/BorderColorT  %s def %% %s\n"
				 ebnf-terminal-border-color
				 "Black")
	      (format "/ShapeT        %d def\n"
		      (ebnf-shape-value ebnf-terminal-shape
					ebnf-terminal-shape-alist))
	      (format "/ShadowT       %s def\n"
		      (ebnf-boolean ebnf-terminal-shadow))
	      ;; non-terminal
	      (format "/fNT           %s /%s DefFont\n"
		      (ebnf-format-float
		       (ebnf-font-size ebnf-non-terminal-font))
		      (ebnf-font-name-select ebnf-non-terminal-font))
	      (ebnf-format-color "/ForegroundNT  %s def %% %s\n"
				 (ebnf-font-foreground ebnf-non-terminal-font)
				 "Black")
	      (ebnf-format-color "/BackgroundNT  %s def %% %s\n"
				 (ebnf-font-background ebnf-non-terminal-font)
				 "White")
	      (format "/EffectNT      %d def\n"
		      (ebnf-font-attributes ebnf-non-terminal-font))
	      (format "/BorderWidthNT %s def\n"
		      (ebnf-format-float ebnf-non-terminal-border-width))
	      (ebnf-format-color "/BorderColorNT %s def %% %s\n"
				 ebnf-non-terminal-border-color
				 "Black")
	      (format "/ShapeNT       %d def\n"
		      (ebnf-shape-value ebnf-non-terminal-shape
					ebnf-terminal-shape-alist))
	      (format "/ShadowNT      %s def\n"
		      (ebnf-boolean ebnf-non-terminal-shadow))
	      ;; special
	      (format "/fS            %s /%s DefFont\n"
		      (ebnf-format-float (ebnf-font-size ebnf-special-font))
		      (ebnf-font-name-select ebnf-special-font))
	      (ebnf-format-color "/ForegroundS   %s def %% %s\n"
				 (ebnf-font-foreground ebnf-special-font)
				 "Black")
	      (ebnf-format-color "/BackgroundS   %s def %% %s\n"
				 (ebnf-font-background ebnf-special-font)
				 "Gray95")
	      (format "/EffectS       %d def\n"
		      (ebnf-font-attributes ebnf-special-font))
	      (format "/BorderWidthS  %s def\n"
		      (ebnf-format-float ebnf-special-border-width))
	      (ebnf-format-color "/BorderColorS  %s def %% %s\n"
				 ebnf-special-border-color
				 "Black")
	      (format "/ShapeS        %d def\n"
		      (ebnf-shape-value ebnf-special-shape
					ebnf-terminal-shape-alist))
	      (format "/ShadowS       %s def\n"
		      (ebnf-boolean ebnf-special-shadow))
	      ;; except
	      (format "/fE            %s /%s DefFont\n"
		      (ebnf-format-float (ebnf-font-size ebnf-except-font))
		      (ebnf-font-name-select ebnf-except-font))
	      (ebnf-format-color "/ForegroundE   %s def %% %s\n"
				 (ebnf-font-foreground ebnf-except-font)
				 "Black")
	      (ebnf-format-color "/BackgroundE   %s def %% %s\n"
				 (ebnf-font-background ebnf-except-font)
				 "Gray90")
	      (format "/EffectE       %d def\n"
		      (ebnf-font-attributes ebnf-except-font))
	      (format "/BorderWidthE  %s def\n"
		      (ebnf-format-float ebnf-except-border-width))
	      (ebnf-format-color "/BorderColorE  %s def %% %s\n"
				 ebnf-except-border-color
				 "Black")
	      (format "/ShapeE        %d def\n"
		      (ebnf-shape-value ebnf-except-shape
					ebnf-terminal-shape-alist))
	      (format "/ShadowE       %s def\n"
		      (ebnf-boolean ebnf-except-shadow))
	      ;; repeat
	      (format "/fR            %s /%s DefFont\n"
		      (ebnf-format-float (ebnf-font-size ebnf-repeat-font))
		      (ebnf-font-name-select ebnf-repeat-font))
	      (ebnf-format-color "/ForegroundR   %s def %% %s\n"
				 (ebnf-font-foreground ebnf-repeat-font)
				 "Black")
	      (ebnf-format-color "/BackgroundR   %s def %% %s\n"
				 (ebnf-font-background ebnf-repeat-font)
				 "Gray85")
	      (format "/EffectR       %d def\n"
		      (ebnf-font-attributes ebnf-repeat-font))
	      (format "/BorderWidthR  %s def\n"
		      (ebnf-format-float ebnf-repeat-border-width))
	      (ebnf-format-color "/BorderColorR  %s def %% %s\n"
				 ebnf-repeat-border-color
				 "Black")
	      (format "/ShapeR        %d def\n"
		      (ebnf-shape-value ebnf-repeat-shape
					ebnf-terminal-shape-alist))
	      (format "/ShadowR       %s def\n"
		      (ebnf-boolean ebnf-repeat-shadow))
	      ;; miscellaneous
	      (format "/DefaultWidth  %s def\n"
		      (ebnf-format-float ebnf-default-width))
	      (format "/LineWidth     %s def\n"
		      (ebnf-format-float ebnf-line-width))
	      (ebnf-format-color "/LineColor     %s def %% %s\n"
				 ebnf-line-color
				 "Black")
	      (format "/ArrowShape    %d def\n"
		      (ebnf-shape-value ebnf-arrow-shape
					ebnf-arrow-shape-alist))
	      (format "/ChartShape    %d def\n"
		      (ebnf-shape-value ebnf-chart-shape
					ebnf-terminal-shape-alist))
	      (format "/UserArrow{%s}def\n"
		      (ebnf-user-arrow ebnf-user-arrow))
	      "\n% === end   EBNF settings\n\n"
	      (and ebnf-debug-ps ebnf-debug))))
   ebnf-prologue))


(defun ebnf-user-arrow (user-arrow)
  "Return a user arrow shape from USER-ARROW (a PostScript code).

This function is only called when `ebnf-arrow-shape' is set to symbol `user'.

If is a string, should be a PostScript procedure body.
If is a variable symbol, should contain a string.
If is a function symbol, it is called and the result is applied recursively.
If is a cons and car is a function symbol, it is called as:
   (funcall (car cons) (cdr cons))
and the result is applied recursively.
If is a cons and car is not a function symbol, it is applied recursively on
car and cdr, and the results are concatened as:
   (concat RESULT-FROM-CAR \" \" RESULT-FROM-CDR)
If is a list and car is a function symbol, it is called as:
   (apply (car list) (cdr list))
and the result is applied recursively.
If is a list and car is not a function symbol, it is applied recursively on
each element and the resulting list is concatened as:
   (mapconcat 'identity RESULTING-LIST \" \")
Otherwise, it is treated as an empty string."
  (cond
   ((null user-arrow)
    "")
   ((stringp user-arrow)
    user-arrow)
   ((and (symbolp user-arrow) (fboundp user-arrow))
    (ebnf-user-arrow (funcall user-arrow)))
   ((and (symbolp user-arrow) (boundp user-arrow))
    (ebnf-user-arrow (symbol-value user-arrow)))
   ((consp user-arrow)
    (if (and (symbolp (car user-arrow)) (fboundp (car user-arrow)))
	(ebnf-user-arrow (funcall (car user-arrow) (cdr user-arrow)))
      (concat (ebnf-user-arrow (car user-arrow))
	      " "
	      (ebnf-user-arrow (cdr user-arrow)))))
   ((listp user-arrow)
    (if (and (symbolp (car user-arrow))
	     (fboundp (car user-arrow)))
	(ebnf-user-arrow (apply (car user-arrow) (cdr user-arrow)))
      (mapconcat 'ebnf-user-arrow user-arrow " ")))
   (t
    "")
   ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Adjusting dimensions


(defun ebnf-dimensions (tree)
  (let ((ebnf-total (length tree))
	(ebnf-nprod 0))
    (mapcar 'ebnf-production-dimension tree))
  tree)


;; [empty width-fun dim-fun entry height width]
;;(defun ebnf-empty-dimension (empty)
;;  )


;; [production width-fun dim-fun entry height width name production action]
(defun ebnf-production-dimension (production)
  (ebnf-message-info "Calculating dimensions")
  (ebnf-node-dimension-func (ebnf-node-production production))
  (let* ((prod   (ebnf-node-production production))
	 (height (+ ebnf-font-height-P
		    ebnf-basic-height
		    (ebnf-node-height prod))))
    (ebnf-node-entry  production height)
    (ebnf-node-height production height)
    (ebnf-node-width  production (+ (ebnf-node-width prod)
				    ebnf-horizontal-space))))


;; [terminal width-fun dim-fun entry height width name]
(defun ebnf-terminal-dimension (terminal)
  (ebnf-terminal-dimension1 terminal
			    ebnf-font-height-T
			    ebnf-font-width-T
			    ebnf-space-T))


;; [non-terminal width-fun dim-fun entry height width name]
(defun ebnf-non-terminal-dimension (non-terminal)
  (ebnf-terminal-dimension1 non-terminal
			    ebnf-font-height-NT
			    ebnf-font-width-NT
			    ebnf-space-NT))


;; [special width-fun dim-fun entry height width name]
(defun ebnf-special-dimension (special)
  (ebnf-terminal-dimension1 special
			    ebnf-font-height-S
			    ebnf-font-width-S
			    ebnf-space-S))


(defun ebnf-terminal-dimension1 (node font-height font-width space)
  (let ((height (+ space font-height space))
	(len    (length (ebnf-node-name node))))
    (ebnf-node-entry  node (* height 0.5))
    (ebnf-node-height node height)
    (ebnf-node-width  node (+ ebnf-basic-width space
			      (* len font-width)
			      space ebnf-basic-width))))


(defconst ebnf-null-vector (vector t t t 0.0 0.0 0.0))


;; [repeat width-fun dim-fun entry height width times element]
(defun ebnf-repeat-dimension (repeat)
  (let ((times   (ebnf-node-name repeat))
	(element (ebnf-node-separator repeat)))
    (if element
	(ebnf-node-dimension-func element)
      (setq element ebnf-null-vector))
    (ebnf-node-entry  repeat (+ (ebnf-node-entry element)
				ebnf-space-R))
    (ebnf-node-height repeat (+ (max (ebnf-node-height element)
				     ebnf-font-height-S)
				ebnf-space-R ebnf-space-R))
    (ebnf-node-width  repeat (+ (ebnf-node-width element)
				ebnf-space-R ebnf-space-R ebnf-space-R
				ebnf-horizontal-space
				(* (length times) ebnf-font-width-R)))))


;; [except width-fun dim-fun entry height width element element]
(defun ebnf-except-dimension (except)
  (let ((factor  (ebnf-node-list except))
	(element (ebnf-node-separator except)))
    (ebnf-node-dimension-func factor)
    (if element
	(ebnf-node-dimension-func element)
      (setq element ebnf-null-vector))
    (ebnf-node-entry  except (+ (max (ebnf-node-entry factor)
				     (ebnf-node-entry element))
				ebnf-space-E))
    (ebnf-node-height except (+ (max (ebnf-node-height factor)
				     (ebnf-node-height element))
				ebnf-space-E ebnf-space-E))
    (ebnf-node-width  except (+ (ebnf-node-width factor)
				(ebnf-node-width element)
				ebnf-space-E ebnf-space-E
				ebnf-space-E ebnf-space-E
				ebnf-font-width-E
				ebnf-horizontal-space))))


;; [alternative width-fun dim-fun entry height width list]
(defun ebnf-alternative-dimension (alternative)
  (let ((body (ebnf-node-list alternative))
	(lis  (ebnf-node-list alternative)))
    (while lis
      (ebnf-node-dimension-func (car lis))
      (setq lis (cdr lis)))
    (let ((height 0.0)
	  (width  0.0)
	  (alt    body)
	  (tail   (car (last body)))
	  (entry  (ebnf-node-entry (car body)))
	  node)
      (while alt
	(setq node   (car alt)
	      alt    (cdr alt)
	      height (+ (ebnf-node-height node) height)
	      width  (max (ebnf-node-width node) width)))
      (ebnf-adjust-width body width)
      (setq height (+ height (* (1- (length body)) ebnf-vertical-space)))
      (ebnf-node-entry  alternative (+ entry
				       (ebnf-entry
					(- height entry
					   (- (ebnf-node-height tail)
					      (ebnf-node-entry tail))))))
      (ebnf-node-height alternative height)
      (ebnf-node-width  alternative (+ width ebnf-horizontal-space))
      (ebnf-node-list   alternative body))))


;; [optional width-fun dim-fun entry height width element]
(defun ebnf-optional-dimension (optional)
  (let ((body (ebnf-node-list optional)))
    (ebnf-node-dimension-func body)
    (ebnf-node-entry  optional (ebnf-node-entry body))
    (ebnf-node-height optional (+ (ebnf-node-height body)
				  ebnf-vertical-space))
    (ebnf-node-width  optional (+ (ebnf-node-width body)
				  ebnf-horizontal-space))))


;; [one-or-more width-fun dim-fun entry height width element separator]
(defun ebnf-one-or-more-dimension (or-more)
  (let ((list-part (ebnf-node-list or-more))
	(sep-part  (ebnf-node-separator or-more)))
    (ebnf-node-dimension-func list-part)
    (and sep-part
	 (ebnf-node-dimension-func sep-part))
    (let ((height (+ (if sep-part
			 (ebnf-node-height sep-part)
		       0.0)
		     ebnf-vertical-space
		     (ebnf-node-height list-part)))
	  (width  (max (if sep-part
			   (ebnf-node-width sep-part)
			 0.0)
		       (ebnf-node-width list-part))))
      (when sep-part
	(ebnf-adjust-width list-part width)
	(ebnf-adjust-width sep-part width))
      (ebnf-node-entry  or-more (+ (- height (ebnf-node-height list-part))
				   (ebnf-node-entry list-part)))
      (ebnf-node-height or-more height)
      (ebnf-node-width  or-more (+ width ebnf-horizontal-space)))))


;; [zero-or-more width-fun dim-fun entry height width element separator]
(defun ebnf-zero-or-more-dimension (or-more)
  (let ((list-part (ebnf-node-list or-more))
	(sep-part  (ebnf-node-separator or-more)))
    (ebnf-node-dimension-func list-part)
    (and sep-part
	 (ebnf-node-dimension-func sep-part))
    (let ((height (+ (if sep-part
			 (ebnf-node-height sep-part)
		       0.0)
		     ebnf-vertical-space
		     (ebnf-node-height list-part)
		     ebnf-vertical-space))
	  (width  (max (if sep-part
			   (ebnf-node-width sep-part)
			 0.0)
		       (ebnf-node-width list-part))))
      (when sep-part
	(ebnf-adjust-width list-part width)
	(ebnf-adjust-width sep-part width))
      (ebnf-node-entry  or-more height)
      (ebnf-node-height or-more height)
      (ebnf-node-width  or-more (+ width ebnf-horizontal-space)))))


;; [sequence width-fun dim-fun entry height width list]
(defun ebnf-sequence-dimension (sequence)
  (let ((above 0.0)
	(below 0.0)
	(width 0.0)
	(lis   (ebnf-node-list sequence))
	entry node)
    (while lis
      (setq node (car lis)
	    lis  (cdr lis))
      (ebnf-node-dimension-func node)
      (setq entry (ebnf-node-entry node)
	    above (max above entry)
	    below (max below (- (ebnf-node-height node) entry))
	    width (+ width (ebnf-node-width node))))
    (ebnf-node-entry  sequence above)
    (ebnf-node-height sequence (+ above below))
    (ebnf-node-width  sequence width)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Adjusting width


(defun ebnf-adjust-width (node width)
  (cond
   ((listp node)
    (prog1
	node
      (while node
	(setcar node (ebnf-adjust-width (car node) width))
	(setq node (cdr node)))))
   ((vectorp node)
    (cond
     ;; nothing to be done
     ((= width (ebnf-node-width node))
      node)
     ;; left justify term
     ((eq ebnf-justify-sequence 'left)
      (ebnf-adjust-empty node width nil))
     ;; right justify terms
     ((eq ebnf-justify-sequence 'right)
      (ebnf-adjust-empty node width t))
     ;; centralize terms
     (t
      (ebnf-node-width-func node width)
      (ebnf-node-width node width)
      node)
     ))
   (t
    node)
   ))


(defun ebnf-adjust-empty (node width last-p)
  (if (eq (ebnf-node-kind node) 'ebnf-generate-empty)
      (progn
	(ebnf-node-width node width)
	node)
    (let ((empty (ebnf-make-empty (- width (ebnf-node-width node)))))
      (ebnf-make-dup-sequence node
			      (if last-p
				  (list empty node)
				(list node empty))))))


;; [terminal     width-fun dim-fun entry height width name]
;; [non-terminal width-fun dim-fun entry height width name]
;; [empty        width-fun dim-fun entry height width]
;; [special      width-fun dim-fun entry height width name]
;; [repeat       width-fun dim-fun entry height width times element]
;; [except       width-fun dim-fun entry height width element element]
;;(defun ebnf-terminal-width (terminal width)
;;  )


;; [alternative width-fun dim-fun entry height width list]
;; [optional    width-fun dim-fun entry height width element]
(defun ebnf-alternative-width (alternative width)
  (ebnf-adjust-width (ebnf-node-list alternative)
		     (- width ebnf-horizontal-space)))


;; [one-or-more  width-fun dim-fun entry height width element separator]
;; [zero-or-more width-fun dim-fun entry height width element separator]
(defun ebnf-list-width (or-more width)
  (setq width (- width ebnf-horizontal-space))
  (ebnf-node-list or-more
		  (ebnf-justify-list or-more
				     (ebnf-node-list or-more)
				     width))
  (ebnf-node-separator or-more
		       (ebnf-justify-list or-more
					  (ebnf-node-separator or-more)
					  width)))


;; [sequence width-fun dim-fun entry height width list]
(defun ebnf-sequence-width (sequence width)
  (ebnf-node-list sequence
		  (ebnf-justify-list sequence
				     (ebnf-node-list sequence)
				     width)))


(defun ebnf-justify-list (node seq width)
  (let ((seq-width (ebnf-node-width node)))
    (if (= width seq-width)
	seq
      (cond
       ;; left justify terms
       ((eq ebnf-justify-sequence 'left)
	(ebnf-justify node seq seq-width width t))
       ;; right justify terms
       ((eq ebnf-justify-sequence 'right)
	(ebnf-justify node seq seq-width width nil))
       ;; centralize terms
       (t
	(let ((the-width (/ (- width seq-width) (length seq)))
	      (lis seq))
	  (while lis
	    (ebnf-adjust-width (car lis)
			       (+ (ebnf-node-width (car lis))
				  the-width))
	    (setq lis (cdr lis)))
	  seq))
       ))))


(defun ebnf-justify (node seq seq-width width last-p)
  (let ((term (car (if last-p (last seq) seq))))
    (cond
     ;; adjust empty term
     ((eq (ebnf-node-kind term) 'ebnf-generate-empty)
      (ebnf-node-width term (+ (- width seq-width)
			       (ebnf-node-width term)))
      seq)
     ;; insert empty at end ==> left justify
     (last-p
      (nconc seq
	     (list (ebnf-make-empty (- width seq-width)))))
     ;; insert empty at beginning ==> right justify
     (t
      (cons (ebnf-make-empty (- width seq-width))
	    seq))
     )))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Functions used by parsers


(defun ebnf-eps-add-context (name)
  (let ((filename (ebnf-eps-filename name)))
    (if (member filename ebnf-eps-context)
	(error "Try to open an already opened EPS file: %s" filename)
      (setq ebnf-eps-context (cons filename ebnf-eps-context)))))


(defun ebnf-eps-remove-context (name)
  (let ((filename (ebnf-eps-filename name)))
    (if (member filename ebnf-eps-context)
	(setq ebnf-eps-context (delete filename ebnf-eps-context))
      (error "Try to close a not opened EPS file: %s" filename))))


(defun ebnf-eps-add-production (header)
  (and ebnf-eps-executing
       ebnf-eps-context
       (let ((prod (assoc header ebnf-eps-production-list)))
	 (if prod
	     (setcdr prod (append ebnf-eps-context (cdr prod)))
	   (setq ebnf-eps-production-list
		 (cons (cons header (ebnf-dup-list ebnf-eps-context))
		       ebnf-eps-production-list))))))


(defun ebnf-dup-list (old)
  (let (new)
    (while old
      (setq new (cons (car old) new)
	    old (cdr old)))
    (nreverse new)))


(defun ebnf-buffer-substring (chars)
  (buffer-substring-no-properties
   (point)
   (progn
     (skip-chars-forward chars ebnf-limit)
     (point))))


(defun ebnf-string (chars eos-char kind)
  (forward-char)
  (buffer-substring-no-properties
   (point)
   (progn
     (skip-chars-forward (concat chars "\240-\377") ebnf-limit)
     (if (or (eobp) (/= (following-char) eos-char))
	 (error "Illegal %s: missing `%c'." kind eos-char)
       (forward-char)
       (1- (point))))))


(defun ebnf-get-string ()
  (forward-char)
  (buffer-substring-no-properties (point) (ebnf-end-of-string)))


(defun ebnf-end-of-string ()
  (let ((n 1))
    (while (> (logand n 1) 0)
      (skip-chars-forward "^\"" ebnf-limit)
      (setq n (- (skip-chars-backward "\\\\")))
      (goto-char (+ (point) n 1))))
  (if (= (preceding-char) ?\")
      (1- (point))
    (error "Missing `\"'.")))


(defun ebnf-trim-right (str)
  (let* ((len   (1- (length str)))
	 (index len))
    (while (and (> index 0) (= (aref str index) ?\ ))
      (setq index (1- index)))
    (if (= index len)
	str
      (substring str 0 (1+ index)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Vector creation


(defun ebnf-make-empty (&optional width)
  (vector 'ebnf-generate-empty
	  'ignore
	  'ignore
	  0.0
	  0.0
	  (or width ebnf-horizontal-space)))


(defun ebnf-make-terminal (name)
  (ebnf-make-terminal1 name
		       'ebnf-generate-terminal
		       'ebnf-terminal-dimension))


(defun ebnf-make-non-terminal (name)
  (ebnf-make-terminal1 name
		       'ebnf-generate-non-terminal
		       'ebnf-non-terminal-dimension))


(defun ebnf-make-special (name)
  (ebnf-make-terminal1 name
		       'ebnf-generate-special
		       'ebnf-special-dimension))


(defun ebnf-make-terminal1 (name gen-func dim-func)
  (vector gen-func
	  'ignore
	  dim-func
	  0.0
	  0.0
	  0.0
	  (let ((len (length name)))
	    (cond ((> len 2) name)
		  ((= len 2) (concat " " name))
		  ((= len 1) (concat " " name " "))
		  (t         "   ")))
	  ebnf-default-p))


(defun ebnf-make-one-or-more (list-part &optional sep-part)
  (ebnf-make-or-more1 'ebnf-generate-one-or-more
		      'ebnf-one-or-more-dimension
		      list-part
		      sep-part))


(defun ebnf-make-zero-or-more (list-part &optional sep-part)
  (ebnf-make-or-more1 'ebnf-generate-zero-or-more
		      'ebnf-zero-or-more-dimension
		      list-part
		      sep-part))


(defun ebnf-make-or-more1 (gen-func dim-func list-part sep-part)
  (vector gen-func
	  'ebnf-list-width
	  dim-func
	  0.0
	  0.0
	  0.0
	  (if (listp list-part)
	      (ebnf-make-sequence list-part)
	    list-part)
	  (if (and sep-part (listp sep-part))
	      (ebnf-make-sequence sep-part)
	    sep-part)))


(defun ebnf-make-production (name prod action)
  (vector 'ebnf-generate-production
	  'ignore
	  'ebnf-production-dimension
	  0.0
	  0.0
	  0.0
	  name
	  prod
	  action))


(defun ebnf-make-alternative (body)
  (vector 'ebnf-generate-alternative
	  'ebnf-alternative-width
	  'ebnf-alternative-dimension
	  0.0
	  0.0
	  0.0
	  body))


(defun ebnf-make-optional (body)
  (vector 'ebnf-generate-optional
	  'ebnf-alternative-width
	  'ebnf-optional-dimension
	  0.0
	  0.0
	  0.0
	  body))


(defun ebnf-make-except (factor exception)
  (vector 'ebnf-generate-except
	  'ignore
	  'ebnf-except-dimension
	  0.0
	  0.0
	  0.0
	  factor
	  exception))


(defun ebnf-make-repeat (times primary)
  (vector 'ebnf-generate-repeat
	  'ignore
	  'ebnf-repeat-dimension
	  0.0
	  0.0
	  0.0
	  (concat times " *")
	  primary))


(defun ebnf-make-sequence (seq)
  (vector 'ebnf-generate-sequence
	  'ebnf-sequence-width
	  'ebnf-sequence-dimension
	  0.0
	  0.0
	  0.0
	  seq))


(defun ebnf-make-dup-sequence (node seq)
  (vector 'ebnf-generate-sequence
	  'ebnf-sequence-width
	  'ebnf-sequence-dimension
	   (ebnf-node-entry node)
	   (ebnf-node-height node)
	   (ebnf-node-width node)
	   seq))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Optimizers used by parsers


(defun ebnf-token-except (element exception)
  (cons (prog1
	    (car exception)
	  (setq exception (cdr exception)))
	(and element			; EMPTY - A ==> EMPTY
	     (let ((kind (ebnf-node-kind element)))
	       (cond
		;; [ A ]- ==> A
		((and (null exception)
		      (eq kind 'ebnf-generate-optional))
		 (ebnf-node-list element))
		;; { A }- ==> { A }+
		((and (null exception)
		      (eq kind 'ebnf-generate-zero-or-more))
		 (ebnf-node-kind element 'ebnf-generate-one-or-more)
		 (ebnf-node-dimension-func element 'ebnf-one-or-more-dimension)
		 element)
		;; ( A | EMPTY )-      ==> A
		;; ( A | B | EMPTY )-  ==> A | B
		((and (null exception)
		      (eq kind 'ebnf-generate-alternative)
		      (eq (ebnf-node-kind
			   (car (last (ebnf-node-list element))))
			  'ebnf-generate-empty))
		 (let ((elt (ebnf-node-list element))
		       bef)
		   (while (cdr elt)
		     (setq bef elt
			   elt (cdr elt)))
		   (if (null bef)
		       ;; this should not happen!!?!
		       (setq element (ebnf-make-empty
				      (ebnf-node-width element)))
		     (setcdr bef nil)
		     (setq elt (ebnf-node-list element))
		     (and (= (length elt) 1)
			  (setq element (car elt))))
		   element))
		;; A - B
		(t
		 (ebnf-make-except element exception))
		)))))


(defun ebnf-token-repeat (times repeat)
  (if (null (cdr repeat))
      ;; n * EMPTY ==> EMPTY
      repeat
    ;; n * term
    (cons (car repeat)
	  (ebnf-make-repeat times (cdr repeat)))))


(defun ebnf-token-optional (body)
  (let ((kind (ebnf-node-kind body)))
    (cond
     ;; [ EMPTY ] ==> EMPTY
     ((eq kind 'ebnf-generate-empty)
      nil)
     ;; [ { A }* ] ==> { A }*
     ((eq kind 'ebnf-generate-zero-or-more)
      body)
     ;; [ { A }+ ] ==> { A }*
     ((eq kind 'ebnf-generate-one-or-more)
      (ebnf-node-kind body 'ebnf-generate-zero-or-more)
      body)
     ;; [ A | B ] ==> A | B | EMPTY
     ((eq kind 'ebnf-generate-alternative)
      (ebnf-node-list body (nconc (ebnf-node-list body)
				  (list (ebnf-make-empty))))
      body)
     ;; [ A ]
     (t
      (ebnf-make-optional body))
     )))


(defun ebnf-token-alternative (body sequence)
  (if (null body)
      (if (cdr sequence)
	  sequence
	(cons (car sequence)
	      (ebnf-make-empty)))
    (cons (car sequence)
	  (let ((seq (cdr sequence)))
	    (if (and (= (length body) 1) (null seq))
		(car body)
	      (ebnf-make-alternative (nreverse (if seq
						   (cons seq body)
						 body))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables used by parsers


(defconst ebnf-comment-table
  (let ((table (make-vector 256 nil)))
    ;; Override special comment character:
    (aset table ?< 'newline)
    (aset table ?> 'keep-line)
    table)
  "Vector used to map characters to a special comment token.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; To make this file smaller, some commands go in a separate file.
;; But autoload them here to make the separation invisible.

(autoload 'ebnf-bnf-parser            "ebnf-bnf"
  "EBNF parser.")

(autoload 'ebnf-bnf-initialize        "ebnf-bnf"
  "Initialize EBNF token table.")

(autoload 'ebnf-iso-parser            "ebnf-iso"
  "ISO EBNF parser.")

(autoload 'ebnf-iso-initialize        "ebnf-iso"
  "Initialize ISO EBNF token table.")

(autoload 'ebnf-yac-parser            "ebnf-yac"
  "Yacc/Bison parser.")

(autoload 'ebnf-yac-initialize        "ebnf-yac"
  "Initializations for Yacc/Bison parser.")

(autoload 'ebnf-eliminate-empty-rules "ebnf-otz"
  "Eliminate empty rules.")

(autoload 'ebnf-optimize              "ebnf-otz"
  "Syntatic chart optimizer.")

(autoload 'ebnf-otz-initialize        "ebnf-otz"
  "Initialize optimizer.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(provide 'ebnf2ps)


;;; ebnf2ps.el ends here
