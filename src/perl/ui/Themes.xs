#include "module.h"

void printformat_perl(TEXT_DEST_REC *dest, char *format, char **arglist)
{
	THEME_REC *theme;
	char *module, *str;
	int formatnum;

	module = g_strdup(perl_get_package());
	formatnum = format_find_tag(module, format);
	if (formatnum < 0) {
		die("printformat(): unregistered format '%s'", format);
                g_free(module);
		return;
	}

	theme = dest->window->theme == NULL ? current_theme :
		dest->window->theme;
	signal_emit("print format", 5, theme, module,
		    &dest, GINT_TO_POINTER(formatnum), arglist);

        str = format_get_text_theme_charargs(theme, module, dest, formatnum, arglist);
	if (*str != '\0') printtext_dest(dest, "%s", str);
	g_free(str);
	g_free(module);
}

static void perl_unregister_theme(const char *package)
{
	FORMAT_REC *formats;
	int n;

	formats = g_hash_table_lookup(default_formats, package);
	if (formats == NULL) return;

	for (n = 0; formats[n].def != NULL; n++) {
		g_free(formats[n].tag);
		g_free(formats[n].def);
	}
	g_free(formats);
	theme_unregister_module(package);
}

static void sig_script_destroyed(PERL_SCRIPT_REC *script)
{
	perl_unregister_theme(script->package);
}

void perl_themes_init(void)
{
	signal_add("script destroyed", (SIGNAL_FUNC) sig_script_destroyed);
}

void perl_themes_deinit(void)
{
	signal_remove("script destroyed", (SIGNAL_FUNC) sig_script_destroyed);
}

MODULE = Irssi::UI::Themes  PACKAGE = Irssi
PROTOTYPES: ENABLE

Irssi::UI::Theme
current_theme()
CODE:
	RETVAL = current_theme;
OUTPUT:
	RETVAL

int
EXPAND_FLAG_IGNORE_REPLACES()
CODE:
	RETVAL = EXPAND_FLAG_IGNORE_REPLACES;
OUTPUT:
	RETVAL

int
EXPAND_FLAG_IGNORE_EMPTY()
CODE:
	RETVAL = EXPAND_FLAG_IGNORE_EMPTY;
OUTPUT:
	RETVAL

int
EXPAND_FLAG_RECURSIVE_MASK()
CODE:
	RETVAL = EXPAND_FLAG_RECURSIVE_MASK;
OUTPUT:
	RETVAL

void
theme_register(formats)
	SV *formats
PREINIT:
        STRLEN n_a;
	AV *av;
	FORMAT_REC *formatrecs;
	char *key, *value;
	int len, n, fpos;
CODE:

        if (!SvROK(formats))
        	croak("formats is not a reference to list");
	av = (AV *) SvRV(formats);
	len = av_len(av)+1;
	if (len == 0 || (len & 1) != 0)
        	croak("formats list is invalid - not divisible by 2 (%d)", len);

	formatrecs = g_new0(FORMAT_REC, len/2+2);
	formatrecs[0].tag = g_strdup(perl_get_package());
	formatrecs[0].def = g_strdup("Perl script");

        for (fpos = 1, n = 0; n < len; n++, fpos++) {
		key = SvPV(*av_fetch(av, n, 0), n_a); n++;
		value = SvPV(*av_fetch(av, n, 0), n_a);

		formatrecs[fpos].tag = g_strdup(key);
		formatrecs[fpos].def = g_strdup(value);
		formatrecs[fpos].params = MAX_FORMAT_PARAMS;
	}

	theme_register_module(perl_get_package(), formatrecs);

void
printformat(level, format, ...)
	int level
	char *format
PREINIT:
        STRLEN n_a;
	TEXT_DEST_REC dest;
	char *arglist[MAX_FORMAT_PARAMS+1];
	int n;
CODE:
	format_create_dest(&dest, NULL, NULL, level, NULL);
	memset(arglist, 0, sizeof(arglist));
	for (n = 2; n < items && n < MAX_FORMAT_PARAMS+2; n++) {
		arglist[n-2] = SvPV(ST(n), n_a);
	}

        printformat_perl(&dest, format, arglist);

#*******************************
MODULE = Irssi::UI::Themes  PACKAGE = Irssi::Server
#*******************************

void
printformat(server, target, level, format, ...)
	Irssi::Server server
	char *target
	int level
	char *format
PREINIT:
        STRLEN n_a;
	TEXT_DEST_REC dest;
	char *arglist[MAX_FORMAT_PARAMS+1];
	int n;
CODE:
	format_create_dest(&dest, server, target, level, NULL);
	memset(arglist, 0, sizeof(arglist));
	for (n = 4; n < items && n < MAX_FORMAT_PARAMS+4; n++) {
		arglist[n-4] = SvPV(ST(n), n_a);
	}

        printformat_perl(&dest, format, arglist);

#*******************************
MODULE = Irssi::UI::Themes  PACKAGE = Irssi::UI::Window
#*******************************

void
printformat(window, level, format, ...)
	Irssi::UI::Window window
	int level
	char *format
PREINIT:
        STRLEN n_a;
	TEXT_DEST_REC dest;
	char *arglist[MAX_FORMAT_PARAMS+1];
	int n;
CODE:
	format_create_dest(&dest, NULL, NULL, level, window);
	memset(arglist, 0, sizeof(arglist));
	for (n = 3; n < items && n < MAX_FORMAT_PARAMS+3; n++) {
		arglist[n-3] = SvPV(ST(n), n_a);
	}

        printformat_perl(&dest, format, arglist);

#*******************************
MODULE = Irssi::UI::Themes  PACKAGE = Irssi::Windowitem
#*******************************

void
printformat(item, level, format, ...)
	Irssi::Windowitem item
	int level
	char *format
PREINIT:
        STRLEN n_a;
	TEXT_DEST_REC dest;
	char *arglist[MAX_FORMAT_PARAMS+1];
	int n;
CODE:
	format_create_dest(&dest, item->server, item->name, level, NULL);
	memset(arglist, 0, sizeof(arglist));
	for (n = 3; n < items && n < MAX_FORMAT_PARAMS+3; n++) {
		arglist[n-3] = SvPV(ST(n), n_a);
	}

        printformat_perl(&dest, format, arglist);

#*******************************
MODULE = Irssi::UI::Themes  PACKAGE = Irssi::UI::Theme  PREFIX = theme_
#*******************************

void
theme_format_expand(theme, format, flags=0)
	Irssi::UI::Theme theme
	char *format
        int flags
PREINIT:
	char *ret;
PPCODE:
	if (flags == 0) {
		ret = theme_format_expand(theme, format);
	} else {
		ret = theme_format_expand_data(theme, (const char **) &format, 'n', 'n',
					       NULL, NULL, EXPAND_FLAG_ROOT | flags);
	}
	XPUSHs(sv_2mortal(new_pv(ret)));
	g_free_not_null(ret);
